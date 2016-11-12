module Internal exposing (..)

import Mouse exposing (Position)
import Maybe.Extra exposing (maybeToList)


type Drag
    = NoDrag
    | TentativeDrag Position
    | Dragging Position
    | Invalid Msg Drag


type Msg
    = DragStart Position
    | DragAt Position
    | DragEnd


type alias Emit msg model =
    ( model, List msg )


type alias Config msg =
    { onDragStart : Maybe msg
    , onDragAt : Position -> Maybe msg
    }


defaultConfig : Config msg
defaultConfig =
    { onDragStart = Nothing
    , onDragAt = \_ -> Nothing
    }


updateAndEmit : Config msg -> Msg -> Drag -> Emit msg Drag
updateAndEmit config msg drag =
    case ( msg, drag ) of
        ( DragStart initialPosition, NoDrag ) ->
            ( TentativeDrag initialPosition, maybeToList config.onDragStart )

        ( DragAt newPosition, TentativeDrag _ ) ->
            ( Dragging newPosition, maybeToList (config.onDragAt newPosition) )

        ( DragAt newPosition, Dragging _ ) ->
            ( Dragging newPosition, [] )

        ( DragEnd, TentativeDrag _ ) ->
            ( NoDrag, [] )

        ( DragEnd, Dragging _ ) ->
            ( NoDrag, [] )

        ( _, unknown ) ->
            case unknown of
                Invalid _ _ ->
                    ( unknown, [] )

                _ ->
                    ( Invalid msg drag, [] )
