module Draggable
    exposing
        ( State
        , Delta
        , DragEvent(..)
        , mouseTrigger
        , customMouseTrigger
        , init
        , subscriptions
        , basicSubscriptions
        )

{-|
This library provides and easy way to make DOM elements (Html or Svg) draggable.

## When is dragging considered?
An element is considered to be dragging when the mouse is pressed **and** moved before it is released. Otherwise, the action is considered a click. This is useful because in some cases you may want to support both actions.

[See examples](https://github.com/zaboco/elm-draggable/tree/master/examples)


# Initial State
@docs init


# Update
@docs subscriptions, basicSubscriptions

# DOM trigger
@docs mouseTrigger, customMouseTrigger

# Definitions
@docs Delta, State, DragEvent
-}

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
    = State (InternalState a)


{-| Events triggered while dragging.
-}
type DragEvent
    = DragStart
    | DragBy Delta
    | DragEnd
    | Click


type InternalState a
    = NotDragging
    | DraggingTentative a Position
    | Dragging Position


{-| Initial drag state.
-}
init : State a
init =
    State NotDragging


{-| Mouse subscriptions used to update the current drag state, as well
    as to handle the [`DragEvent`s](#DragEvent). If no events other than
    `DragBy` are needed, [`basicSubscriptions`](#basicSubscriptions)
    should be used instead.
-}
subscriptions : (State a -> DragEvent -> msg) -> State a -> Sub msg
subscriptions dragHandler (State drag) =
    Sub.batch
        [ handleMoves dragHandler drag
        , handleMouseups dragHandler drag
        ]


{-| Mouse subscriptions used to update the current drag state, as well
    as to change state according to the last drag delta. If other events
    related to dragging are needed, [`subscriptions`](#subscriptions)
    should be used instead.
-}
basicSubscriptions : (State a -> Delta -> msg) -> State a -> Sub msg
basicSubscriptions moveHandler =
    let
        dragHandler drag event =
            case event of
                DragBy delta ->
                    moveHandler drag delta

                _ ->
                    moveHandler drag ( 0, 0 )
    in
        subscriptions dragHandler


handleMoves : (State a -> DragEvent -> msg) -> InternalState a -> Sub msg
handleMoves moveHandler drag =
    case drag of
        Dragging oldPosition ->
            Mouse.moves
                (\newPosition ->
                    moveHandler
                        (State <| Dragging newPosition)
                        (DragBy <| distanceTo newPosition oldPosition)
                )

        NotDragging ->
            Sub.none

        DraggingTentative _ oldPosition ->
            Mouse.moves (\_ -> moveHandler (State <| Dragging oldPosition) DragStart)


distanceTo : Position -> Position -> Delta
distanceTo end start =
    ( toFloat (end.x - start.x)
    , toFloat (end.y - start.y)
    )


handleMouseups : (State a -> DragEvent -> msg) -> InternalState a -> Sub msg
handleMouseups moveHandler drag =
    case drag of
        NotDragging ->
            Sub.none

        DraggingTentative _ _ ->
            Mouse.ups (\_ -> moveHandler (State NotDragging) Click)

        Dragging _ ->
            Mouse.ups (\_ -> moveHandler (State NotDragging) DragEnd)


{-| DOM event handler to start dragging on mouse down. It requires a key for the element, in order to provide support for multiple drag targets sharing the same drag state. Of course, if only one element is draggable, it can have any value, including `()`.

    div [ mouseTrigger "element-id" StartDrag ] [ text "Drag me" ]
-}
mouseTrigger : a -> (State a -> msg) -> VirtualDom.Property msg
mouseTrigger key stateHandler =
    VirtualDom.onWithOptions "mousedown"
        ignoreDefaults
        (Decode.map stateHandler (positionDecoder key))


{-| DOM event handler to start dragging on mouse down and also sending custom information about the `mousedown` event. It does so by using a custom `Decoder` for the [`MouseEvent`](https://developer.mozilla.org/en-US/docs/Web/API/MouseEvent).

    div [ customMouseTrigger offsetDecoder StartDrag ] [ text "Drag me" ]
-}
customMouseTrigger : Decoder a -> (State () -> a -> msg) -> VirtualDom.Property msg
customMouseTrigger customDecoder customStateHandler =
    VirtualDom.onWithOptions "mousedown"
        ignoreDefaults
        (Decode.map2 customStateHandler (positionDecoder ()) customDecoder)


positionDecoder : a -> Decoder (State a)
positionDecoder key =
    Mouse.position
        |> Decode.map (State << DraggingTentative key)
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
