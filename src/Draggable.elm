module Draggable
    exposing
        ( State
        , Delta
        , DragEvent(..)
        , newMouseTrigger
        , newCustomMouseTrigger
        , init
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


# Update
@docs newSubscription, basicSubscription

# DOM trigger
@docs newMouseTrigger, newCustomMouseTrigger

# Definitions
@docs Delta, State, DragEvent
-}

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


{-| Handle mouse subscriptions used for dragging
-}
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
newMouseTrigger : a -> (State a -> msg) -> VirtualDom.Property msg
newMouseTrigger key stateHandler =
    VirtualDom.onWithOptions "mousedown"
        ignoreDefaults
        (Decode.map stateHandler (newPositionDecoder key))


{-| DOM event handler to start dragging on mouse down and also sending custom information about the `mousedown` event. It does so by using a custom `Decoder` for the [`MouseEvent`](https://developer.mozilla.org/en-US/docs/Web/API/MouseEvent).

    div [ mouseTrigger offsetDecoder CustomDragMsg ] [ text "Drag me" ]
-}
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
