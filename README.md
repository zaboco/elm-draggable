# elm-draggable
An easy way to make DOM elements draggable

[![elm version](https://img.shields.io/badge/elm-v0.18-blue.svg?style=flat-square)](http://elm-lang.org)
[![Build Status](https://travis-ci.org/zaboco/elm-draggable.svg?branch=master)](https://travis-ci.org/zaboco/elm-draggable)

## Install
Have [elm installed](https://guide.elm-lang.org/install.html).

```sh
elm package install --yes zaboco/elm-draggable
```

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
- The internal `Drag` state. Note that, for simplicity, the model entry holding this state **must** be called `drag`, since the update function below follows this naming convention. A future update could allow using custom field names.
```elm
type alias Model =
    { position : ( Int, Int )
    , drag : Draggable.State
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
- `OnDragBy` is for actually updating the position, taking a `Draggable.Delta` as an argument. `Delta` is just an alias for a tuple of `(Int, Int)` and it represents the distance between two consecutive drag points.
- `DragMsg` is for handling internal `Drag` state updates.
```elm
type Msg
    = OnDragBy Draggable.Delta
    | DragMsg Draggable.Msg
```

#### 5. Setup the config used when updating the `Drag` state
For the simplest case, you only have to provide a handler for `onDragBy`:
```elm
dragConfig : Draggable.Config Msg
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
Finally, inside your `view` function, you must somehow make the element draggable. You do that by adding a trigger for the `mousedown` event. Of course, you'll also have to style your DOM element such that it reflects its moving position (with `top: x; left: y` or [`transform: translate`](http://www.w3schools.com/css/css3_2dtransforms.asp))
```elm
view : Model -> Html Msg
view { position } =
    Html.div
        [ Draggable.triggerOnMouseDown DragMsg
        -- , Html.Attributes.style (someStyleThatSetsPosition position)
        ]
        [ Html.text "Drag me" ]
```

For a working demo, see the [basic example](https://github.com/zaboco/elm-draggable/blob/master/examples/BasicExample.elm)

### Advanced

#### Custom config
Besides tracking the mouse moves, this library can also track all the other associated events related to dragging. But, before enumerating these events, it's import to note that an element it's not considered to be dragging if the mouse was simply clicked (without moving). That allows tracking both `click` and `drag` events:
- "mouse down" + "mouse up" = "click"
- "mouse down" + "mouse moves" + "mouse up" = "drag"

So, the mouse events are:
- `onMouseDown` - it was pressed.
- `onDragStart` - it was first moved while being pressed.
- `onDragBy` - it was moved while being pressed.
- `onDragEnd` - it was released after dragging.
- `onMouseUp` - it was released, either after dragging or not.
- `onClick` - it was pressed and immediately released, without moving.

All of these events are optional, and can be provided to `Draggable.customConfig` using an API similar to the one used by `VirtualDom.node` to specify the `Attribute`s. For example, if we want to handle all the events, we define the `config` like:
```elm
import Draggable
import Draggable.Events exposing (onClick, onDragBy, onDragEnd, onDragStart, onMouseDown, onMouseUp)

dragConfig : Draggable.Config Msg
dragConfig =
    Draggable.customConfig
        [ onDragStart OnDragStart
        , onDragEnd OnDragEnd
        , onDragBy OnDragBy
        , onClick CountClick
        , onMouseDown (SetClicked True)
        , onMouseUp (SetClicked False)
        ]
```
See [the full example](https://github.com/zaboco/elm-draggable/blob/master/examples/CustomEventsExample.elm)

#### Custom Delta
By default, `OnDragBy` message will have a `Draggable.Delta` parameter, which, as we saw, is just an alias for `(Int, Int)`. However, there are situations when we would like some other data type for representing our `delta`.

Luckily, that's pretty easy using function composition. And the library provides a helper function for a simple (yet useful) transformation: `deltaToFloats`. It just converts the delta to a `(Float, Float)` which can be useful when operations such as scaling are required:

```elm
type Msg
    = OnDragBy ( Float, Float )
--  | ...

dragConfig : Draggable.Config Msg
dragConfig =
    Draggable.basicConfig (OnDragBy << Draggable.deltaToFloats)
```

We can go even further and use a [Vec2](http://package.elm-lang.org/packages/elm-community/linear-algebra/1.0.0/Math-Vector2#Vec2) type from the `linear-algebra` library, which provides handy function like `translate`, `scale` and `negate`. And there is even a [simple way of converting our "floats" delta to a `Vec2`](http://package.elm-lang.org/packages/elm-community/linear-algebra/1.0.0/Math-Vector2#fromTuple)

```elm
import Math.Vector2 as Vector2 exposing (Vec2)

type Msg
    = OnDragBy Vec2
--  | ...

dragConfig : Draggable.Config Msg
dragConfig =
    Draggable.basicConfig (OnDragBy << Vector2.fromTuple << Draggable.deltaToFloats)
```

There is actually [an example right for this use-case](https://github.com/zaboco/elm-draggable/blob/master/examples/PanAndZoomExample.elm)
