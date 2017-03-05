module BasicExample exposing (..)

import Html exposing (Html)
import Html.Attributes as A
import Draggable


type alias Position =
    { x : Float
    , y : Float
    }


type alias Model =
    { xy : Position
    , drag : Draggable.State
    }


type Msg
    = TriggerDrag Draggable.State
    | UpdateDragBy Draggable.State Draggable.Delta


main : Program Never Model Msg
main =
    Html.program
        { init = ( model, Cmd.none )
        , update = \msg model -> ( update msg model, Cmd.none )
        , subscriptions = subscriptions
        , view = view
        }


model : Model
model =
    { xy = Position 32 32, drag = Draggable.init }


update : Msg -> Model -> Model
update msg ({ xy } as model) =
    case msg of
        TriggerDrag drag ->
            { model | drag = drag }

        UpdateDragBy drag ( dx, dy ) ->
            { model
                | drag = drag
                , xy = Position (xy.x + dx) (xy.y + dy)
            }


subscriptions : Model -> Sub Msg
subscriptions { drag } =
    Draggable.subscriptions UpdateDragBy drag


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
            , Draggable.mouseTrigger TriggerDrag
            ]
            [ Html.text "Drag me" ]


(=>) : a -> b -> ( a, b )
(=>) =
    (,)
