module Tests exposing (..)

import Fuzz exposing (Fuzzer, int)
import Mouse exposing (Position)
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
                    |> Should.equal ( NoDrag, Cmd.none )
        , fuzz positionF "DragEnd: Dragging -> NoDrag" <|
            \lastPosition ->
                Dragging lastPosition
                    |> D.update DragEnd
                    |> Should.equal ( NoDrag, Cmd.none )
        ]


shouldYield : model -> ( model, Cmd msg ) -> Expectation
shouldYield expected ( actual, _ ) =
    Should.equal expected actual


positionF : Fuzzer Position
positionF =
    Fuzz.map2 Position int int
