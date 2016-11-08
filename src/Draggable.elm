module Draggable
    exposing
        ( Drag
        , update
        )

import Mouse exposing (Position)
import Types exposing (Model(..), Msg(..))


type alias Drag =
    Model


update : Msg -> Drag -> ( Drag, Cmd msg )
update msg drag =
    case ( msg, drag ) of
        ( DragStart initialPosition, NoDrag ) ->
            ( TentativeDrag initialPosition, Cmd.none )

        ( DragAt newPosition, TentativeDrag _ ) ->
            ( Dragging newPosition, Cmd.none )

        ( DragAt newPosition, Dragging _ ) ->
            ( Dragging newPosition, Cmd.none )

        ( DragEnd, TentativeDrag _ ) ->
            ( NoDrag, Cmd.none )

        ( DragEnd, Dragging _ ) ->
            ( NoDrag, Cmd.none )

        ( _, unknown ) ->
            case unknown of
                Invalid _ _ ->
                    ( unknown, Cmd.none )

                _ ->
                    ( Invalid msg drag, Cmd.none )
