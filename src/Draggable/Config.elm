module Draggable.Config
    exposing
        ( DragConfig
        , defaultConfig
        , onDragStart
        , onDragEnd
        , onDragBy
        , onClick
        )

{-| This modules provides helper functions for setting up the Config

# Definition
@docs DragConfig

# Init
@docs defaultConfig

# Modifiers
@docs onDragStart, onDragEnd, onDragBy, onClick
-}

import Draggable.Delta exposing (Delta)
import Internal exposing (Config(..))


{-| Configuration of a draggable model. Includes listeners for various events related to dragging.
-}
type alias DragConfig msg =
    Internal.Config msg


{-| The default configuration for dragging. It's just a starting point, and must be extended with `modifiers` in order to be of any use.
-}
defaultConfig : Config msg
defaultConfig =
    Internal.defaultConfig


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


{-| Register a `DragStart` event listener. It will not trigger if the mouse has not moved while it was pressed.
-}
onDragBy : (Delta -> msg) -> Config msg -> Config msg
onDragBy toMsg (Config config) =
    Config { config | onDragBy = Just << toMsg }


{-| Register a `Click` event listener. It will trigger if the mouse is pressed and immediately release, without any move.
-}
onClick : msg -> Config msg -> Config msg
onClick toMsg (Config config) =
    Config { config | onClick = Just toMsg }
