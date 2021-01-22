## Usage

```sh
$ elm-reactor
$ open http://localhost:8000/
```

## Examples

### Basic Example
A minimal example of a Draggable element. It only registers an `onDragBy` event which translates the element's position.

### Custom Events Example
A showcase of the other supported events: `onDragStart`, `onDragEnd`, `onClick`, `onMouseDown`.

### Constraints Examples
Controlling dragging directions using the keyboard.

### Pan And Zoom Example
Dragging on a scaled viewport.

### Multiple Targets Example
Multiple DOM elements' dragging state can be tracked at once.

### Free Drawing Example
Showcasing `customMouseTrigger` with `mouseOffsetDecoder`

### Right click Example
Showcasing `customMouseTrigger` with `buttonDecoder`, allowing custom buttons for mouse events.
