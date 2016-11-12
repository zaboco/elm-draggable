module DeltaTests exposing (..)

import Fuzz exposing (Fuzzer)
import Test exposing (..)
import Expect as Should
import Draggable.Delta as Delta exposing (..)
import Mouse exposing (Position)


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
        ]


positionF : Fuzzer Position
positionF =
    Fuzz.map2 Position Fuzz.int Fuzz.int


deltaF : Fuzzer Delta
deltaF =
    Fuzz.map2 fromDxDy Fuzz.int Fuzz.int
