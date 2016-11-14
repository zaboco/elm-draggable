module Tests exposing (..)

import Test exposing (Test)
import UpdateTests
import VectorTests


all : Test
all =
    Test.concat
        [ UpdateTests.all
        , VectorTests.all
        ]
