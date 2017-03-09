### 4.0.0 Simplified API
This release keeps the same functionality as before, it just changes how the events are passed to the parent application.


#### State handling using only subscriptions

It seems that for this library to work, there was no need for a fullblown **TEA**, with `update` and own `Msg`s. All that was needed could have been achieved by only using `subscriptions`, while the parent application is responsible for storing the state in its `Model`. So, `update` and `Msg` were removed. Instead, the subscriptions would return a parent `msg` containing the new drag state.

Also, now that `update` was removed, there needed to be another way to send the `Event`s (like `dragStart`, etc.). The solution for that was simple, the parent `msg` would also pass along a `DragEvent`, which the library now exposes as a `type` (along with its type constructors). With this change, everything related to config was removed, including the `Event` type and the `Draggable.Events` module.


That led to other simplifications:
- parent model is not required to contain a field called `drag` anymore.
- no `Cmd`s are involved anymore, so the parent update can be simplified if not using other `Cmd`s.
- no `key` is stored in the state anymore, one can be stored on the parent model on `mouseTrigger`.

#### Migration path:

##### 1. Update imports
```diff
-import Draggable.Events exposing (onClick, onDragBy, onDragEnd, onDragStart)

-import Draggable
+import Draggable exposing (DragEvent(..))
```

##### 2. Remove the `Msg`s related to event handling
```diff
type Msg
-    = OnDragBy Draggable.Delta
-    | OnDragStart
-    | OnDragEnd
-    | CountClick
-    | SetClicked Bool
-    | DragMsg (Draggable.Msg String)
+    = TriggerDrag Draggable.State
+    | UpdateDrag Draggable.State DragEvent
```
Only these two `Msg`s will be needed to handle dragging:
  - `TriggerDrag` - to pass the initial drag state when pressing the mouse down.
  - `UpdateDrag` - to pass the updated drag state and the `DragEvent` resulted from subscribing to the other mouse actions.

##### 3. Extract the update logic related to dragging
Tipically, your `update` logic will be split into:
- top-level `update`, handling application messages, including triggering and updating drag `State`. Also, when triggering the drag, any other change to the state can be done (like setting `isSelected` below). So it also takes the role of `onMouseDown` from the previous versions.
```elm
update : Msg -> Model -> Model
update msg model =
    case msg of
        TriggerDrag drag ->
            { model | drag = drag, isSelected = True }

        UpdateDrag drag event ->
            { model | drag = drag }
                |> updateOnDrag event
```
- drag-related `update`, handling the `DragEvent`s that the application is interested in. The other events can simply be ignored by adding a default branch: `_ -> model`.
```elm
updateOnDrag : DragEvent -> Model -> Model
updateOnDrag dragEvent ({ xy } as model) =
    case dragEvent of
        DragBy ( dx, dy ) ->
            { model | xy = Position (xy.x + dx) (xy.y + dy) }

        DragStart ->
            { model | isDragging = True }

        DragEnd ->
            { model | isDragging = False }

        Click ->
            { model | clicksCount = model.clicksCount + 1 }
```

##### 4. Setup subscriptions
The new function is called `eventSubscriptions` because there is another one called `subscriptions` which is simpler, see below for details.
```diff
 subscriptions : Model -> Sub Msg
 subscriptions { drag } =
-    Draggable.subscriptions DragMsg drag
+    Draggable.eventSubscriptions UpdateDrag drag
```

##### 5. Setup mouseTrigger
Not much, just make sure to remove the key parameter, since it is no longer needed.
```diff
-            , Draggable.mouseTrigger "" DragMsg
+            , Draggable.mouseTrigger TriggerDrag
```


#### Special cases

##### Basic subscriptions
In case you are not interested in tracking any event other than dragging, you can use the simplified `subscriptions`:

```elm
type Msg
    = TriggerDrag Draggable.State
    | UpdateDragBy Draggable.State Draggable.Delta

update : Msg -> Model -> Model
update msg ({ xy } as model) =
    case msg of
        TriggerDrag drag ->
            { model | drag = drag }

        UpdateDragBy drag ( dx, dy ) ->
            { model | drag = drag, xy = Position (xy.x + dx) (xy.y + dy) }

subscriptions : Model -> Sub Msg
subscriptions { drag } =
    Draggable.subscriptions UpdateDragBy drag
```

Note that `UpdateDragBy` is called for all events, so sometimes the delta will be `(0, 0)`.

