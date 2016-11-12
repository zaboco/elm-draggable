module Internal exposing (..)

import Cmd.Extra
import Draggable.Delta as Delta exposing (Delta)
import Maybe.Extra exposing (maybeToList)
import Mouse exposing (Position)
import String


type Drag
    = NoDrag
    | TentativeDrag Position
    | Dragging Position


type Msg
    = DragStart Position
    | DragAt Position
    | DragEnd


type alias Emit msg model =
    ( model, List msg )


type alias UpdateEmitter msg =
    Msg -> Drag -> Emit msg Drag


type Config msg
    = Config
        { onDragStart : Maybe msg
        , onDragBy : Delta -> Maybe msg
        , onDragEnd : Maybe msg
        , onClick : Maybe msg
        }


defaultConfig : Config msg
defaultConfig =
    Config
        { onDragStart = Nothing
        , onDragBy = \_ -> Nothing
        , onDragEnd = Nothing
        , onClick = Nothing
        }


updateDraggable : Config msg -> Msg -> Drag -> ( Drag, Cmd msg )
updateDraggable config msg drag =
    let
        ( newDrag, newMsgs ) =
            updateAndEmit config msg drag
    in
        ( newDrag, Cmd.Extra.multiMessage newMsgs )


updateAndEmit : Config msg -> Msg -> Drag -> Emit msg Drag
updateAndEmit (Config config) msg drag =
    case ( msg, drag ) of
        ( DragStart initialPosition, NoDrag ) ->
            ( TentativeDrag initialPosition, [] )

        ( DragAt newPosition, TentativeDrag oldPosition ) ->
            ( Dragging newPosition
            , List.concatMap maybeToList
                [ config.onDragStart
                , config.onDragBy (Delta.distanceTo newPosition oldPosition)
                ]
            )

        ( DragAt newPosition, Dragging oldPosition ) ->
            ( Dragging newPosition
            , maybeToList (config.onDragBy (Delta.distanceTo newPosition oldPosition))
            )

        ( DragEnd, TentativeDrag _ ) ->
            ( NoDrag, maybeToList config.onClick )

        ( DragEnd, Dragging _ ) ->
            ( NoDrag, maybeToList config.onDragEnd )

        _ ->
            ( drag, [] )
                |> logInvalidState drag msg



-- utility


logInvalidState : Drag -> Msg -> a -> a
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
