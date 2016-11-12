module Tests exposing (..)

import Fuzz exposing (Fuzzer, int, list)
import Mouse exposing (Position)
import Test exposing (..)
import Expect as Should exposing (Expectation)
import Internal exposing (..)


all : Test
all =
    Test.concat
        [ updateResult
        , updateEvents
        ]


type alias UpdateEmitter =
    Msg -> Drag -> Emit Msg Drag


defaultUpdate : UpdateEmitter
defaultUpdate =
    updateAndEmit defaultConfig


updateResult : Test
updateResult =
    describe "update result"
        [ fuzz positionF "DragStart: NoDrag -> DragAttempt" <|
            \position ->
                NoDrag
                    |> defaultUpdate (DragStart position)
                    |> shouldYield (TentativeDrag position)
        , fuzz2 positionF positionF "DragAt: TentativeDrag -> Dragging" <|
            \oldPosition newPosition ->
                TentativeDrag oldPosition
                    |> defaultUpdate (DragAt newPosition)
                    |> shouldYield (Dragging newPosition)
        , fuzz2 positionF positionF "DragAt: Dragging -> Dragging" <|
            \oldPosition newPosition ->
                Dragging oldPosition
                    |> defaultUpdate (DragAt newPosition)
                    |> shouldYield (Dragging newPosition)
        , fuzz positionF "DragEnd: TentativeDrag -> NoDrag" <|
            \lastPosition ->
                TentativeDrag lastPosition
                    |> defaultUpdate DragEnd
                    |> shouldYield NoDrag
        , fuzz positionF "DragEnd: Dragging -> NoDrag" <|
            \lastPosition ->
                Dragging lastPosition
                    |> defaultUpdate DragEnd
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
                        |> chainUpdateEmit defaultUpdate msgs
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
                        |> chainUpdateEmit defaultUpdate msgs
                        |> shouldYield expected
        ]


type EmitMsg
    = OnDragStart
    | OnDragBy Delta
    | OnDragEnd
    | OnClick


updateEvents : Test
updateEvents =
    describe "update events"
        [ fuzz positionF "emits DragStart" <|
            \initialPosition ->
                let
                    config =
                        { defaultConfig | onDragStart = Just OnDragStart }
                in
                    NoDrag
                        |> updateAndEmit config (DragStart initialPosition)
                        |> shouldEmit [ OnDragStart ]
        , fuzz positionF "does not emit DragStart if not in config" <|
            \initialPosition ->
                let
                    config =
                        { defaultConfig | onDragStart = Nothing }
                in
                    NoDrag
                        |> updateAndEmit config (DragStart initialPosition)
                        |> shouldEmit []
        , testDragByEvent
            "emits DragBy when Dragging after TentativeDrag"
            TentativeDrag
        , testDragByEvent
            "emits DragBy when it keeps Dragging"
            Dragging
        , fuzz positionF "emits DragEnd if it was Dragging" <|
            \dragPosition ->
                let
                    config =
                        { defaultConfig | onDragEnd = Just OnDragEnd }
                in
                    Dragging dragPosition
                        |> updateAndEmit config DragEnd
                        |> shouldEmit [ OnDragEnd ]
        , fuzz positionF "emits Click if it stops dragging after TentativeDrag" <|
            \dragPosition ->
                let
                    config =
                        { defaultConfig | onClick = Just OnClick }
                in
                    TentativeDrag dragPosition
                        |> updateAndEmit config DragEnd
                        |> shouldEmit [ OnClick ]
        ]


testDragByEvent : String -> (Position -> Drag) -> Test
testDragByEvent desc draggedAt =
    fuzz2 positionF positionF desc <|
        \p1 p2 ->
            let
                delta =
                    { dx = p2.x - p1.x, dy = p2.y - p1.y }

                config =
                    { defaultConfig | onDragBy = Just << OnDragBy }
            in
                draggedAt p1
                    |> updateAndEmit config (DragAt p2)
                    |> shouldEmit [ OnDragBy delta ]



-- Fuzzers


dragsF : Fuzzer (List Msg)
dragsF =
    list <| Fuzz.map DragAt <| positionF


positionF : Fuzzer Position
positionF =
    Fuzz.map2 Position int int



-- Expectation Helpers


shouldYield : model -> ( model, x ) -> Expectation
shouldYield expected ( actual, _ ) =
    Should.equal expected actual


shouldEmit : List msg -> ( x, List msg ) -> Expectation
shouldEmit expected ( _, actual ) =
    Should.equal expected actual



-- Return Helpers


chainUpdateEmit : UpdateEmitter -> List Msg -> Drag -> Emit Msg Drag
chainUpdateEmit update msgs model =
    List.foldl (andThenEmit << update) ( model, [] ) msgs


andThenEmit : (a -> Emit msg a) -> Emit msg a -> Emit msg a
andThenEmit f ( model, msgs ) =
    let
        ( newModel, newMsgs ) =
            f model
    in
        ( newModel, msgs ++ newMsgs )
