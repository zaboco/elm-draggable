port module TestApp exposing (..)

import Html exposing (Html)
import Html.Attributes as A
import Draggable
import Mouse


type alias Position =
    { x : Float
    , y : Float
    }


type alias Model =
    { xy : Position
    , drag : Draggable.State
    , eventsLog : List String
    }


model : Model
model =
    { xy = Position 32 32
    , drag = Draggable.init
    , eventsLog = []
    }


port log : String -> Cmd msg


type Msg
    = TriggerDrag Draggable.State
    | UpdateDragBy Draggable.State Draggable.Delta
    | NoOp


update : Msg -> Model -> ( Model, Cmd Msg )
update msg ({ xy, eventsLog } as model) =
    case msg of
        TriggerDrag drag ->
            { model | drag = drag } ! [ log "Trigger" ]

        UpdateDragBy drag ( dx, dy ) ->
            { model
                | drag = drag
                , xy = Position (xy.x + dx) (xy.y + dy)
            }
                ! [ log ("Drag by" ++ (toString dx) ++ ", " ++ (toString dy)) ]

        NoOp ->
            model ! []


subscriptions : Model -> Sub Msg
subscriptions { drag } =
    --    Sub.batch
    --        [ Draggable.subscriptions UpdateDragBy drag
    --        , Mouse.moves (\_ -> NoOp)
    --        ]
    Draggable.subscriptions UpdateDragBy drag


view : Model -> Html Msg
view { xy, eventsLog } =
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

        logString =
            eventsLog
                |> List.reverse
                |> String.join " "
    in
        Html.div
            []
            [ Html.div
                [ A.style style
                , A.id "draggable-box"
                , Draggable.mouseTrigger TriggerDrag
                ]
                [ Html.text "Drag me" ]
            , Html.div
                [ A.id "log" ]
                [ Html.text logString ]
            ]


(=>) : a -> b -> ( a, b )
(=>) =
    (,)


main : Program Never Model Msg
main =
    Html.program
        { init = ( model, Cmd.none )
        , update = update
        , subscriptions = subscriptions
        , view = view
        }
