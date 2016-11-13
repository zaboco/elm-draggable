module Draggable.Delta
    exposing
        ( Delta
        , fromDxDy
        , distanceTo
        , translate
        , scale
        )

{-| This module provides means of manipulationg the Delta value received on the
`onDragBy` event.

# Definition
@docs Delta

# Init
@docs fromDxDy

# Position utilities
@docs distanceTo, translate

# Delta modifiers
@docs scale
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

    distance (Position 10 10) (Position 11 12) == fromDxDy 1 2
-}
distanceTo : Position -> Position -> Delta
distanceTo b a =
    Delta { dx = b.x - a.x, dy = b.y - a.y }


{-| Translates the given position by `delta`.

    translate (fromDxDy 1 2) (Position 10 10) == Position 11 12
-}
translate : Delta -> Position -> Position
translate (Delta { dx, dy }) { x, y } =
    { x = x + dx, y = y + dy }


{-| Scales delta on both dimensions

    scale 2 (fromDxDy 1 2) == fromDxDy 2 4
-}
scale : Float -> Delta -> Delta
scale factor (Delta { dx, dy }) =
    let
        twoDecimalsFactor =
            factor
                |> (*) 100
                |> round
                |> toFloat
                |> flip (/) 100

        scaleOne coord =
            coord
                |> toFloat
                |> (*) twoDecimalsFactor
                |> ceiling
    in
        Delta { dx = scaleOne dx, dy = scaleOne dy }
