module Draggable
    exposing
        ( State
        , Msg
        , Delta
        , Config
        , Event
        , DragEvent(..)
        , basicConfig
        , customConfig
        , mouseTrigger
        , customMouseTrigger
        , newMouseTrigger
        , newCustomMouseTrigger
        , init
        , update
        , subscriptions
        , newSubscription
        , basicSubscription
        )

{-|
This library provides and easy way to make DOM elements (Html or Svg) draggable.

## When is dragging considered?
An element is considered to be dragging when the mouse is pressed **and** moved before it is released. Otherwise, the action is considered a click. This is useful because in some cases you may want to support both actions.

[See examples](https://github.com/zaboco/elm-draggable/tree/master/examples)


# Initial State
@docs init

# Config
@docs basicConfig, customConfig

# Update
@docs update, subscriptions, newSubscription, basicSubscription

# DOM trigger
@docs mouseTrigger, customMouseTrigger, newMouseTrigger, newCustomMouseTrigger

# Definitions
@docs Delta, State, Msg, Config, Event, DragEvent
-}

import Cmd.Extra
import Internal exposing (State(..))
import Json.Decode as Decode exposing (Decoder)
import Mouse exposing (Position)
import VirtualDom


{-| A type alias representing the distance between two drag points.
-}
type alias Delta =
    ( Float, Float )


{-| Drag state to be included in model.
-}
type State a
    = State (Internal.State a)


{-| A message type for updating the internal drag state.
-}
type Msg a
    = Msg (Internal.Msg a)


{-| An event declaration for the draggable config
-}
type alias Event a msg =
    Internal.Event a msg


{-| -}
type DragEvent
    = DragStart
    | DragBy Delta
    | DragEnd
    | Click


{-| Initial drag state
-}
init : State a
init =
    State Internal.NotDragging


{-| Handle update messages for the draggable model. It assumes that the drag state will be stored under the key `drag`.
-}
update :
    Config a msg
    -> Msg a
    -> { m | drag : State a }
    -> ( { m | drag : State a }, Cmd msg )
update config msg model =
    let
        ( dragState, dragCmd ) =
            updateDraggable config msg model.drag
    in
        { model | drag = dragState } ! [ dragCmd ]


updateDraggable : Config a msg -> Msg a -> State a -> ( State a, Cmd msg )
updateDraggable (Config config) (Msg msg) (State drag) =
    let
        ( newDrag, newMsgMaybe ) =
            Internal.updateAndEmit config msg drag
    in
        ( State newDrag, Cmd.Extra.optionalMessage newMsgMaybe )


{-| Handle mouse subscriptions used for dragging
-}
subscriptions : (Msg a -> msg) -> State a -> Sub msg
subscriptions envelope (State drag) =
    case drag of
        Internal.NotDragging ->
            Sub.none

        _ ->
            [ Mouse.moves Internal.DragAt, Mouse.ups (\_ -> Internal.StopDragging) ]
                |> Sub.batch
                |> Sub.map (envelope << Msg)


{-| -}
newSubscription : (State a -> DragEvent -> msg) -> State a -> Sub msg
newSubscription dragHandler (State drag) =
    Sub.batch
        [ handleMoves dragHandler drag
        , handleMouseups dragHandler drag
        ]


{-| -}
basicSubscription : (State a -> Delta -> msg) -> State a -> Sub msg
basicSubscription moveHandler =
    let
        dragHandler drag event =
            case event of
                DragBy delta ->
                    moveHandler drag delta

                _ ->
                    moveHandler drag ( 0, 0 )
    in
        newSubscription dragHandler


handleMoves : (State a -> DragEvent -> msg) -> Internal.State a -> Sub msg
handleMoves moveHandler drag =
    case drag of
        Dragging oldPosition ->
            Mouse.moves
                (\newPosition ->
                    moveHandler
                        (State <| Dragging newPosition)
                        (DragBy <| Internal.distanceTo newPosition oldPosition)
                )

        NotDragging ->
            Sub.none

        DraggingTentative _ oldPosition ->
            Mouse.moves (\_ -> moveHandler (State <| Dragging oldPosition) DragStart)


handleMouseups : (State a -> DragEvent -> msg) -> Internal.State a -> Sub msg
handleMouseups moveHandler drag =
    case drag of
        NotDragging ->
            Sub.none

        DraggingTentative _ _ ->
            Mouse.ups (\_ -> moveHandler (State NotDragging) Click)

        Dragging _ ->
            Mouse.ups (\_ -> moveHandler (State NotDragging) DragEnd)


{-| DOM event handler to start dragging on mouse down. It requires a key for the element, in order to provide support for multiple drag targets sharing the same drag state. Of course, if only one element is draggable, it can have any value, including `()`.

    div [ mouseTrigger "element-id" DragMsg ] [ text "Drag me" ]
-}
mouseTrigger : a -> (Msg a -> msg) -> VirtualDom.Property msg
mouseTrigger key envelope =
    VirtualDom.onWithOptions "mousedown"
        ignoreDefaults
        (Decode.map envelope (positionDecoder key))


{-| DOM event handler to start dragging on mouse down and also sending custom information about the `mousedown` event. It does so by using a custom `Decoder` for the [`MouseEvent`](https://developer.mozilla.org/en-US/docs/Web/API/MouseEvent).

    div [ mouseTrigger offsetDecoder CustomDragMsg ] [ text "Drag me" ]
-}
customMouseTrigger : Decoder a -> (Msg () -> a -> msg) -> VirtualDom.Property msg
customMouseTrigger customDecoder customEnvelope =
    VirtualDom.onWithOptions "mousedown"
        ignoreDefaults
        (Decode.map2 customEnvelope (positionDecoder ()) customDecoder)


{-| -}
newMouseTrigger : a -> (State a -> msg) -> VirtualDom.Property msg
newMouseTrigger key stateHandler =
    VirtualDom.onWithOptions "mousedown"
        ignoreDefaults
        (Decode.map stateHandler (newPositionDecoder key))


{-| -}
newCustomMouseTrigger : Decoder a -> (State () -> a -> msg) -> VirtualDom.Property msg
newCustomMouseTrigger customDecoder customStateHandler =
    VirtualDom.onWithOptions "mousedown"
        ignoreDefaults
        (Decode.map2 customStateHandler (newPositionDecoder ()) customDecoder)


newPositionDecoder : a -> Decoder (State a)
newPositionDecoder key =
    Mouse.position
        |> Decode.map (State << Internal.DraggingTentative key)
        |> whenLeftMouseButtonPressed


positionDecoder : a -> Decoder (Msg a)
positionDecoder key =
    Mouse.position
        |> Decode.map (Msg << Internal.StartDragging key)
        |> whenLeftMouseButtonPressed


ignoreDefaults : VirtualDom.Options
ignoreDefaults =
    VirtualDom.Options True True


whenLeftMouseButtonPressed : Decoder a -> Decoder a
whenLeftMouseButtonPressed decoder =
    Decode.field "button" Decode.int
        |> Decode.andThen
            (\button ->
                case button of
                    -- https://www.w3.org/TR/DOM-Level-2-Events/events.html#Events-MouseEvent
                    -- 0 indicates the primary (usually left) mouse button
                    0 ->
                        decoder

                    _ ->
                        Decode.fail "Event is only relevant when the main mouse button was pressed."
            )



-- CONFIG


{-| Configuration of a draggable model.
-}
type Config a msg
    = Config (Internal.Config a msg)


{-| Basic config

    config = basicConfig OnDragBy
-}
basicConfig : (Delta -> msg) -> Config a msg
basicConfig onDragByListener =
    let
        defaultConfig =
            Internal.defaultConfig
    in
        Config { defaultConfig | onDragBy = Just << onDragByListener }


{-| Custom config, including arbitrary options. See [`Events`](#Draggable-Events).

    config = customConfig
        [ onDragBy OnDragBy
        , onDragStart OnDragStart
        , onDragEnd OnDragEnd
        ]
-}
customConfig : List (Event a msg) -> Config a msg
customConfig events =
    Config <| List.foldl (<|) Internal.defaultConfig events
