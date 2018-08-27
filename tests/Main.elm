port module Main exposing (emit, main)

import Json.Encode exposing (Value)
import Test.Runner.Node exposing (TestProgram, run)
import Tests


main : TestProgram
main =
    run emit Tests.all


port emit : ( String, Value ) -> Cmd msg
