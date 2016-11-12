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
            ( TentativeDrag initialPosition, [] )

        ( DragAt newPosition, TentativeDrag oldPosition ) ->
            ( Dragging newPosition
            , List.concatMap maybeToList
                [ config.onDragStart
                , config.onDragBy (distance oldPosition newPosition)
                ]
            )

        ( DragAt newPosition, Dragging oldPosition ) ->
            ( Dragging newPosition
            , maybeToList (config.onDragBy (distance oldPosition newPosition))
            )

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


distance : Position -> Position -> Delta
distance p1 p2 =
    { dx = p2.x - p1.x, dy = p2.y - p1.y }
