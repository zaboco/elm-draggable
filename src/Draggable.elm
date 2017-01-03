module Draggable
    exposing
        ( State
        , Msg
        , Delta
        , Config
        , Event
        , basicConfig
        , customConfig
        , mouseTrigger
        , init
        , update
        , subscriptions
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
@docs update, subscriptions

# DOM trigger
@docs mouseTrigger

# Definitions
@docs Delta, State, Msg, Config, Event
-}

import Cmd.Extra
import Internal
import Json.Decode
import Mouse exposing (Position)
import VirtualDom


{-| A type alias representing the distance between two drag points.
-}
type alias Delta =
    ( Float, Float )


{-| Drag state to be included in model.
-}
type State
    = State Internal.State


{-| A message type for updating the internal drag state.
-}
type Msg
    = Msg Internal.Msg


{-| An event declaration for the draggable config
-}
type alias Event msg =
    Internal.Event msg


{-| Initial drag state
-}
init : State
init =
    State Internal.NotDragging


{-| Handle update messages for the draggable model. It assumes that the drag state will be stored under the key `drag`.
-}
update :
    Config msg
    -> Msg
    -> { m | drag : State }
    -> ( { m | drag : State }, Cmd msg )
update config msg model =
    let
        ( dragState, dragCmd ) =
            updateDraggable config msg model.drag
    in
        { model | drag = dragState } ! [ dragCmd ]


updateDraggable : Config msg -> Msg -> State -> ( State, Cmd msg )
updateDraggable (Config config) (Msg msg) (State drag) =
    let
        ( newDrag, newMsgMaybe ) =
            Internal.updateAndEmit config msg drag
    in
        ( State newDrag, Cmd.Extra.optionalMessage newMsgMaybe )


{-| Handle mouse subscriptions used for dragging
-}
subscriptions : (Msg -> msg) -> State -> Sub msg
subscriptions envelope (State drag) =
    case drag of
        Internal.NotDragging ->
            Sub.none

        _ ->
            [ Mouse.moves Internal.DragAt, Mouse.ups (\_ -> Internal.StopDragging) ]
                |> Sub.batch
                |> Sub.map (envelope << Msg)


{-| DOM event handler to start dragging on mouse down. It requires a `String` key for the element, in order to provide support for multiple drag targets sharing the same drag state. Of course, if only one element is draggable, it can have any value, including `""`.

    div [ mouseTrigger "element-id" DragMsg ] [ text "Drag me" ]
-}
mouseTrigger : String -> (Msg -> msg) -> VirtualDom.Property msg
mouseTrigger key envelope =
    let
        ignoreDefaults =
            VirtualDom.Options True True
    in
        VirtualDom.onWithOptions "mousedown"
            ignoreDefaults
            (whenLeftMouseButtonPressed <|
                Json.Decode.map (envelope << Msg << Internal.StartDragging key) Mouse.position
            )


whenLeftMouseButtonPressed : Json.Decode.Decoder a -> Json.Decode.Decoder a
whenLeftMouseButtonPressed decoder =
    Json.Decode.field "button" Json.Decode.int
        |> Json.Decode.andThen
            (\button ->
                case button of
                    -- https://www.w3.org/TR/DOM-Level-2-Events/events.html#Events-MouseEvent
                    -- 0 indicates the primary (usually left) mouse button
                    0 ->
                        decoder

                    _ ->
                        Json.Decode.fail "Event is only relevant when the main mouse button was pressed."
            )



-- CONFIG


{-| Configuration of a draggable model.
-}
type Config msg
    = Config (Internal.Config msg)


{-| Basic config

    config = basicConfig OnDragBy
-}
basicConfig : (Delta -> msg) -> Config msg
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
customConfig : List (Event msg) -> Config msg
customConfig events =
    Config <| List.foldl (<|) Internal.defaultConfig events
