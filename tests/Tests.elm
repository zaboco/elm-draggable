module Tests exposing (..)

import Fuzz exposing (Fuzzer, int, list)
import Mouse exposing (Position)
import Return exposing (Return)
import Test exposing (..)
import Expect as Should exposing (Expectation)
import Draggable as D
import Types exposing (Model(..), Msg(..))


all : Test
all =
    describe "update result"
        [ fuzz positionF "DragStart: NoDrag -> DragAttempt" <|
            \position ->
                NoDrag
                    |> D.update (DragStart position)
                    |> shouldYield (TentativeDrag position)
        , fuzz2 positionF positionF "DragAt: TentativeDrag -> Dragging" <|
            \oldPosition newPosition ->
                TentativeDrag oldPosition
                    |> D.update (DragAt newPosition)
                    |> shouldYield (Dragging newPosition)
        , fuzz2 positionF positionF "DragAt: Dragging -> Dragging" <|
            \oldPosition newPosition ->
                Dragging oldPosition
                    |> D.update (DragAt newPosition)
                    |> shouldYield (Dragging newPosition)
        , fuzz positionF "DragEnd: TentativeDrag -> NoDrag" <|
            \lastPosition ->
                TentativeDrag lastPosition
                    |> D.update DragEnd
                    |> shouldYield NoDrag
        , fuzz positionF "DragEnd: Dragging -> NoDrag" <|
            \lastPosition ->
                Dragging lastPosition
                    |> D.update DragEnd
                    |> shouldYield NoDrag
        , fuzz3 positionF dragsF positionF "multi DragAt records last position" <|
            \firstPosition middleDrags lastPosition ->
                let
                    msgs =
                        [ DragStart firstPosition ] ++ middleDrags ++ [ DragAt lastPosition ]

                    expected =
                        Dragging lastPosition
                in
                    NoDrag
                        |> chainUpdate msgs
                        |> shouldYield expected
        , fuzz2 positionF dragsF "complete drag ends up in NoDrag" <|
            \firstPosition middleDrags ->
                let
                    msgs =
                        [ DragStart firstPosition ] ++ middleDrags ++ [ DragEnd ]

                    expected =
                        NoDrag
                in
                    NoDrag
                        |> chainUpdate msgs
                        |> shouldYield expected
        ]



-- Fuzzers


dragsF : Fuzzer (List Msg)
dragsF =
    list <| Fuzz.map DragAt <| positionF


positionF : Fuzzer Position
positionF =
    Fuzz.map2 Position int int



-- Expectation Helpers


shouldYield : model -> ( model, Cmd msg ) -> Expectation
shouldYield expected ( actual, _ ) =
    Should.equal expected actual



-- Return Helpers


chainUpdate : List Msg -> Model -> Return Msg Model
chainUpdate msgs model =
    List.foldl (andThen << D.update) (Return.singleton model) msgs


andThen : (a -> Return msg b) -> Return msg a -> Return msg b
andThen =
    flip Return.andThen