##### Multiple targets
Since the key is no longer part of the drag `State`, the parent app is responsible for keeping it. That can be done by partially applying the clicked element's `key` to the message sent by `mouseTrigger`:
```elm
itemView { id } =
    Svg.rect [ Draggable.mouseTrigger (TriggerDrag id) ] []
```

Then, in the main `update` function you can do:
```elm
case msg of
    TriggerDrag id drag ->
        { model | drag = drag } |> setActiveId id
```

**NOTE** A side effect of removing the `key` from the state is that you can't rely on `Html.Events.onMouseUp` to reset the `activeId`. That's because this event is triggered before `DragEnd` or `Click` are, so if the user clicks the element, the `activeId` is reset before having the chance to handle `Click` `DragEvent`.

The solution is to have a function `resetActiveId` and call it both on `DragEnd` and `Click` branches in `updateOnDrag`:
```elm
case dragEvent of
    Click ->
        model |> handleClick |> resetActiveId

    DragEnd ->
        model |> handleDragEnd |> resetActiveId
```
Anyway, there are other cases when you can't relly on `Html.Events.onMouseUp`, such as when [the mouse leaves the target while dragging](https://zaboco.github.io/elm-draggable/constraints.html).

##### Custom decoder for mouse trigger
In version `2.1.0`, a `customMouseTrigger` was added, but because of the arhitecture at that point, it was not so straightforward to use. With this release, this function has a simpler API:
```elm
customMouseTrigger : Decoder a -> (State -> a -> msg) -> VirtualDom.Property msg
```
It is very similar to the signature of `mouseTrigger`, but with a new custom value added.


### 3.0.0 Parameterize the type of the draggable element's `key`
Allow draggable elements to have `key`s of any type, instead of `String`.
Easy to migrate to, just add the type parameter to `State`, `Msg` and `Config`. If the key isn't used, it can have the type `()`:
- `Draggable.State ()`
- `Draggable.Msg ()`
- `Draggable.Config () Msg`

PR: #34

### 2.1.0 Added customMouseTrigger
Get custom information about the mouse position on `mousedown`
```elm
customMouseTrigger : Decoder a -> (Msg -> a -> msg) -> VirtualDom.Property msg
```
PR: #33


### 2.0.0

#### 1. `Delta` now uses floats
This change was made because it seems to be more common to need floats when handling positions:
- in **elm-css** [`px`](http://package.elm-lang.org/packages/rtfeldman/elm-css/7.0.0/Css#px) expects a `Float`
- in **linear-algebra** [`fromTuple`](http://package.elm-lang.org/packages/elm-community/linear-algebra/1.0.0/Math-Vector2#fromTuple) also expects `Float`s

Actual changes:
- changed `Delta` alias to `(Float, Float)`.
- removed `deltaToFloats` - no longer needed. Also, did not feel like a "mirror" `deltaToInts` would have been that useful for the common case.

#### 2. Consolidated `keyed` API
Version **1.1.0** introduced the ability to have multiple drag targets, each identified by its own key. Since it was a minor release, it only added new functions alongside the old ones: `onMouseDownKeyed` as a "keyed" alternative to `onMouseDown` and `mouseTrigger` as a more general `triggerOnMouseDown` (which was deprecated). In this release the old API is updated to handle `key`s by default:
- `triggerOnMouseDown` is removed - `mouseTrigger ""` should be used instead.
- `onMouseDownKeyed` is renamed to `onMouseDown`.
- `onMouseDown` will now get a `Key` - old calls can be replaced with `onMouseDown (\_ -> OnMouseDown)`.
- `onDragStart` and `onClick` will also get a `Key`.

Fixes [#23](https://github.com/zaboco/elm-draggable/issues/23)


#### 3. Removed `onMouseUp`
This event is not actually needed, since it can handled as a regular DOM event. However, `onMouseDown` can't be removed because a DOM element cannot handle two events of the same type: the last one will override the first. So, in the following example `HandleMouseDown` will be handled, but dragging will not work:
```elm
Html.div
    [ Draggable.mouseTrigger "" DragMsg
    , Html.Events.onMouseDown HandleMouseDown
    ]
```

So, the following change is needed to keep `onMouseUp` working:
```diff
  dragConfig =
      Draggable.customConfig
          [ onDragBy HandleDragBy
-         , Draggable.Events.onMouseUp HandleMouseUp
          ]

  view =
      Html.div
          [ Draggable.mouseTrigger "" DragMsg
+         , Html.Events.onMouseUp HandleMouseUp
          ]

```
