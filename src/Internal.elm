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
    | DraggingTentative a Position
    | Dragging Position


type Msg a
    = StartDragging a Position
    | DragAt Position
    | StopDragging


type alias Delta =
    ( Float, Float )


type alias Config a msg =
    { onDragStart : a -> Maybe msg
    , onDragBy : Delta -> Maybe msg
    , onDragEnd : Maybe msg
    , onClick : a -> Maybe msg
    , onMouseDown : a -> Maybe msg
    }


type alias Event a msg =
    Config a msg -> Config a msg


defaultConfig : Config a msg
defaultConfig =
    { onDragStart = \_ -> Nothing
    , onDragBy = \_ -> Nothing
    , onDragEnd = Nothing
    , onClick = \_ -> Nothing
    , onMouseDown = \_ -> Nothing
    }


updateAndEmit : Config a msg -> Msg a -> State a -> ( State a, Maybe msg )
updateAndEmit config msg drag =
    case ( drag, msg ) of
        ( NotDragging, StartDragging key initialPosition ) ->
            ( DraggingTentative key initialPosition, config.onMouseDown key )

        ( DraggingTentative key oldPosition, DragAt _ ) ->
            ( Dragging oldPosition
            , config.onDragStart key
            )

        ( Dragging oldPosition, DragAt newPosition ) ->
            ( Dragging newPosition
            , config.onDragBy (distanceTo newPosition oldPosition)
            )

        ( DraggingTentative key _, StopDragging ) ->
            ( NotDragging
            , config.onClick key
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
