module Draggable
    exposing
        ( State
        , Msg
        , Delta
        , Config
        , basicConfig
        , customConfig
        , deltaToPosition
        , onDragStart
        , onDragBy
        , onDragEnd
        , onClick
        , onMouseDown
        , onMouseUp
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

# Config Modifiers
Optional listeners for the various events involved in dragging (`onDragBy`, `onDragStart`, etc.). It can also handle `click` events when the mouse was not moved.
@docs onDragStart, onDragEnd, onDragBy
@docs onClick, onMouseDown, onMouseUp

# Helpers
@docs deltaToPosition

# Definitions
@docs Delta, State, Msg, Config
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


{-| Converts a `Delta` to a `Mouse.Position`. Can be used to change the argument to `DragBy` messages:

    dragConfig =
        Draggable.basicConfig (OnDragBy << Draggable.deltaToPosition)

See [BasicExample](https://github.com/zaboco/elm-draggable/blob/master/examples/BasicExample.elm)
-}
deltaToPosition : Delta -> Position
deltaToPosition ( dx, dy ) =
    Position (round dx) (round dy)



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
    defaultConfig
        |> onDragBy onDragByListener


{-| Custom config, including arbitrary options. See below the available `Modifiers`.

    config = customConfig
        [ onDragBy OnDragBy
        , onDragStart OnDragStart
        , onDragEnd OnDragEnd
        ]
-}
customConfig : List (Config msg -> Config msg) -> Config msg
customConfig modifiers =
    List.foldl (<|) defaultConfig modifiers


{-| Register a `DragStart` event listener. It will not trigger if the mouse has not moved while it was pressed.
-}
onDragStart : msg -> Config msg -> Config msg
onDragStart toMsg (Config config) =
    Config { config | onDragStart = Just toMsg }


{-| Register a `DragEnd` event listener. It will not trigger if the mouse has not moved while it was pressed.
-}
onDragEnd : msg -> Config msg -> Config msg
onDragEnd toMsg (Config config) =
    Config { config | onDragEnd = Just toMsg }


{-| Register a `DragBy` event listener. It will trigger every time the mouse is moved. The sent message will contain a `Delta`, which is the distance between the current position and the previous one.

**Note** The delta values are `Float`, so the code bellow assumes that the `point` is of type `{ x: Float, y: Float }`. If you want to use a `Mouse.Position` instead (which has `Int` coordinates), you might want to convert the `Delta` to a `Position`, using [`deltaToPosition`](#deltaToPosition)

    case Msg of
        OnDragBy (dx, dy) ->
            { model | point = { x = point.x + dx, y = point.y + dy } }
-}
onDragBy : (Delta -> msg) -> Config msg -> Config msg
onDragBy toMsg (Config config) =
    Config { config | onDragBy = Just << toMsg }


{-| Register a `Click` event listener. It will trigger if the mouse is pressed and immediately release, without any move.
-}
onClick : msg -> Config msg -> Config msg
onClick toMsg (Config config) =
    Config { config | onClick = Just toMsg }


{-| Register a `MouseDown` event listener. It will trigger whenever the mouse is pressed.
-}
onMouseDown : msg -> Config msg -> Config msg
onMouseDown toMsg (Config config) =
    Config { config | onMouseDown = Just toMsg }


{-| Register a `MouseUp` event listener. It will trigger whenever the mouse is released.
-}
onMouseUp : msg -> Config msg -> Config msg
onMouseUp toMsg (Config config) =
    Config { config | onMouseUp = Just toMsg }


defaultConfig : Config msg
defaultConfig =
    Config Internal.defaultConfig
