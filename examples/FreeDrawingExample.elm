module FreeDrawingExample exposing (main)

import Draggable exposing (Delta)
import Draggable.Events exposing (onDragBy, onMouseDown)
import Html exposing (Html)
import Svg exposing (Svg)
import Svg.Attributes as Attr


type alias Model =
    { scene : Scene
    , drag : Draggable.State
    }


type Scene
    = Path Position (List Delta)
    | Empty


type alias Position =
    { x : Float
    , y : Float
    }


type SceneMsg
    = StartPath Position
    | NewPointBy Delta


type Msg
    = UpdateScene SceneMsg
    | DragMsg Draggable.Msg


init : ( Model, Cmd msg )
init =
    ( { scene = Empty, drag = Draggable.init }, Cmd.none )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        DragMsg dragMsg ->
            Draggable.update dragConfig dragMsg model

        UpdateScene sceneMsg ->
            ( { model | scene = updateScene sceneMsg model.scene }, Cmd.none )


updateScene : SceneMsg -> Scene -> Scene
updateScene msg scene =
    case ( scene, msg ) of
        ( _, StartPath startPoint ) ->
            Path startPoint []

        ( Path startPoint deltasSoFar, NewPointBy lastDelta ) ->
            Path startPoint (lastDelta :: deltasSoFar)

        _ ->
            scene


dragConfig : Draggable.Config Msg
dragConfig =
    Draggable.customConfig
        [ onMouseDown (\_ -> UpdateScene <| StartPath { x = 10, y = 10 })
        , onDragBy (UpdateScene << NewPointBy)
        ]


subscriptions : Model -> Sub Msg
subscriptions { drag } =
    Draggable.subscriptions DragMsg drag


view : Model -> Html Msg
view { scene } =
    Svg.svg
        [ Attr.style "height: 100vh; width: 100vw;"
        , Attr.fill "none"
        , Attr.stroke "black"
        , Draggable.mouseTrigger "" DragMsg
        ]
        [ background
        , sceneView scene
        ]


sceneView : Scene -> Svg msg
sceneView scene =
    case scene of
        Empty ->
            Svg.text ""

        Path firstPoint deltas ->
            pathView firstPoint deltas


pathView : Position -> List Delta -> Svg msg
pathView firstPoint reverseDeltas =
    let
        deltas =
            List.reverse reverseDeltas

        deltasString =
            deltas
                |> List.map (\( dx, dy ) -> " l " ++ (toString dx) ++ " " ++ (toString dy))
                |> String.join ""

        firstPointString =
            "M " ++ (toString firstPoint.x) ++ " " ++ (toString firstPoint.y)

        pathString =
            firstPointString ++ deltasString
    in
        Svg.path [ Attr.d pathString ] []


background : Svg msg
background =
    Svg.rect
        [ Attr.x "0"
        , Attr.y "0"
        , Attr.width "100%"
        , Attr.height "100%"
        , Attr.fill "#eee"
        ]
        []


main : Program Never Model Msg
main =
    Html.program
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        }
