module Draggable
    exposing
        ( Drag
        , update
        )

import Mouse exposing (Position)
import Internal
import Cmd.Extra


type alias Drag =
    Internal.Drag


update : Internal.Msg -> Internal.Drag -> ( Internal.Drag, Cmd Internal.Msg )
update msg drag =
    let
        ( newDrag, newMsgs ) =
            Internal.updateAndEmit msg drag
    in
        ( newDrag, Cmd.Extra.multiMessage newMsgs )
