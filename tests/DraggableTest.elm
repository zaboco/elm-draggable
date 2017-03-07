port module TestApp exposing (..)

import Html exposing (Html)
import Html.Attributes as A
import Draggable


type alias Model =
    { drag : Draggable.State
    }


model : Model
model =
    { drag = Draggable.init
    }


port log : String -> Cmd msg


type Msg
    = TriggerDrag Draggable.State
    | UpdateDragBy Draggable.State Draggable.Delta


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        TriggerDrag drag ->
            { model | drag = drag } ! [ log "TriggerDrag" ]

        UpdateDragBy drag ( dx, dy ) ->
            { model | drag = drag }
                ! [ log ("UpdateDragBy " ++ (toString dx) ++ ", " ++ (toString dy)) ]


subscriptions : Model -> Sub Msg
subscriptions { drag } =
    Draggable.subscriptions UpdateDragBy drag


view : Model -> Html Msg
view _ =
    Html.div
        []
        [ Html.div
            [ A.id "basic-subscription-target"
            , Draggable.mouseTrigger TriggerDrag
            ]
            [ Html.text "Drag me" ]
        ]


main : Program Never Model Msg
main =
    Html.program
        { init = ( model, Cmd.none )
        , update = update
        , subscriptions = subscriptions
        , view = view
        }
