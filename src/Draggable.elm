module Draggable
    exposing
        ( Drag
        , Msg
        , basicConfig
        , customConfig
        , init
        , update
        , subscriptions
        , triggerOnMouseDown
        )

{-|
Draggable

# Config
@docs basicConfig, customConfig

# DOM triggers
@docs triggerOnMouseDown

# Boilerplate
@docs init, update, subscriptions

# Opaque structures
@docs Drag, Msg
-}

import Internal
import Json.Decode
import Mouse
import VirtualDom
import Draggable.Delta as Delta exposing (Delta)
import Draggable.Config as Config exposing (DragConfig)


{-| Drag state to be included in model
-}
type alias Drag =
    Internal.Drag


{-| Messages to be wrapped
-}
type alias Msg =
    Internal.Msg


{-| Basic config

    config = basicConfig OnDragBy
-}
basicConfig : (Delta -> msg) -> DragConfig msg
basicConfig onDragBy =
    Config.defaultConfig
        |> Config.onDragBy onDragBy


{-| Custom config, including arbitrary options. See `Config` module for the available `modifiers`.

    config = customConfig
        [ onDragBy OnDragBy
        , onDragStart OnDragStart
        , onDragEnd OnDragEnd
        , onClick OnClick
        ]
-}
customConfig : List (DragConfig msg -> DragConfig msg) -> DragConfig msg
customConfig modifiers =
    List.foldl (<|) Config.defaultConfig modifiers


{-| Initial drag state
-}
init : Drag
init =
    Internal.NoDrag


{-| Handle update messages for the draggable model. It assumes that the drag state will be stored under the key `drag`.
-}
update :
    DragConfig msg
    -> Msg
    -> { m | drag : Drag }
    -> ( { m | drag : Drag }, Cmd msg )
update config msg model =
    let
        ( dragState, dragCmd ) =
            Internal.updateDraggable config msg model.drag
    in
        { model | drag = dragState } ! [ dragCmd ]


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
