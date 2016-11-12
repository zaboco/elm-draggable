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


type alias Delta =
    { dx : Int
    , dy : Int
    }


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


updateAndEmit : Config msg -> Msg -> Drag -> Emit msg Drag
updateAndEmit config msg drag =
    case ( msg, drag ) of
        ( DragStart initialPosition, NoDrag ) ->
            ( TentativeDrag initialPosition, maybeToList config.onDragStart )

        ( DragAt newPosition, TentativeDrag oldPosition ) ->
            updateOnDragAt config newPosition oldPosition

        ( DragAt newPosition, Dragging oldPosition ) ->
            updateOnDragAt config newPosition oldPosition

        ( DragEnd, TentativeDrag _ ) ->
            ( NoDrag, maybeToList config.onClick )

        ( DragEnd, Dragging _ ) ->
            ( NoDrag, maybeToList config.onDragEnd )

        ( _, unknown ) ->
            case unknown of
                Invalid _ _ ->
                    ( unknown, [] )

                _ ->
                    ( Invalid msg drag, [] )


updateOnDragAt : Config msg -> Position -> Position -> Emit msg Drag
updateOnDragAt { onDragBy } newPosition oldPosition =
    let
        delta =
            { dx = newPosition.x - oldPosition.x
            , dy = newPosition.y - oldPosition.y
            }
    in
        ( Dragging newPosition, maybeToList (onDragBy delta) )
