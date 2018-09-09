module BasicExample exposing (main)

import Browser
import Draggable
import Html exposing (Html)
import Html.Attributes as A


type alias Position =
    { x : Float
    , y : Float
    }


type alias Model =
    { xy : Position
    , drag : Draggable.State ()
    }


type Msg
    = OnDragBy Draggable.Delta
    | DragMsg (Draggable.Msg ())


main : Program () Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        }


init : flags -> ( Model, Cmd Msg )
init _ =
    ( { xy = Position 32 32, drag = Draggable.init }
    , Cmd.none
    )


dragConfig : Draggable.Config () Msg
dragConfig =
    Draggable.basicConfig OnDragBy


update : Msg -> Model -> ( Model, Cmd Msg )
update msg ({ xy } as model) =
    case msg of
        OnDragBy ( dx, dy ) ->
            ( { model | xy = Position (xy.x + dx) (xy.y + dy) }
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
            "translate(" ++ String.fromFloat xy.x ++ "px, " ++ String.fromFloat xy.y ++ "px)"
    in
    Html.div
        ([ A.style "transform" translate
         , A.style "padding" "16px"
         , A.style "background-color" "lightgray"
         , A.style "width" "64px"
         , A.style "cursor" "move"
         , Draggable.mouseTrigger () DragMsg
         ]
            ++ Draggable.touchTriggers () DragMsg
        )
        [ Html.text "Drag me" ]
