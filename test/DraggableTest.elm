port module TestApp exposing (..)

import Html exposing (Html)
import Html.Attributes as A
import Json.Decode as Decode exposing (Decoder)
import Draggable exposing (DragEvent)


type alias Model =
    { basicDrag : Draggable.State
    , eventDrag : Draggable.State
    }


model : Model
model =
    { basicDrag = Draggable.init
    , eventDrag = Draggable.init
    }


port log : String -> Cmd msg


type Msg
    = TriggerBasicDrag Draggable.State
    | UpdateBasicDrag Draggable.State Draggable.Delta
    | TriggerEventDrag Draggable.State
    | UpdateEventDrag Draggable.State DragEvent
    | CustomTrigger Draggable.State Float


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        TriggerBasicDrag basicDrag ->
            { model | basicDrag = basicDrag } ! [ log "TriggerBasicDrag" ]

        UpdateBasicDrag basicDrag ( dx, dy ) ->
            { model | basicDrag = basicDrag }
                ! [ log ("UpdateBasicDrag " ++ (toString dx) ++ ", " ++ (toString dy)) ]

        TriggerEventDrag eventDrag ->
            { model | eventDrag = eventDrag } ! [ log "TriggerEventDrag" ]

        UpdateEventDrag eventDrag dragEvent ->
            { model | eventDrag = eventDrag } ! [ log ("UpdateEventDrag " ++ (toString dragEvent)) ]

        CustomTrigger eventDrag offsetX ->
            -- reusing the eventDrag, since it is not relevant for this use-case
            { model | eventDrag = eventDrag } ! [ log ("CustomTrigger " ++ (toString offsetX)) ]


subscriptions : Model -> Sub Msg
subscriptions { basicDrag, eventDrag } =
    Sub.batch
        [ Draggable.subscriptions UpdateBasicDrag basicDrag
        , Draggable.eventSubscriptions UpdateEventDrag eventDrag
        ]


view : Model -> Html Msg
view _ =
    Html.div
        []
        [ Html.div
            [ A.id "basic-subscription-target"
            , Draggable.mouseTrigger TriggerBasicDrag
            ]
            [ Html.text "Drag me" ]
        , Html.div
            [ A.id "event-subscription-target"
            , Draggable.mouseTrigger TriggerEventDrag
            ]
            [ Html.text "Drag me too" ]
        , Html.div
            [ A.id "custom-trigger-target"
            , Draggable.customMouseTrigger mouseOffsetXDecoder CustomTrigger
            ]
            [ Html.text "Whatever" ]
        ]


mouseOffsetXDecoder : Decoder Float
mouseOffsetXDecoder =
    Decode.field "offsetX" Decode.float


main : Program Never Model Msg
main =
    Html.program
        { init = ( model, Cmd.none )
        , update = update
        , subscriptions = subscriptions
        , view = view
        }
