module Tests exposing (..)

import Fuzz exposing (Fuzzer)
import Mouse exposing (Position)
import Test exposing (..)
import Expect as Should exposing (Expectation)
import Internal exposing (Delta, Msg(..), State(..))


all : Test
all =
    describe "update"
        [ describe "single update" updateTests
        , describe
            "invalid updates leave the state unchanged"
            invalidUpdateTests
        , noEventsTest
        ]


type Key
    = Key String


type EmitMsg a
    = OnDragStart a
    | OnDragBy Delta
    | OnDragEnd
    | OnClick a
    | OnMouseDown a


updateWithEvents : Msg a -> State a -> ( State a, Maybe (EmitMsg a) )
updateWithEvents =
    Internal.updateAndEmit fullConfig


fullConfig : Internal.Config a (EmitMsg a)
fullConfig =
    { onDragStart = Just << OnDragStart
    , onDragBy = Just << OnDragBy
    , onDragEnd = Just OnDragEnd
    , onClick = Just << OnClick
    , onMouseDown = Just << OnMouseDown
    }


defaultUpdate : Msg a -> State a -> ( State a, Maybe msg )
defaultUpdate =
    Internal.updateAndEmit Internal.defaultConfig


defaultKey : Key
defaultKey =
    Key "defaultKey"


startDragging : Position -> Msg Key
startDragging =
    StartDragging defaultKey


updateTests : List Test
updateTests =
    [ fuzz2 keyF positionF "NoDrag -[DragStart]-> DraggingTentative (onMouseDown key)" <|
        \key startPosition ->
            NotDragging
                |> updateWithEvents (StartDragging key startPosition)
                |> Should.equal
                    ( DraggingTentative key startPosition
                    , Just (OnMouseDown key)
                    )
    , (fuzz3 keyF positionF positionF)
        "DraggingTentative -[DragAt]-> Dragging (onDragStart key)"
        (\key p1 p2 ->
            DraggingTentative key p1
                |> updateWithEvents (DragAt p2)
                |> Should.equal
                    ( Dragging p1
                    , Just (OnDragStart key)
                    )
        )
    , fuzz2 positionF positionF "Dragging -[DragAt]-> Dragging (onDragBy delta)" <|
        \p1 p2 ->
            Dragging p1
                |> updateWithEvents (DragAt p2)
                |> Should.equal ( Dragging p2, Just <| OnDragBy (Internal.distanceTo p2 p1) )
    , fuzz2 keyF positionF "DraggingTentative -[StopDragging]-> NotDragging (onClick key)" <|
        \key endPosition ->
            DraggingTentative key endPosition
                |> updateWithEvents StopDragging
                |> Should.equal ( NotDragging, Just (OnClick key) )
    , fuzz positionF "Dragging -[StopDragging]-> NotDragging (onDragEnd)" <|
        \endPosition ->
            Dragging endPosition
                |> updateWithEvents StopDragging
                |> Should.equal ( NotDragging, Just OnDragEnd )
    ]


invalidUpdateTests : List Test
invalidUpdateTests =
    [ fuzz positionF "Invalid DragAt from NoDrag" <|
        \position ->
            NotDragging
                |> updateWithEvents (DragAt position)
                |> Should.equal ( NotDragging, Nothing )
    , test "Invalid DragEnd from NoDrag" <|
        \() ->
            NotDragging
                |> updateWithEvents StopDragging
                |> Should.equal ( NotDragging, Nothing )
    , fuzz3 keyF positionF positionF "Invalid DragStart from DraggingTentative" <|
        \key position startPosition ->
            DraggingTentative key position
                |> updateWithEvents (startDragging startPosition)
                |> Should.equal ( DraggingTentative key position, Nothing )
    , fuzz2 positionF positionF "Invalid DragStart from Dragging" <|
        \position startPosition ->
            Dragging position
                |> updateWithEvents (startDragging startPosition)
                |> Should.equal ( Dragging position, Nothing )
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
                    |> Should.equal ( NotDragging, Nothing )



-- Fuzzers


positionF : Fuzzer Position
positionF =
    Fuzz.map2 Position Fuzz.int Fuzz.int


keyF : Fuzzer Key
keyF =
    Fuzz.map Key Fuzz.string



-- Update Helpers


type alias Emit msg model =
    ( model, Maybe msg )


andThen : (a -> Emit msg a) -> Emit msg a -> Emit msg a
andThen f ( model, msgMaybe ) =
    let
        ( newModel, newMsgMaybe ) =
            f model
    in
        ( newModel, msgMaybe |> Maybe.andThen (\_ -> newMsgMaybe) )
