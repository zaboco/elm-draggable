module Types exposing (Model(..), Msg(..))

import Mouse exposing (Position)


type Model
    = NoDrag
    | TentativeDrag Position
    | Dragging Position
    | Invalid Msg Model


type Msg
    = DragStart Position
    | DragAt Position
    | DragEnd
