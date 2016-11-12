module Draggable
    exposing
        ( Drag
        , Delta
        , Msg
        , Config
        , basicConfig
        , init
        , update
        , subscriptions
        , triggerOnMouseDown
        )

{-|
Draggable

# Config
@docs basicConfig

# DOM triggers
@docs triggerOnMouseDown

# Boilerplate
@docs init, update, subscriptions

# Opaque structures
@docs Config, Drag, Msg, Delta
-}

import Cmd.Extra
import Internal
import Json.Decode
import Mouse
import VirtualDom


{-| Configuration of a draggable model
-}
type Config msg
    = Config (Internal.Config msg)


{-| Drag state to be included in model
-}
type alias Drag =
    Internal.Drag


{-|
-}
type alias Delta =
    Internal.Delta


{-| Messages to be wrapped
-}
type alias Msg =
    Internal.Msg


{-| Basic config
-}
basicConfig : (Delta -> msg) -> Config msg
basicConfig onDragBy =
    let
        defaultConfig =
            Internal.defaultConfig
    in
        Config { defaultConfig | onDragBy = Just << onDragBy }


{-| Initial drag state
-}
init : Drag
init =
    Internal.NoDrag


{-| Handle update messages for the draggable model
-}
update :
    Config msg
    -> Msg
    -> { m | drag : Drag }
    -> ( { m | drag : Drag }, Cmd msg )
update config msg model =
    let
        ( dragState, dragCmd ) =
            updateDraggable config msg model.drag
    in
        { model | drag = dragState } ! [ dragCmd ]


updateDraggable : Config msg -> Msg -> Drag -> ( Drag, Cmd msg )
updateDraggable (Config config) msg drag =
    let
        ( newDrag, newMsgs ) =
            Internal.updateAndEmit config msg drag
    in
        ( newDrag, Cmd.Extra.multiMessage newMsgs )


{-| Handle mouse subscriptions used for dragging
-}
subscriptions : (Msg -> msg) -> Drag -> Sub msg
subscriptions envelope drag =
    case drag of
        Internal.NoDrag ->
            Sub.none

        _ ->
            [ Mouse.moves Internal.DragAt, Mouse.ups (\_ -> Internal.DragEnd) ]
                |> Sub.batch
                |> Sub.map envelope


{-| DOM event handler to start dragging on mouse down.

    div [ triggerOnMouseDown DragMsg ] [ text "Drag me" ]

-}
triggerOnMouseDown : (Msg -> msg) -> VirtualDom.Property msg
triggerOnMouseDown envelope =
    let
        ignoreDefaults =
            VirtualDom.Options True True
    in
        VirtualDom.onWithOptions "mousedown"
            ignoreDefaults
            (Json.Decode.map (envelope << Internal.DragStart) Mouse.position)
