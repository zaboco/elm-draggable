module RigthClickExample exposing (main)

import Browser
import Draggable
import Draggable.Events exposing (onDragBy)
import Html exposing (Html)
import Html.Attributes as A
import Html.Events
import Json.Decode as JD


type alias Position =
    { x : Float
    , y : Float
    }


type alias Model =
    { xy : Position
    , mouseButton : Maybe Int
    , drag : Draggable.State String
    }


type Msg
    = OnDragBy Draggable.Delta
    | OnMouseDown (Draggable.Msg String) Int
    | OnMouseUp
    | DragMsg (Draggable.Msg String)
    | NoOp


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
    ( { xy = Position 32 32
      , drag = Draggable.init
      , mouseButton = Nothing
      }
    , Cmd.none
    )


dragConfig : Draggable.Config String Msg
dragConfig =
    Draggable.customConfig
        [ onDragBy OnDragBy
        ]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg ({ xy } as model) =
    case msg of
        OnDragBy ( dx, dy ) ->
            ( { model | xy = Position (xy.x + dx) (xy.y + dy) }
            , Cmd.none
            )

        DragMsg dragMsg ->
            Draggable.update dragConfig dragMsg model

        OnMouseDown dragMsg button ->
            { model | mouseButton = Just button } |> Draggable.update dragConfig dragMsg

        OnMouseUp ->
            ( { model | mouseButton = Nothing }, Cmd.none )

        NoOp ->
            ( model, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions { drag } =
    Draggable.subscriptions DragMsg drag


view : Model -> Html Msg
view { xy, mouseButton } =
    let
        translate =
            "translate(" ++ String.fromFloat xy.x ++ "px, " ++ String.fromFloat xy.y ++ "px)"

        alwaysPreventDefaultAndStopPropagation msg =
            { message = msg, stopPropagation = True, preventDefault = True }

        textAboutButton =
            mouseButton
                |> Maybe.map String.fromInt
                |> Maybe.withDefault ""
    in
    Html.div
        [ A.style "transform" translate
        , A.style "padding" "16px"
        , A.style "background-color" "lightgray"
        , A.style "width" "100px"
        , A.style "text-align" "center"
        , A.style "cursor" "move"
        , A.id "box"
        , Draggable.customMouseTrigger "" mouseButtonDecoder OnMouseDown
        , Html.Events.custom "contextmenu" <| JD.map alwaysPreventDefaultAndStopPropagation <| JD.succeed NoOp
        , Html.Events.onMouseUp OnMouseUp
        ]
        [ Html.text <| "Drag me " ++ textAboutButton ]


mouseButtonDecoder : JD.Decoder Int
mouseButtonDecoder =
    JD.field "button" JD.int
