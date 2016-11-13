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
    , onMouseDown : Maybe msg
    }


defaultConfig : Config msg
defaultConfig =
    { onDragStart = Nothing
    , onDragBy = \_ -> Nothing
    , onDragEnd = Nothing
    , onClick = Nothing
    , onMouseDown = Nothing
    }


updateAndEmit : Config msg -> Msg -> State -> ( State, List msg )
updateAndEmit config msg drag =
    case ( drag, msg ) of
        ( NotDragging, StartDragging initialPosition ) ->
            ( DraggingTentative initialPosition, maybeToList config.onMouseDown )

        ( DraggingTentative oldPosition, DragAt newPosition ) ->
            ( Dragging newPosition
            , List.concatMap maybeToList
                [ config.onDragStart
                , config.onDragBy (Delta.distanceTo newPosition oldPosition)
                ]
            )

        ( Dragging oldPosition, DragAt newPosition ) ->
            ( Dragging newPosition
            , maybeToList (config.onDragBy (Delta.distanceTo newPosition oldPosition))
            )

        ( DraggingTentative _, StopDragging ) ->
            ( NotDragging, maybeToList config.onClick )

        ( Dragging _, StopDragging ) ->
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
