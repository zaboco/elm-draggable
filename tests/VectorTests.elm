module VectorTests exposing (..)

import Fuzz exposing (Fuzzer)
import Test exposing (..)
import Expect as Should exposing (Expectation)
import Draggable.Vector as Vector exposing (Vector, add, getX, getY, sub)
import Mouse exposing (Position)


all : Test
all =
    describe "Vector"
        [ fuzz2 vectorF vectorF "subtracting and then adding the same value" <|
            \start end ->
                end `sub` start `add` start |> shouldAlmostEqual end
        , fuzz2 vectorF vectorF "adding and then subtracting the same value" <|
            \start delta ->
                start `add` delta `sub` delta |> shouldAlmostEqual start
        , fuzz2 (Fuzz.floatRange 0.01 100) vectorF "scale in and out" <|
            \factor vector ->
                vector
                    |> Vector.scale factor
                    |> Vector.scale (1 / factor)
                    |> shouldAlmostEqual vector
        , fuzz2 Fuzz.int Fuzz.int "toPosition after fromPosition" <|
            \x y ->
                let
                    position =
                        { x = x, y = y }
                in
                    position
                        |> Vector.fromPosition
                        |> Vector.toPosition
                        |> Should.equal position
        ]


vectorF : Fuzzer Vector
vectorF =
    Fuzz.map2 Vector.init Fuzz.float Fuzz.float


shouldAlmostEqual : Vector -> Vector -> Expectation
shouldAlmostEqual first second =
    let
        dx =
            getX first - getX second

        dy =
            getY first - getY second

        tolerance =
            0.000001
    in
        ( abs dx, abs dy )
            |> Should.atMost ( tolerance, tolerance )
