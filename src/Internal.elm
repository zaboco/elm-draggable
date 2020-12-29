module Internal exposing
    ( Config
    , Delta
    , Event
    , Msg(..)
    , Position
    , State(..)
    , defaultConfig
    , distanceTo
    , updateAndEmit
    )

import Browser.Events as Events


type alias Position =
    { x : Int
    , y : Int
    }


type State a
    = NotDragging
    | DraggingTentative a Int Position
    | Dragging Position


type Msg a
    = StartDragging a Int Position
    | DragAt Position
    | StopDragging


type alias Delta =
    ( Float, Float )


type alias Config a msg =
    { onDragStart : a -> Maybe msg
    , onDragBy : Delta -> Maybe msg
    , onDragEnd : Maybe msg
    , onClick : a -> Int -> Maybe msg
    , onMouseDown : a -> Int -> Maybe msg
    }


type alias Event a msg =
    Config a msg -> Config a msg


defaultConfig : Config a msg
defaultConfig =
    { onDragStart = \_ -> Nothing
    , onDragBy = \_ -> Nothing
    , onDragEnd = Nothing
    , onClick = \_ _ -> Nothing
    , onMouseDown = \_ _ -> Nothing
    }


updateAndEmit : Config a msg -> Msg a -> State a -> ( State a, Maybe msg )
updateAndEmit config msg drag =
    case ( drag, msg ) of
        ( NotDragging, StartDragging key button initialPosition ) ->
            ( DraggingTentative key button initialPosition, config.onMouseDown key button )

        ( DraggingTentative key button oldPosition, DragAt _ ) ->
            case button of
                -- https://www.w3.org/TR/DOM-Level-2-Events/events.html#Events-MouseEvent
                -- 0 indicates the primary (usually left) mouse button
                0 ->
                    ( Dragging oldPosition
                    , config.onDragStart key
                    )
                _ ->
                    ( NotDragging
                    , Nothing
                    )

        ( Dragging oldPosition, DragAt newPosition ) ->
            ( Dragging newPosition
            , config.onDragBy (distanceTo newPosition oldPosition)
            )

        ( DraggingTentative key button _, StopDragging ) ->
            ( NotDragging
            , config.onClick key button
            )

        ( Dragging _, StopDragging ) ->
            ( NotDragging
            , config.onDragEnd
            )

        _ ->
            ( drag, Nothing )



-- utility


distanceTo : Position -> Position -> Delta
distanceTo end start =
    ( toFloat (end.x - start.x)
    , toFloat (end.y - start.y)
    )
