module Tests exposing (..)

import Fuzz exposing (Fuzzer)
import Mouse exposing (Position)
import Test exposing (..)
import Expect as Should exposing (Expectation)
import Internal exposing (Delta, Msg(..), State(..))
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
    | OnDragBy Delta
    | OnDragEnd
    | OnClick
    | OnMouseDown String
    | OnMouseUp


updateWithEvents : UpdateEmitter EmitMsg
updateWithEvents =
    Internal.updateAndEmit fullConfig


fullConfig : Internal.Config EmitMsg
fullConfig =
    { onDragStart = Just OnDragStart
    , onDragBy = Just << OnDragBy
    , onDragEnd = Just OnDragEnd
    , onClick = Just OnClick
    , onMouseDown = Just << OnMouseDown
    , onMouseUp = Just OnMouseUp
    }


defaultUpdate : UpdateEmitter ()
defaultUpdate =
    Internal.updateAndEmit Internal.defaultConfig


defaultKey : String
defaultKey =
    "defaultKey"


startDragging : Position -> Msg
startDragging =
    StartDragging defaultKey


singleUpdateTests : List Test
singleUpdateTests =
    [ fuzz positionF "NoDrag -[DragStart]-> DragAttempt (onMouseDown)" <|
        \startPosition ->
            NotDragging
                |> updateWithEvents (startDragging startPosition)
                |> Should.equal
                    ( DraggingTentative startPosition
                    , [ OnMouseDown defaultKey ]
                    )
    , (fuzz2 positionF positionF)
        "TentativeDrag -[DragAt]-> Dragging (onDragStart, onDragBy)"
        (\p1 p2 ->
            DraggingTentative p1
                |> updateWithEvents (DragAt p2)
                |> Should.equal
                    ( Dragging p2
                    , [ OnDragStart, OnDragBy (Internal.distanceTo p2 p1) ]
                    )
        )
    , fuzz2 positionF positionF "Dragging -[DragAt]-> Dragging (onDragBy)" <|
        \p1 p2 ->
            Dragging p1
                |> updateWithEvents (DragAt p2)
                |> Should.equal ( Dragging p2, [ OnDragBy (Internal.distanceTo p2 p1) ] )
    , fuzz positionF "TentativeDrag -[DragEnd]-> NoDrag (onClick, onMouseUp)" <|
        \endPosition ->
            DraggingTentative endPosition
                |> updateWithEvents StopDragging
                |> Should.equal ( NotDragging, [ OnClick, OnMouseUp ] )
    , fuzz positionF "Dragging -[DragEnd]-> NoDrag (onDragEnd, onMouseUp)" <|
        \endPosition ->
            Dragging endPosition
                |> updateWithEvents StopDragging
                |> Should.equal ( NotDragging, [ OnDragEnd, OnMouseUp ] )
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
                |> updateWithEvents (startDragging startPosition)
                |> Should.equal ( DraggingTentative position, [] )
    , fuzz2 positionF positionF "Invalid DragStart from Dragging" <|
        \position startPosition ->
            Dragging position
                |> updateWithEvents (startDragging startPosition)
                |> Should.equal ( Dragging position, [] )
    ]


chainUpdateTests : List Test
chainUpdateTests =
    [ fuzz2 positionF positionsStrictF "DragStart DragAt+ DragEnd" <|
        \startPosition dragPositions ->
            let
                msgs =
                    List.concat
                        [ [ startDragging startPosition ]
                        , List.map DragAt dragPositions
                        , [ StopDragging ]
                        ]

                expectedState =
                    NotDragging

                expectedEvents =
                    List.concat
                        [ [ OnMouseDown defaultKey, OnDragStart ]
                        , List.map OnDragBy (deltas startPosition dragPositions)
                        , [ OnDragEnd, OnMouseUp ]
                        ]
            in
                NotDragging
                    |> chainUpdate updateWithEvents msgs
                    |> Should.equal ( expectedState, expectedEvents )
    , fuzz positionF "DragStart DragEnd" <|
        \startPosition ->
            let
                msgs =
                    [ startDragging startPosition, StopDragging ]

                expected =
                    ( NotDragging
                    , [ OnMouseDown defaultKey, OnClick, OnMouseUp ]
                    )
            in
                NotDragging
                    |> chainUpdate updateWithEvents msgs
                    |> Should.equal expected
    , fuzz2 positionF positionF "no events if none configured" <|
        \startPosition endPosition ->
            let
                msgs =
                    [ startDragging startPosition
                    , DragAt endPosition
                    , StopDragging
                    , startDragging endPosition
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
    List.map2 Internal.distanceTo rest (first :: rest)



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
