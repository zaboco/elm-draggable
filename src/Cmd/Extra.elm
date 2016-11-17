module Cmd.Extra exposing (..)

import Task


message : msg -> Cmd msg
message x =
    Task.perform identity (Task.succeed x)


multiMessage : List msg -> Cmd msg
multiMessage xs =
    xs
        |> List.map message
        |> Cmd.batch
