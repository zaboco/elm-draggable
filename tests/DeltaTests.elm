module DeltaTests exposing (..)

import Fuzz exposing (Fuzzer)
import Test exposing (..)
import Expect as Should
import Draggable.Delta as Delta exposing (..)
import Mouse exposing (Position)
import String


all : Test
all =
    describe "Delta"
        [ fuzz2 positionF positionF "translate by distance" <|
            \start end ->
                start
                    |> translate (distanceTo end start)
                    |> Should.equal end
        , fuzz2 positionF deltaF "distance to translated" <|
            \start delta ->
                start
                    |> distanceTo (translate delta start)
                    |> Should.equal delta
        , fuzz3 (Fuzz.intRange 1 100) Fuzz.int Fuzz.int "scale dx dy" <|
            \factor dx dy ->
                fromDxDy dx dy
                    |> scale (toFloat factor)
                    |> Should.equal (fromDxDy (dx * factor) (dy * factor))
        ]


positionF : Fuzzer Position
positionF =
    Fuzz.map2 Position Fuzz.int Fuzz.int


deltaF : Fuzzer Delta
deltaF =
    Fuzz.map2 fromDxDy Fuzz.int Fuzz.int
