module Internal exposing (..)

import Mouse exposing (Position)


type alias Key =
    String


type State
    = NotDragging
    | DraggingTentative Key Position
    | Dragging Position


type Msg
    = StartDragging Key Position
    | DragAt Position
    | StopDragging


type alias Delta =
    ( Float, Float )


type alias Config msg =
    { onDragStart : Key -> Maybe msg
    , onDragBy : Delta -> Maybe msg
    , onDragEnd : Maybe msg
    , onClick : Key -> Maybe msg
    , onMouseDown : Key -> Maybe msg
    }


type alias Event msg =
    Config msg -> Config msg


defaultConfig : Config msg
defaultConfig =
    { onDragStart = \_ -> Nothing
    , onDragBy = \_ -> Nothing
    , onDragEnd = Nothing
    , onClick = \_ -> Nothing
    , onMouseDown = \_ -> Nothing
    }


updateAndEmit : Config msg -> Msg -> State -> ( State, Maybe msg )
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
                |> logInvalidState drag msg



-- utility


distanceTo : Position -> Position -> Delta
distanceTo end start =
    ( toFloat (end.x - start.x)
    , toFloat (end.y - start.y)
    )


logInvalidState : State -> Msg -> a -> a
logInvalidState drag msg result =
    let
        str =
            String.join ""
                [ "Invalid drag state: "
                , toString drag
                , ": "
                , toString msg
                ]

        _ =
            Debug.log str
    in
        result
