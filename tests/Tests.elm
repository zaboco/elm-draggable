module Tests exposing (..)

import Fuzz exposing (Fuzzer)
import Mouse exposing (Position)
import Test exposing (..)
import Expect as Should exposing (Expectation)
import Internal exposing (Delta, Key, Msg(..), State(..))


all : Test
all =
    describe "update"
        [ describe "single update" updateTests
        , describe
            "invalid updates leave the state unchanged"
            invalidUpdateTests
        , noEventsTest
        ]


type EmitMsg
    = OnDragStart Key
    | OnDragBy Delta
    | OnDragEnd
    | OnClick
    | OnMouseDown Key


updateWithEvents =
    Internal.updateAndEmit fullConfig


fullConfig : Internal.Config EmitMsg
fullConfig =
    { onDragStart = Just << OnDragStart
    , onDragBy = Just << OnDragBy
    , onDragEnd = Just OnDragEnd
    , onClick = Just OnClick
    , onMouseDown = Just << OnMouseDown
    }


defaultUpdate =
    Internal.updateAndEmit Internal.defaultConfig


defaultKey : String
defaultKey =
    "defaultKey"


startDragging : Position -> Msg
startDragging =
    StartDragging defaultKey


updateTests : List Test
updateTests =
    [ fuzz2 keyF positionF "NoDrag -[DragStart]-> DraggingTentative (onMouseDown)" <|
        \key startPosition ->
            NotDragging
                |> updateWithEvents (StartDragging key startPosition)
                |> Should.equal
                    ( DraggingTentative key startPosition
                    , [ OnMouseDown key ]
                    )
    , (fuzz3 keyF positionF positionF)
        "DraggingTentative -[DragAt]-> Dragging (onDragStart key)"
        (\key p1 p2 ->
            DraggingTentative key p1
                |> updateWithEvents (DragAt p2)
                |> Should.equal
                    ( Dragging p1
                    , [ OnDragStart key ]
                    )
        )
    , fuzz2 positionF positionF "Dragging -[DragAt]-> Dragging (onDragBy)" <|
        \p1 p2 ->
            Dragging p1
                |> updateWithEvents (DragAt p2)
                |> Should.equal ( Dragging p2, [ OnDragBy (Internal.distanceTo p2 p1) ] )
    , fuzz2 keyF positionF "DraggingTentative -[DragEnd]-> NoDrag (onClick, onMouseUp)" <|
        \key endPosition ->
            DraggingTentative key endPosition
                |> updateWithEvents StopDragging
                |> Should.equal ( NotDragging, [ OnClick ] )
    , fuzz positionF "Dragging -[DragEnd]-> NoDrag (onDragEnd, onMouseUp)" <|
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
    , fuzz3 keyF positionF positionF "Invalid DragStart from DraggingTentative" <|
        \key position startPosition ->
            DraggingTentative key position
                |> updateWithEvents (startDragging startPosition)
                |> Should.equal ( DraggingTentative key position, [] )
    , fuzz2 positionF positionF "Invalid DragStart from Dragging" <|
        \position startPosition ->
            Dragging position
                |> updateWithEvents (startDragging startPosition)
                |> Should.equal ( Dragging position, [] )
    ]


noEventsTest : Test
noEventsTest =
    fuzz2 positionF positionF "no events if none configured" <|
        \startPosition endPosition ->
            let
                andUpdate =
                    andThen << defaultUpdate
            in
                NotDragging
                    |> defaultUpdate (startDragging startPosition)
                    |> andUpdate (DragAt endPosition)
                    |> andUpdate StopDragging
                    |> andUpdate (startDragging startPosition)
                    |> andUpdate StopDragging
                    |> Should.equal ( NotDragging, [] )



-- Fuzzers


positionF : Fuzzer Position
positionF =
    Fuzz.map2 Position Fuzz.int Fuzz.int


keyF : Fuzzer Key
keyF =
    Fuzz.string



-- Update Helpers


type alias Emit msg model =
    ( model, List msg )


andThen : (a -> Emit msg a) -> Emit msg a -> Emit msg a
andThen f ( model, msgs ) =
    let
        ( newModel, newMsgs ) =
            f model
    in
        ( newModel, msgs ++ newMsgs )
