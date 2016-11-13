module UpdateTests exposing (..)

import Fuzz exposing (Fuzzer)
import Mouse exposing (Position)
import Test exposing (..)
import Expect as Should exposing (Expectation)
import Internal exposing (State(..), Msg(..))
import Draggable.Delta as Delta exposing (Delta)
import String


all : Test
all =
    describe "update"
        [ describe "single update" singleUpdateTests
        , describe "chain update" chainUpdateTests
        , describe
            "invalid updates leave the state unchanged"
            invalidUpdateTests
        ]


type EmitMsg
    = OnDragStart
    | OnDragBy Delta.Delta
    | OnDragEnd
    | OnClick


updateWithEvents : UpdateEmitter EmitMsg
updateWithEvents =
    Internal.updateAndEmit fullConfig


fullConfig : Internal.Config EmitMsg
fullConfig =
    { onDragStart = Just OnDragStart
    , onDragBy = Just << OnDragBy
    , onDragEnd = Just OnDragEnd
    , onClick = Just OnClick
    }


defaultUpdate : UpdateEmitter ()
defaultUpdate =
    Internal.updateAndEmit Internal.defaultConfig


singleUpdateTests : List Test
singleUpdateTests =
    [ fuzz positionF "NoDrag -[DragStart]-> DragAttempt (onDragStart)" <|
        \startPosition ->
            NotDragging
                |> updateWithEvents (StartDragging startPosition)
                |> Should.equal ( DraggingTentative startPosition, [] )
    , fuzz2 positionF positionF "TentativeDrag -[DragAt]-> Dragging (onDragBy)" <|
        \p1 p2 ->
            DraggingTentative p1
                |> updateWithEvents (DragAt p2)
                |> Should.equal
                    ( Dragging p2
                    , [ OnDragStart, OnDragBy (Delta.distanceTo p2 p1) ]
                    )
    , fuzz2 positionF positionF "Dragging -[DragAt]-> Dragging (onDragBy)" <|
        \p1 p2 ->
            Dragging p1
                |> updateWithEvents (DragAt p2)
                |> Should.equal ( Dragging p2, [ OnDragBy (Delta.distanceTo p2 p1) ] )
    , fuzz positionF "TentativeDrag -[DragEnd]-> NoDrag (onClick)" <|
        \endPosition ->
            DraggingTentative endPosition
                |> updateWithEvents StopDragging
                |> Should.equal ( NotDragging, [ OnClick ] )
    , fuzz positionF "Dragging -[DragEnd]-> NoDrag (onDragEnd)" <|
        \endPosition ->
            Dragging endPosition
                |> updateWithEvents StopDragging
                |> Should.equal ( NotDragging, [ OnDragEnd ] )
    ]


invalidUpdateTests : List Test
invalidUpdateTests =
    [ fuzz positionF "Invalid DragAt from NoDrag" <|
        \position ->
            NotDragging
                |> updateWithEvents (DragAt position)
                |> Should.equal ( NotDragging, [] )
    , test "Invalid DragEnd from NoDrag" <|
        \() ->
            NotDragging
                |> updateWithEvents StopDragging
                |> Should.equal ( NotDragging, [] )
    , fuzz2 positionF positionF "Invalid DragStart from TentativeDrag" <|
        \position startPosition ->
            DraggingTentative position
                |> updateWithEvents (StartDragging startPosition)
                |> Should.equal ( DraggingTentative position, [] )
    , fuzz2 positionF positionF "Invalid DragStart from Dragging" <|
        \position startPosition ->
            Dragging position
                |> updateWithEvents (StartDragging startPosition)
                |> Should.equal ( Dragging position, [] )
    ]


chainUpdateTests : List Test
chainUpdateTests =
    [ fuzz2 positionF positionsStrictF "DragStart DragAt+ DragEnd" <|
        \startPosition dragPositions ->
            let
                msgs =
                    List.concat
                        [ [ StartDragging startPosition ]
                        , List.map DragAt dragPositions
                        , [ StopDragging ]
                        ]

                expectedState =
                    NotDragging

                expectedEvents =
                    List.concat
                        [ [ OnDragStart ]
                        , List.map OnDragBy (deltas startPosition dragPositions)
                        , [ OnDragEnd ]
                        ]
            in
                NotDragging
                    |> chainUpdate updateWithEvents msgs
                    |> Should.equal ( expectedState, expectedEvents )
    , fuzz positionF "DragStart DragEnd" <|
        \startPosition ->
            let
                msgs =
                    [ StartDragging startPosition, StopDragging ]

                expected =
                    ( NotDragging, [ OnClick ] )
            in
                NotDragging
                    |> chainUpdate updateWithEvents msgs
                    |> Should.equal expected
    , fuzz2 positionF positionF "no events if none configured" <|
        \startPosition endPosition ->
            let
                msgs =
                    [ StartDragging startPosition
                    , DragAt endPosition
                    , StopDragging
                    , StartDragging endPosition
                    , StopDragging
                    ]

                expected =
                    ( NotDragging, [] )
            in
                NotDragging
                    |> chainUpdate defaultUpdate msgs
                    |> Should.equal expected
    ]


deltas : Position -> List Position -> List Delta
deltas first rest =
    List.map2 Delta.distanceTo rest (first :: rest)



-- Fuzzers


positionsStrictF : Fuzzer (List Position)
positionsStrictF =
    Fuzz.map2 (::) positionF (Fuzz.list positionF)


positionF : Fuzzer Position
positionF =
    Fuzz.map2 Position Fuzz.int Fuzz.int



-- Update Helpers


type alias Emit msg model =
    ( model, List msg )


type alias UpdateEmitter msg =
    Msg -> State -> Emit msg State


chainUpdate : UpdateEmitter msg -> List Msg -> State -> Emit msg State
chainUpdate update msgs model =
    List.foldl (andThenEmit << update) ( model, [] ) msgs


andThenEmit : (a -> Emit msg a) -> Emit msg a -> Emit msg a
andThenEmit f ( model, msgs ) =
    let
        ( newModel, newMsgs ) =
            f model
    in
        ( newModel, msgs ++ newMsgs )
