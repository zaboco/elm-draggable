module BasicExample exposing (..)

import Html exposing (Html)
import Html.Attributes as A
import Draggable
import Mouse exposing (Position)


type alias Model =
    { xy : Position
    , drag : Draggable.State
    }


type Msg
    = OnDragBy Position
    | DragMsg Draggable.Msg


main : Program Never Model Msg
main =
    Html.program
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        }


init : ( Model, Cmd Msg )
init =
    ( { xy = Position 32 32, drag = Draggable.init }
    , Cmd.none
    )


dragConfig : Draggable.Config Msg
dragConfig =
    Draggable.basicConfig (OnDragBy << Draggable.deltaToPosition)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg ({ xy } as model) =
    case msg of
        OnDragBy { x, y } ->
            ( { model | xy = Position (xy.x + x) (xy.y + y) }
            , Cmd.none
            )

        DragMsg dragMsg ->
            Draggable.update dragConfig dragMsg model


subscriptions : Model -> Sub Msg
subscriptions { drag } =
    Draggable.subscriptions DragMsg drag


view : Model -> Html Msg
view { xy } =
    let
        translate =
            "translate(" ++ (toString xy.x) ++ "px, " ++ (toString xy.y) ++ "px)"

        style =
            [ "transform" => translate
            , "padding" => "16px"
            , "background-color" => "lightgray"
            , "width" => "64px"
            , "cursor" => "move"
            ]
    in
        Html.div
            [ A.style style
            , Draggable.triggerOnMouseDown DragMsg
            ]
            [ Html.text "Drag me" ]


(=>) =
    (,)
