module Draggable
    exposing
        ( Drag
        , update
        )

{-|
Draggable

# Boilerplate
@docs update

# Opaque structures
@docs Drag
-}

import Config exposing (Config)
import Internal
import Cmd.Extra


{-|
Drag state to be included in model
-}
type alias Drag =
    Internal.Drag


{-|
Handle Drag update messages
-}
update : Config msg -> Internal.Msg -> Internal.Drag -> ( Internal.Drag, Cmd msg )
update (Config.Config config) msg drag =
    let
        ( newDrag, newMsgs ) =
            Internal.updateAndEmit config msg drag
    in
        ( newDrag, Cmd.Extra.multiMessage newMsgs )
