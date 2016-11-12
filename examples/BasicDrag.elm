module DraggableDiv exposing (..)

import Html exposing (Html)
import Html.App
import Html.Attributes as A
import Mouse exposing (Position)
import Draggable


type alias Model =
    { xy : Position
    , drag : Draggable.Drag
    }


type Msg
    = OnDragBy Draggable.Delta
    | DragMsg Draggable.Msg


main : Program Never
main =
    Html.App.program
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        }


init : ( Model, Cmd Msg )
init =
    ( { xy = Position 0 0, drag = Draggable.init }
    , Cmd.none
    )


dragConfig : Draggable.Config Msg
dragConfig =
    Draggable.basicConfig OnDragBy


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        OnDragBy { dx, dy } ->
            ( { model | xy = { x = model.xy.x + dx, y = model.xy.y + dy } }
            , Cmd.none
            )

        DragMsg dragMsg ->
            let
                ( dragState, dragCmd ) =
                    Draggable.update dragConfig dragMsg model.drag
            in
                { model | drag = dragState } ! [ dragCmd ]


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
            , "margin" => "32px"
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
