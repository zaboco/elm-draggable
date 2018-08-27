module Draggable exposing
    ( init
    , basicConfig, customConfig
    , update, subscriptions
    , mouseTrigger, customMouseTrigger, touchTriggers
    , Delta, State, Msg, Config, Event
    )

{-| This library provides and easy way to make DOM elements (Html or Svg) draggable.


## When is dragging considered?

An element is considered to be dragging when the mouse is pressed **and** moved before it is released. Otherwise, the action is considered a click. This is useful because in some cases you may want to support both actions.

[See examples](https://github.com/zaboco/elm-draggable/tree/master/examples)


# Initial State

@docs init


# Config

@docs basicConfig, customConfig


# Update

@docs update, subscriptions


# DOM trigger

@docs mouseTrigger, customMouseTrigger, touchTriggers


# Definitions

@docs Delta, State, Msg, Config, Event

-}

import Cmd.Extra
import Internal
import Json.Decode as Decode exposing (Decoder)
import Mouse exposing (Position)
import SingleTouch
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
    ( { model | drag = dragState }
    , dragCmd
    )


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


{-| DOM event handler to start dragging on mouse down. It requires a key for the element, in order to provide support for multiple drag targets sharing the same drag state. Of course, if only one element is draggable, it can have any value, including `()`.

    div [ mouseTrigger "element-id" DragMsg ] [ text "Drag me" ]

-}
mouseTrigger : a -> (Msg a -> msg) -> VirtualDom.Property msg
mouseTrigger key envelope =
    VirtualDom.onWithOptions "mousedown"
        ignoreDefaults
        (Decode.map envelope (positionDecoder key))


{-| DOM event handlers to manage dragging based on touch events. See `mouseTrigger` for details on the `key` parameter.
-}
touchTriggers : a -> (Msg a -> msg) -> List (VirtualDom.Property msg)
touchTriggers key envelope =
    let
        touchToMouse =
            \{ clientX, clientY } -> Mouse.Position (round clientX) (round clientY)

        mouseToEnv internal =
            touchToMouse >> internal >> Msg >> envelope
    in
    [ SingleTouch.onStart <| mouseToEnv (Internal.StartDragging key)
    , SingleTouch.onMove <| mouseToEnv Internal.DragAt
    , SingleTouch.onEnd <| mouseToEnv (\_ -> Internal.StopDragging)
    ]


{-| DOM event handler to start dragging on mouse down and also sending custom information about the `mousedown` event. It does so by using a custom `Decoder` for the [`MouseEvent`](https://developer.mozilla.org/en-US/docs/Web/API/MouseEvent).

    div [ mouseTrigger offsetDecoder CustomDragMsg ] [ text "Drag me" ]

-}
customMouseTrigger : Decoder a -> (Msg () -> a -> msg) -> VirtualDom.Property msg
customMouseTrigger customDecoder customEnvelope =
    VirtualDom.onWithOptions "mousedown"
        ignoreDefaults
        (Decode.map2 customEnvelope (positionDecoder ()) customDecoder)


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

    config =
        basicConfig OnDragBy

-}
basicConfig : (Delta -> msg) -> Config a msg
basicConfig onDragByListener =
    let
        defaultConfig =
            Internal.defaultConfig
    in
    Config { defaultConfig | onDragBy = Just << onDragByListener }


{-| Custom config, including arbitrary options. See [`Events`](#Draggable-Events).

    config =
        customConfig
            [ onDragBy OnDragBy
            , onDragStart OnDragStart
            , onDragEnd OnDragEnd
            ]

-}
customConfig : List (Event a msg) -> Config a msg
customConfig events =
    Config <| List.foldl (<|) Internal.defaultConfig events
