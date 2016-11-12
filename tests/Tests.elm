module Tests exposing (..)

import Test exposing (Test)
import UpdateTests
import DeltaTests


all : Test
all =
    Test.concat
        [ UpdateTests.all
        , DeltaTests.all
        ]
