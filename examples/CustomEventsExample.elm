module CustomEventsExample exposing (..)

import Html exposing (Html)
import Html.App
import Html.Attributes as A
import Mouse exposing (Position)
import Draggable exposing (onClick, onDragBy, onDragEnd, onDragStart)
import Draggable.Delta as Delta exposing (Delta)


type alias Model =
    { xy : Position
    , clicks : Int
    , dragging : Bool
    , drag : Draggable.Drag
    }


type Msg
    = OnDragBy Delta
    | OnDragStart
    | OnDragEnd
    | OnClick
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
    ( { xy = Position 0 0
      , drag = Draggable.init
      , clicks = 0
      , dragging = False
      }
    , Cmd.none
    )


dragConfig : Draggable.Config Msg
dragConfig =
    Draggable.customConfig
        [ onDragStart OnDragStart
        , onDragEnd OnDragEnd
        , onDragBy OnDragBy
        , onClick OnClick
        ]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        OnDragBy delta ->
            ( { model | xy = Delta.translate delta model.xy }
            , Cmd.none
            )

        OnDragStart ->
            ( { model | dragging = True }, Cmd.none )

        OnDragEnd ->
            ( { model | dragging = False }, Cmd.none )

        OnClick ->
            ( { model | clicks = model.clicks + 1 }, Cmd.none )

        DragMsg dragMsg ->
            Draggable.update dragConfig dragMsg model


subscriptions : Model -> Sub Msg
subscriptions { drag } =
    Draggable.subscriptions DragMsg drag


view : Model -> Html Msg
view { xy, dragging, clicks } =
    let
        translate =
            "translate(" ++ (toString xy.x) ++ "px, " ++ (toString xy.y) ++ "px)"

        style =
            [ "transform" => translate
            , "padding" => "16px"
            , "margin" => "32px"
            , "background-color" => "lightgray"
            , "width" => "100px"
            , "text-align" => "center"
            , "cursor" => "move"
            ]

        status =
            if dragging then
                "Release me"
            else
                "Drag me"
    in
        Html.div
            [ A.style style
            , Draggable.triggerOnMouseDown DragMsg
            ]
            [ Html.text status
            , Html.br [] []
            , Html.text <| (toString clicks) ++ " clicks"
            ]


(=>) =
    (,)
