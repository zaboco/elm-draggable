module Draggable.Vector
    exposing
        ( Vector
        , init
        , getX
        , getY
        , add
        , sub
        , scale
        , fromPosition
        , toPosition
        )

{-| This module provides means of manipulationg positions and deltas.

# Definition
@docs Vector

# Init
@docs init

# Getters
@docs getX, getY

# Operations
@docs add, sub, scale

# Conversions
@docs fromPosition, toPosition
-}

import Mouse exposing (Position)
import String


{-| Two dimensional vector type.
-}
type Vector
    = Vector
        { x : Float
        , y : Float
        }


{-| Create a new vector.
-}
init : Float -> Float -> Vector
init x y =
    Vector { x = x, y = y }


{-| Add two vectors.

    add (init 1 2) (init 10 20) == init 11 22

This operation is needed when calculating the new position on drag:

    OnDragBy delta ->
        ( { model | xy = add delta model.xy }, Cmd.none)

See [BasicExample](https://github.com/zaboco/elm-draggable/blob/master/examples/BasicExample.elm)
-}
add : Vector -> Vector -> Vector
add (Vector first) (Vector second) =
    init
        (first.x + second.x)
        (first.y + second.y)


{-| Subtract two vectors. Can be used to get distance between two points.

    sub (init 100 100) (init 150 350) == init (50 250)
-}
sub : Vector -> Vector -> Vector
sub first second =
    first `add` (scale -1 second)


{-| Scale a vector by a factor.

    scale 2 (init 10 30) == init 20 60

Can be used when zooming is involved. An update of the position would look something like:

    xy = xy |> add (delta |> scale (-1 / zoom))

See [PanAndZoomExample](https://github.com/zaboco/elm-draggable/blob/master/examples/PanAndZoomExample.elm)
-}
scale : Float -> Vector -> Vector
scale factor (Vector { x, y }) =
    init
        (factor * x)
        (factor * y)


{-| Extract the x component of a vector.
-}
getX : Vector -> Float
getX (Vector { x }) =
    x


{-| Extract the y component of a vector.
-}
getY : Vector -> Float
getY (Vector { y }) =
    y


{-| Convert a Vector to a mouse Position.
-}
toPosition : Vector -> Position
toPosition (Vector { x, y }) =
    Position (round x) (round y)


{-| Convert a mouse Position to a Vector.
-}
fromPosition : Position -> Vector
fromPosition { x, y } =
    init (toFloat x) (toFloat y)
