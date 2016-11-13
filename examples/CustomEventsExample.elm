module CustomEventsExample exposing (..)

import Html exposing (Html)
import Html.App
import Html.Attributes as A
import Mouse exposing (Position)
import Draggable exposing (onClick, onDragBy, onDragEnd, onDragStart, onMouseDown, onMouseUp)
import Draggable.Delta as Delta exposing (Delta)


type alias Model =
    { xy : Position
    , clicksCount : Int
    , isDragging : Bool
    , isClicked : Bool
    , drag : Draggable.State
    }


type Msg
    = OnDragBy Delta
    | OnDragStart
    | OnDragEnd
    | CountClick
    | SetClicked Bool
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
      , clicksCount = 0
      , isDragging = False
      , isClicked = False
      }
    , Cmd.none
    )


dragConfig : Draggable.Config Msg
dragConfig =
    Draggable.customConfig
        [ onDragStart OnDragStart
        , onDragEnd OnDragEnd
        , onDragBy OnDragBy
        , onClick CountClick
        , onMouseDown (SetClicked True)
        , onMouseUp (SetClicked False)
        ]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        OnDragBy delta ->
            ( { model | xy = Delta.translate delta model.xy }
            , Cmd.none
            )

        OnDragStart ->
            ( { model | isDragging = True }, Cmd.none )

        OnDragEnd ->
            ( { model | isDragging = False }, Cmd.none )

        CountClick ->
            ( { model | clicksCount = model.clicksCount + 1 }, Cmd.none )

        SetClicked flag ->
            ( { model | isClicked = flag }, Cmd.none )

        DragMsg dragMsg ->
            Draggable.update dragConfig dragMsg model


subscriptions : Model -> Sub Msg
subscriptions { drag } =
    Draggable.subscriptions DragMsg drag


view : Model -> Html Msg
view { xy, isDragging, isClicked, clicksCount } =
    let
        translate =
            "translate(" ++ (toString xy.x) ++ "px, " ++ (toString xy.y) ++ "px)"

        status =
            if isDragging then
                "Release me"
            else
                "Drag me"

        color =
            if isClicked then
                "limegreen"
            else
                "lightgray"

        style =
            [ "transform" => translate
            , "padding" => "16px"
            , "margin" => "32px"
            , "background-color" => color
            , "width" => "100px"
            , "text-align" => "center"
            , "cursor" => "move"
            ]
    in
        Html.div
            [ A.style style
            , Draggable.triggerOnMouseDown DragMsg
            ]
            [ Html.text status
            , Html.br [] []
            , Html.text <| (toString clicksCount) ++ " clicks"
            ]


(=>) =
    (,)