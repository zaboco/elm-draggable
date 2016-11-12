module Draggable.Delta exposing (Delta, fromDxDy, distanceTo, translate)

{-| This module provides means of manipulationg the Delta value received on the
`onDragBy` event.

# Definition
@docs Delta

# Init
@docs fromDxDy

# Utils
@docs distance, translate
-}

import Mouse exposing (Position)


{-| Represents the difference between the last position of the mouse and the current one
-}
type Delta
    = Delta { dx : Int, dy : Int }


{-| Creates a delta
-}
fromDxDy : Int -> Int -> Delta
fromDxDy dx dy =
    Delta { dx = dx, dy = dy }


{-| Gets the distance between two positions

    distance (Position 10 10) (Position 11 12) == delta 1 2
-}
distanceTo : Position -> Position -> Delta
distanceTo b a =
    Delta { dx = b.x - a.x, dy = b.y - a.y }


{-| Translates the given position by `delta`.

    translate (delta 1 2) (Position 10 10) == Position 11 12
-}
translate : Delta -> Position -> Position
translate (Delta { dx, dy }) { x, y } =
    { x = x + dx, y = y + dy }
