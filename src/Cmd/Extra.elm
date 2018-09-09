module Cmd.Extra exposing
    ( message
    , multiMessage
    , optionalMessage
    )

import Task


message : msg -> Cmd msg
message x =
    Task.perform identity (Task.succeed x)


multiMessage : List msg -> Cmd msg
multiMessage xs =
    xs
        |> List.map message
        |> Cmd.batch


optionalMessage : Maybe msg -> Cmd msg
optionalMessage msgMaybe =
    msgMaybe
        |> Maybe.map message
        |> Maybe.withDefault Cmd.none
