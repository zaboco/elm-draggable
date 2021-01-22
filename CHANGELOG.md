### 5.0.0
- `customMouseTrigger` now allows all mouse buttons, not only the left one
- `whenLeftMouseButtonPressed` is now exposed by the module, to allow the old behaviour when using `customMouseTrigger`. It must be applied manually to the custom decoder.
- `customMouseTrigger` now also takes the key as an argument, same as `mouseTrigger`.

#### Migration
```diff
- customMouseTrigger customDecoder CustomMsg
+ customMouseTrigger () (whenLeftMouseButtonPressed customDecoder) CustomMsg
```

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
