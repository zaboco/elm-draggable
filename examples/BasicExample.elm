module BasicExample exposing (..)

import Html exposing (Html)
import Html.Attributes as A
import Draggable
import Draggable.Vector as Vector exposing (Vector, getX, getY)


type alias Model =
    { xy : Vector
    , drag : Draggable.State
    }


type Msg
    = OnDragBy Vector
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
    ( { xy = Vector.init 32 32, drag = Draggable.init }
    , Cmd.none
    )


dragConfig : Draggable.Config Msg
dragConfig =
    Draggable.basicConfig OnDragBy


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        OnDragBy delta ->
            ( { model | xy = Vector.add delta model.xy }
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
            "translate(" ++ (toString <| getX xy) ++ "px, " ++ (toString <| getY xy) ++ "px)"

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
