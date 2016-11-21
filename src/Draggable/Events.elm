module Draggable.Events
    exposing
        ( onDragStart
        , onDragBy
        , onDragEnd
        , onClick
        , onMouseDown
        , onMouseUp
        )

{-| Listeners for the various events involved in dragging (`onDragBy`, `onDragStart`, etc.). Also handles `click` events when the mouse was not moved.
@docs onDragStart, onDragEnd, onDragBy
@docs onClick, onMouseDown, onMouseUp
-}

import Internal exposing (Config, Delta)
import Draggable exposing (Event)


{-| Register a `DragStart` event listener. It will not trigger if the mouse has not moved while it was pressed.
-}
onDragStart : msg -> Event msg
onDragStart toMsg config =
    { config | onDragStart = Just toMsg }


{-| Register a `DragEnd` event listener. It will not trigger if the mouse has not moved while it was pressed.
-}
onDragEnd : msg -> Event msg
onDragEnd toMsg config =
    { config | onDragEnd = Just toMsg }


{-| Register a `DragBy` event listener. It will trigger every time the mouse is moved. The sent message will contain a `Delta`, which is the distance between the current position and the previous one.

**Note** The delta values are `Float`, so the code bellow assumes that the `point` is of type `{ x: Float, y: Float }`. If you want to use a `Mouse.Position` instead (which has `Int` coordinates), you might want to convert the `Delta` to a `Position`, using [`deltaToPosition`](#deltaToPosition)

    case Msg of
        OnDragBy (dx, dy) ->
            { model | point = { x = point.x + dx, y = point.y + dy } }
-}
onDragBy : (Delta -> msg) -> Event msg
onDragBy toMsg config =
    { config | onDragBy = Just << toMsg }


{-| Register a `Click` event listener. It will trigger if the mouse is pressed and immediately release, without any move.
-}
onClick : msg -> Event msg
onClick toMsg config =
    { config | onClick = Just toMsg }


{-| Register a `MouseDown` event listener. It will trigger whenever the mouse is pressed.
-}
onMouseDown : msg -> Event msg
onMouseDown toMsg config =
    { config | onMouseDown = Just toMsg }


{-| Register a `MouseUp` event listener. It will trigger whenever the mouse is released.
-}
onMouseUp : msg -> Event msg
onMouseUp toMsg config =
    { config | onMouseUp = Just toMsg }