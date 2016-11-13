module Internal exposing (..)

import Draggable.Delta as Delta exposing (Delta)
import Maybe.Extra exposing (maybeToList)
import Mouse exposing (Position)
import String


type State
    = NotDragging
    | DraggingTentative Position
    | Dragging Position


type Msg
    = StartDragging Position
    | DragAt Position
    | StopDragging


type alias Config msg =
    { onDragStart : Maybe msg
    , onDragBy : Delta -> Maybe msg
    , onDragEnd : Maybe msg
    , onClick : Maybe msg
    }


defaultConfig : Config msg
defaultConfig =
    { onDragStart = Nothing
    , onDragBy = \_ -> Nothing
    , onDragEnd = Nothing
    , onClick = Nothing
    }


updateAndEmit : Config msg -> Msg -> State -> ( State, List msg )
updateAndEmit config msg drag =
    case ( msg, drag ) of
        ( StartDragging initialPosition, NotDragging ) ->
            ( DraggingTentative initialPosition, [] )

        ( DragAt newPosition, DraggingTentative oldPosition ) ->
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

        ( StopDragging, DraggingTentative _ ) ->
            ( NotDragging, maybeToList config.onClick )

        ( StopDragging, Dragging _ ) ->
            ( NotDragging, maybeToList config.onDragEnd )

        _ ->
            ( drag, [] )
                |> logInvalidState drag msg



-- utility


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
