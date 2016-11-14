module CustomEventsExample exposing (..)

import Html exposing (Html)
import Html.App
import Html.Attributes as A
import Draggable exposing (onClick, onDragBy, onDragEnd, onDragStart, onMouseDown, onMouseUp)
import Draggable.Vector as Vector exposing (Vector, getX, getY)


type alias Model =
    { xy : Vector
    , clicksCount : Int
    , isDragging : Bool
    , isClicked : Bool
    , drag : Draggable.State
    }


type Msg
    = OnDragBy Vector
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
    ( { xy = Vector.init 32 32
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
            ( { model | xy = Vector.add delta model.xy }
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
            "translate(" ++ (toString <| getX xy) ++ "px, " ++ (toString <| getY xy) ++ "px)"

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
