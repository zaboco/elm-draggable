module CustomEventsExample exposing (main)

import Browser
import Draggable
import Draggable.Events exposing (onClick, onDragBy, onDragEnd, onDragStart)
import Html exposing (Html)
import Html.Attributes as A
import Html.Events


type alias Position =
    { x : Float
    , y : Float
    }


type alias Model =
    { xy : Position
    , clicksCount : Int
    , isDragging : Bool
    , isClicked : Bool
    , drag : Draggable.State String
    }


type Msg
    = OnDragBy Draggable.Delta
    | OnDragStart
    | OnDragEnd
    | CountClick
    | SetClicked Bool
    | DragMsg (Draggable.Msg String)


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
      , clicksCount = 0
      , isDragging = False
      , isClicked = False
      }
    , Cmd.none
    )


dragConfig : Draggable.Config String Msg
dragConfig =
    Draggable.customConfig
        [ onDragStart (\_ -> OnDragStart)
        , onDragEnd OnDragEnd
        , onDragBy OnDragBy
        , onClick (\_ -> CountClick)
        , Draggable.Events.onMouseDown (\_ -> SetClicked True)
        ]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg ({ xy } as model) =
    case msg of
        OnDragBy ( dx, dy ) ->
            ( { model | xy = Position (xy.x + dx) (xy.y + dy) }
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
            "translate(" ++ String.fromFloat xy.x ++ "px, " ++ String.fromFloat xy.y ++ "px)"

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
    in
    Html.div
        [ A.style "transform" translate
        , A.style "padding" "16px"
        , A.style "background-color" color
        , A.style "width" "100px"
        , A.style "text-align" "center"
        , A.style "cursor" "move"
        , Draggable.mouseTrigger "" DragMsg
        , Html.Events.onMouseUp (SetClicked False)
        ]
        [ Html.text status
        , Html.br [] []
        , Html.text <| String.fromInt clicksCount ++ " clicks"
        ]
