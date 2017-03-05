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
- [Pan & Zoom - drag to pan & scroll to zoom](https://zaboco.github.io/elm-draggable/pan-and-zoom.html) / [Code](https://github.com/zaboco/elm-draggable/blob/master/examples/PanAndZoomExample.elm)
- [Free drawing - using custom Decoder to get the mouse position](https://github.com/zaboco/elm-draggable/blob/master/examples/FreeDrawingExample.elm) / [Code](https://github.com/zaboco/elm-draggable/blob/master/examples/FreeDrawingExample.elm)
- [Multiple Targets - sharing the same drag state](https://zaboco.github.io/elm-draggable/multiple.html) / [Code](https://github.com/zaboco/elm-draggable/blob/master/examples/MultipleTargetsExample.elm)
- [Constraints - restrict dragging to one axis at a time](https://zaboco.github.io/elm-draggable/constraints.html) / [Code](https://github.com/zaboco/elm-draggable/blob/master/examples/ConstraintsExample.elm)


## Usage

This library is meant to be easy to use, by keeping its internal details hidden and only communicating to the parent application by sending the drag `Delta`. Or, for more advanced use-cases, by emitting `DragEvent`s: each time the internals change and something relevant happens (such as "started dragging", "dragged at", etc.), an event is sent from the `eventSubscriptions`. To better understand how this works, see the snippets below and also the [working examples](https://github.com/zaboco/elm-draggable/blob/master/examples/).

### Basic

In order to make a DOM element draggable, you'll need to:

#### 1. Import this library
```elm
import Draggable
```

#### 2. Define your model
Include:
- The element's position.
- The internal `Drag` state.
```elm
type alias Model =
    { position : ( Int, Int )
    , drag : Draggable.State
    }
```

#### 3. Initialize the `Drag` state and the element's position
```elm
model : Model
model =
    { position = ( 0, 0 )
    , drag = Draggable.init
    }
```

#### 4. Define the message types that will be handled by your application
- `TriggerDrag` updates the `Drag` state when the mouse is pressed down.
- `UpdateDragBy` updates the `Drag` state whenever some mouse event is received from `subscriptions`. It is also used for actually updating the position, taking a `Draggable.Delta` as an argument. `Delta` is just an alias for a tuple of `(Float, Float)` and it represents the distance between two consecutive drag points.
```elm
type Msg
    = TriggerDrag Draggable.State
    | UpdateDragBy Draggable.State Draggable.Delta
```


#### 6. Your update function must handle the messages declared above
- For `TriggerDrag`, which will be emitted when the user presses the mouse down on the element, all that is needed is to set the `drag` field.
- `UpdateDragBy` must update the `drag` field, and also use the received `Delta` to compute the new position.
```elm
update : Msg -> Model -> Model
update msg ({ position } as model) =
    case msg of
        TriggerDrag drag ->
            { model | drag = drag }

        UpdateDragBy drag ( dx, dy ) ->
            let
                ( x, y ) =
                    position
            in
                { model | drag = drag, position = ( x + dx, y + dy ) }
```

#### 7. In order to keep track of the mouse events, you must include the relevant subscriptions
```elm
subscriptions : Model -> Sub Msg
subscriptions { drag } =
    Draggable.subscriptions UpdateDragBy drag
```

#### 8. Triggering drag
Finally, inside your `view` function, you must somehow make the element draggable. You do that by adding a trigger for the `mousedown` event.

Of course, you'll also have to style your DOM element such that it reflects its moving position (with `top: x; left: y` or [`transform: translate`](http://www.w3schools.com/css/css3_2dtransforms.asp))
```elm
view : Model -> Html Msg
view { position } =
    Html.div
        [ Draggable.mouseTrigger TriggerDrag
        -- , Html.Attributes.style (someStyleThatSetsPosition position)
        ]
        [ Html.text "Drag me" ]
```

For a working demo, see the [basic example](https://github.com/zaboco/elm-draggable/blob/master/examples/BasicExample.elm).

### Advanced

#### Handling drag events
Besides tracking the mouse moves, this library can also track all the other events related to dragging. But, before enumerating these events, it's important to note that an element is not considered to be dragging if the mouse was simply clicked (without moving). That allows tracking both `click` and `drag` events:
- "mouse down" + "mouse up" = "click"
- "mouse down" + "mouse moves" + "mouse up" = "drag"

So, the `DragEvent`s are:
- `DragStart` - on the first mouse move after pressing.
- `DragBy` - on every mouse move.
- `DragEnd` - on releasing the mouse after dragging.
- `Click` - on releasing the mouse without dragging.

In order to handle one or more of these events, `eventSubscriptions` needs to be used instead of `subscriptions`.
```elm
import Draggable exposing (DragEvent(..))


type Msg
    = TriggerDrag Draggable.State
    | UpdateDrag Draggable.State DragEvent


update : Msg -> Model -> Model
update msg model =
    case msg of
        TriggerDrag drag ->
            { model | drag = drag, isMousePressed = True }

        UpdateDrag drag event ->
            { model | drag = drag }
                |> updateOnDrag event


updateOnDrag : DragEvent -> Model -> Model
updateOnDrag dragEvent model =
    case dragEvent of
        DragBy delta ->
            moveBy delta model

        DragStart ->
            startDragging model

        DragEnd ->
            stopDragging model

        Click ->
            recordClick model
```

__Note__: If we need to handle `mouseup` after either a `drag` or a `click`, we can use the `DOM` event handler `onMouseUp` from `Html.Events` or `Svg.Events`. Be aware though that the `Msg` received from `onMouseUp` is handled before `DragEnd` or `Click`.

See [the example featuring all events](https://github.com/zaboco/elm-draggable/blob/master/examples/CustomEventsExample.elm).


#### Custom Delta
By default, `UpdateDragBy` message (or `DragBy` event when using `eventSubscriptions`) will have a `Draggable.Delta` parameter, which, as we saw, is just an alias for `(Float, Float)`. However, there are situations when we would like some other data type for representing our `delta`.

Luckily, that's pretty easy using data mappers. For example, we can use a [Vec2](http://package.elm-lang.org/packages/elm-community/linear-algebra/1.0.0/Math-Vector2#Vec2) type from the `linear-algebra` library, which provides handy function like `translate`, `scale` and `negate`. And there is even a [simple way of converting our "floats" delta to a `Vec2`](http://package.elm-lang.org/packages/elm-community/linear-algebra/1.0.0/Math-Vector2#fromTuple)

```elm
import Math.Vector2 as Vector2

update : Msg -> Model -> Model
update msg ({ center } as model) =
    case msg of
        UpdateDragBy drag deltaTuple ->
            let
                delta =
                    Vector2.fromTuple deltaTuple

            in
                { model | drag = drag, center = center |> Vector2.add delta }
    --  ...
```

There is actually [an example right for this use-case](https://github.com/zaboco/elm-draggable/blob/master/examples/PanAndZoomExample.elm).

#### Custom mouse trigger
There are cases when we need some additional information (e.g. mouse offset) about the `mousedown` event which triggers the drag. For these cases, there is an advanced `customMouseTrigger` which also takes a JSON `Decoder` for the [`MouseEvent`](https://developer.mozilla.org/en-US/docs/Web/API/MouseEvent).

```elm
import Json.Decode as Decode exposing (Decoder)


type Msg
    = TriggerDrag Draggable.State (Float, Float)
--  | ...

update msg model =
    case msg of
        TriggerDrag drag startPoint ->
            { model | drag = drag, startPoint = startPoint }

view model =
    Svg.svg
        [ Draggable.customMouseTrigger mouseOffsetDecoder TriggerDrag
--      , ...
        ]
        []

mouseOffsetDecoder : Decoder (Float, Float)
mouseOffsetDecoder =
    Decode.map2 (,)
        (Decode.field "offsetX" Decode.float)
        (Decode.field "offsetY" Decode.float)
```
[Full example](https://github.com/zaboco/elm-draggable/blob/master/examples/FreeDrawingExample.elm).


#### Multiple Targets
Sometimes there are more elements that can be dragged. A naive approach to implement that would be to have multiple drag `subscriptions` and multiple drag `State`s in our `Model`. A better alternative is to share the same drag `State`, since there can only be one element dragging at a time anyway.

That can be acomplished by assiging some sort of `key` to each target and then partially apply that `key` to the message sent by `mouseTrigger`/`customMouseTrigger`:


```elm
type Msg
    = TriggerDrag Key Draggable.State
--  | ...

update msg model =
    case msg of
        TriggerDrag key drag ->
            { model | drag = drag, activeKey = key }
    --  ...

view model =
        Svg.rect
            [ Draggable.mouseTrigger (TriggerDrag key)
        --  , ...
            ]
```
[Full example](https://github.com/zaboco/elm-draggable/blob/master/examples/MultipleTargetsExample.elm).
