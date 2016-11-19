module Draggable
    exposing
        ( State
        , Msg
        , Delta
        , Config
        , Event
        , basicConfig
        , customConfig
        , deltaToFloats
        , triggerOnMouseDown
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
@docs triggerOnMouseDown

# Helpers
@docs deltaToFloats

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
    ( Int, Int )


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
        ( newDrag, newMsgs ) =
            Internal.updateAndEmit config msg drag
    in
        ( State newDrag, Cmd.Extra.multiMessage newMsgs )


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


{-| DOM event handler to start dragging on mouse down.

    div [ triggerOnMouseDown DragMsg ] [ text "Drag me" ]
-}
triggerOnMouseDown : (Msg -> msg) -> VirtualDom.Property msg
triggerOnMouseDown envelope =
    let
        ignoreDefaults =
            VirtualDom.Options True True
    in
        VirtualDom.onWithOptions "mousedown"
            ignoreDefaults
            (Json.Decode.map (envelope << Msg << Internal.StartDragging) Mouse.position)



-- HELPERS


{-| Converts a `Delta` to a tuple of `Float`s. Can be used to change the argument to `DragBy` messages, when float operations are needed:

    dragConfig =
        Draggable.basicConfig (OnDragBy << Draggable.deltaToFloats)

A use case for that could be converting the `Delta` to a `Vector` type (e.g. [`Math.Vector2.Vec2` from `linear-algebra`][vec2])

    dragConfig =
        Draggable.basicConfig (OnDragBy << Vector2.fromTuple << Draggable.deltaToFloats)

See [PanAndZoomExample](https://github.com/zaboco/elm-draggable/blob/master/examples/PanAndZoomExample.elm)

[vec2]: http://package.elm-lang.org/packages/elm-community/linear-algebra/1.0.0/Math-Vector2#Vec2
-}
deltaToFloats : Delta -> ( Float, Float )
deltaToFloats ( dx, dy ) =
    ( toFloat dx, toFloat dy )



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
