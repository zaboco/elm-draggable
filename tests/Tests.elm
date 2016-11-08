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
                    |> Should.equal ( NoDrag, Cmd.none )
        , fuzz positionF "DragEnd: Dragging -> NoDrag" <|
            \lastPosition ->
                Dragging lastPosition
                    |> D.update DragEnd
                    |> Should.equal ( NoDrag, Cmd.none )
        , fuzz3 positionF dragUpdatesF positionF "multi DragAt records last position" <|
            \firstPosition middleDragUpdates lastPosition ->
                Return.singleton NoDrag
                    |> andThen (D.update << DragStart <| firstPosition)
                    |> andThenAll middleDragUpdates
                    |> andThen (D.update << DragAt <| lastPosition)
                    |> shouldYield (Dragging lastPosition)
        , fuzz2 positionF dragUpdatesF "complete drag ends up in NoDrag" <|
            \firstPosition middleDragUpdates ->
                Return.singleton NoDrag
                    |> andThen (D.update << DragStart <| firstPosition)
                    |> andThenAll middleDragUpdates
                    |> andThen (D.update DragEnd)
                    |> shouldYield NoDrag
        ]



-- Fuzzers


dragUpdatesF : Fuzzer (List (Model -> Return Msg Model))
dragUpdatesF =
    list <| Fuzz.map (D.update << DragAt) <| positionF


positionF : Fuzzer Position
positionF =
    Fuzz.map2 Position int int



-- Expectation Helpers


shouldYield : model -> ( model, Cmd msg ) -> Expectation
shouldYield expected ( actual, _ ) =
    Should.equal expected actual



-- Return Helpers


andThenAll : List (a -> Return msg a) -> Return msg a -> Return msg a
andThenAll fns initial =
    fns |> List.foldl andThen initial


andThen : (a -> Return msg b) -> Return msg a -> Return msg b
andThen =
    flip Return.andThen
