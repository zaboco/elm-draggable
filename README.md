# elm-draggable
An easy way to make DOM elements draggable

[![elm version](https://img.shields.io/badge/elm-v0.18-blue.svg?style=flat-square)](http://elm-lang.org)
[![Build Status](https://travis-ci.org/zaboco/elm-draggable.svg?branch=master)](https://travis-ci.org/zaboco/elm-draggable)

## Install
Have [elm installed](https://guide.elm-lang.org/install.html).

```sh
elm package install --yes zaboco/elm-draggable
```

## Live examples
- [Basic](https://zaboco.github.io/elm-draggable/basic.html) / [Code](https://github.com/zaboco/elm-draggable/blob/master/examples/BasicExample.elm)
- [Custom events](https://zaboco.github.io/elm-draggable/custom.html) / [Code](https://github.com/zaboco/elm-draggable/blob/master/examples/CustomEventsExample.elm)
- [Constraints - restrict dragging to one axis at a time](https://zaboco.github.io/elm-draggable/constraints.html) / [Code](https://github.com/zaboco/elm-draggable/blob/master/examples/ConstraintsExample.elm)
- [Pan & Zoom - drag to pan & scroll to zoom](https://zaboco.github.io/elm-draggable/pan-and-zoom.html) / [Code](https://github.com/zaboco/elm-draggable/blob/master/examples/PanAndZoomExample.elm)
- [Multiple Targets](https://zaboco.github.io/elm-draggable/multiple.html) / [Code](https://github.com/zaboco/elm-draggable/blob/master/examples/MultipleTargetsExample.elm)

## Usage

This library is meant to be easy to use, by keeping its internal details hidden and only communicating to the parent application by emitting [`Event` messages](http://faq.elm-community.org/#how-do-i-generate-a-new-message-as-a-command). So, each time the internals change and something relevant happens (such as "started dragging", "dragged at", etc.), a new message is sent as a `Cmd` and handled in the main `update` function. To better understand how this works, see the snippets below and also the [working examples](https://github.com/zaboco/elm-draggable/blob/master/examples/).

### Basic

In order to make a DOM element draggable, you'll need to:

#### 1. Import this library
```elm
import Draggable
```

#### 2. Define your model
Include:
- The element's position.
- The internal `Drag` state. Note that, for simplicity, the model entry holding this state **must** be called `drag`, since the update function below follows this naming convention. A future update could allow using custom field names. Please note that for the sake of example, we are specifying `String` as the type to tag draggable elements with. If you have only one such element, `()` might be a better type.
```elm
type alias Model =
    { position : ( Int, Int )
    , drag : Draggable.State String
    }
```

#### 3. Initialize the `Drag` state and the element's position
```elm
initModel : Model
initModel =
    { position = ( 0, 0 )
    , drag = Draggable.init
    }
```

#### 4. Define the message types that will be handled by your application
- `OnDragBy` is for actually updating the position, taking a `Draggable.Delta` as an argument. `Delta` is just an alias for a tuple of `(Float, Float)` and it represents the distance between two consecutive drag points.
- `DragMsg` is for handling internal `Drag` state updates.
```elm
type Msg
    = OnDragBy Draggable.Delta
    | DragMsg (Draggable.Msg String)
```

#### 5. Setup the config used when updating the `Drag` state
For the simplest case, you only have to provide a handler for `onDragBy`:
```elm
dragConfig : Draggable.Config String Msg
dragConfig =
    Draggable.basicConfig OnDragBy
```

#### 6. Your update function must handle the messages declared above
- For `OnDragBy`, which will be emitted when the user drags the element, the new position will be computed using the `Delta` `(dx, dy)`
- `DragMsg` will be forwarded to `Draggable.update` which takes care of both updating the `Drag` state and sending the appropriate event commands. In order to do that, it receives the `dragConfig`. As mentioned above, this function assumes that the model has a `drag` field holding the internal `Drag` state.
```elm
update : Msg -> Model -> ( Model, Cmd Msg )
update msg ({ position } as model) =
    case msg of
        OnDragBy ( dx, dy ) ->
            let
                ( x, y ) =
                    position
            in
                { model | position = ( x + dx, y + dy ) } ! []

        DragMsg dragMsg ->
            Draggable.update dragConfig dragMsg model
```

#### 7. In order to keep track of the mouse events, you must include the relevant subscriptions
```elm
subscriptions : Model -> Sub Msg
subscriptions { drag } =
    Draggable.subscriptions DragMsg drag
```

#### 8. Triggering drag
Inside your `view` function, you must somehow make the element draggable. You do that by adding a trigger for the `mousedown` event. You must also specify a `key` for that element. This can be useful when there are multiple drag targets in the same view.

Of course, you'll also have to style your DOM element such that it reflects its moving position (with `top: x; left: y` or [`transform: translate`](http://www.w3schools.com/css/css3_2dtransforms.asp))
```elm
view : Model -> Html Msg
view { position } =
    Html.div
        [ Draggable.mouseTrigger "my-element" DragMsg
        -- , Html.Attributes.style (someStyleThatSetsPosition position)
        ]
        [ Html.text "Drag me" ]
```

For working demos, see the [basic example](https://github.com/zaboco/elm-draggable/blob/master/examples/BasicExample.elm) or the [examples with multiple targets](https://github.com/zaboco/elm-draggable/blob/master/examples/MultipleTargetsExample.elm)

#### 9. Triggering on touch
If you want to trigger drags on touch events (i.e. on mobile platforms) as well
as mouse events, you need to add `touchTriggers` to your elements. Building on
the previous example, it looks like this.

```elm
view : Model -> Html Msg
view { position } =
    Html.div
        [ Draggable.mouseTrigger "my-element" DragMsg
        -- , Html.Attributes.style (someStyleThatSetsPosition position)
        ] ++ (Draggable.touchTriggers "my-element" DragMsg)
        [ Html.text "Drag me" ]
```

The
[basic example](https://github.com/zaboco/elm-draggable/blob/master/examples/BasicExample.elm) demonstrates
this as well.

### Advanced

#### Custom config
Besides tracking the mouse moves, this library can also track all the other associated events related to dragging. But, before enumerating these events, it's import to note that an element is not considered to be dragging if the mouse was simply clicked (without moving). That allows tracking both `click` and `drag` events:
- "mouse down" + "mouse up" = "click"
- "mouse down" + "mouse moves" + "mouse up" = "drag"

So, the mouse events are:
- `onMouseDown` - on mouse press.
- `onDragStart` - on the first mouse move after pressing.
- `onDragBy` - on every mouse move.
- `onDragEnd` - on releasing the mouse after dragging.
- `onClick` - on releasing the mouse without dragging.

All of these events are optional, and can be provided to `Draggable.customConfig` using an API similar to the one used by `VirtualDom.node` to specify the `Attribute`s. For example, if we want to handle all the events, we define the `config` like:
```elm
import Draggable
import Draggable.Events exposing (onClick, onDragBy, onDragEnd, onDragStart, onMouseDown)

dragConfig : Draggable.Config String Msg
dragConfig =
    Draggable.customConfig
        [ onDragStart OnDragStart
        , onDragEnd OnDragEnd
        , onDragBy OnDragBy
        , onClick CountClick
        , onMouseDown (SetClicked True)
        ]
```

__Note__: If we need to handle `mouseup` after either a `drag` or a `click`, we can use the `DOM` event handler `onMouseUp` from `Html.Events` or `Svg.Events`.

See [the full example](https://github.com/zaboco/elm-draggable/blob/master/examples/CustomEventsExample.elm)

#### Custom Delta
By default, `OnDragBy` message will have a `Draggable.Delta` parameter, which, as we saw, is just an alias for `(Float, Float)`. However, there are situations when we would like some other data type for representing our `delta`.

Luckily, that's pretty easy using function composition. For example, we can use a [Vec2](http://package.elm-lang.org/packages/elm-community/linear-algebra/1.0.0/Math-Vector2#Vec2) type from the `linear-algebra` library, which provides handy function like `translate`, `scale` and `negate`. And there is even a [simple way of converting our "floats" delta to a `Vec2`](http://package.elm-lang.org/packages/elm-community/linear-algebra/1.0.0/Math-Vector2#fromTuple)

```elm
import Math.Vector2 as Vector2 exposing (Vec2)

type Msg
    = OnDragBy Vec2
--  | ...

dragConfig : Draggable.Config Msg
dragConfig =
    Draggable.basicConfig (OnDragBy << Vector2.fromTuple)
```

There is actually [an example right for this use-case](https://github.com/zaboco/elm-draggable/blob/master/examples/PanAndZoomExample.elm)

#### Custom mouse trigger
There are cases when we need some additional information (e.g. mouse offset) about the `mousedown` event which triggers the drag. For these cases, there is an advanced `customMouseTrigger` which also takes a JSON `Decoder` for the [`MouseEvent`](https://developer.mozilla.org/en-US/docs/Web/API/MouseEvent).

```elm
import Json.Decode as Decode exposing (Decoder)

type Msg
    = CustomMouseDown Draggable.Msg (Float, Float)
--  | ...

update msg model =
    case msg of
        CustomMouseDown dragMsg startPoint ->
            { model | startPoint = startPoint }
                |> Draggable.update dragConfig dragMsg

view { scene } =
    Svg.svg
        [ Draggable.customMouseTrigger mouseOffsetDecoder CustomMouseDown
--      , ...
        ]
        []

mouseOffsetDecoder : Decoder (Float, Float)
mouseOffsetDecoder =
    Decode.map2 (,)
        (Decode.field "offsetX" Decode.float)
        (Decode.field "offsetY" Decode.float)
```
[Full example](https://github.com/zaboco/elm-draggable/blob/master/examples/FreeDrawingExample.elm)
