module FreeDrawingExample exposing (main)

import Draggable exposing (Delta)
import Draggable.Events exposing (onDragBy, onMouseDown)
import Html exposing (Html)
import Json.Decode as Decode exposing (Decoder)
import Svg exposing (Svg)
import Svg.Attributes as Attr


type alias Model =
    { scene : Scene
    , drag : Draggable.State ()
    }


type Scene
    = Path Position (List Delta)
    | Empty


type alias Position =
    { x : Float
    , y : Float
    }


type Msg
    = DragMsg (Draggable.Msg ())
    | StartPathAndDrag (Draggable.Msg ()) Position
    | AddNewPointAtDelta Draggable.Delta


init : ( Model, Cmd msg )
init =
    ( { scene = Empty, drag = Draggable.init }, Cmd.none )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        DragMsg dragMsg ->
            Draggable.update dragConfig dragMsg model

        StartPathAndDrag dragMsg startPoint ->
            { model | scene = Path startPoint [] }
                |> Draggable.update dragConfig dragMsg

        AddNewPointAtDelta delta ->
            case model.scene of
                Empty ->
                    model ! []

                Path startPoint deltasSoFar ->
                    { model | scene = Path startPoint (delta :: deltasSoFar) } ! []


dragConfig : Draggable.Config () Msg
dragConfig =
    Draggable.customConfig
        [ onDragBy AddNewPointAtDelta
        ]


subscriptions : Model -> Sub Msg
subscriptions { drag } =
    Draggable.subscriptions DragMsg drag


view : Model -> Html Msg
view { scene } =
    Svg.svg
        [ Attr.style "height: 100vh; width: 100vw; margin: 100px;"
        , Attr.fill "none"
        , Attr.stroke "black"
        , Draggable.customMouseTrigger mouseOffsetDecoder StartPathAndDrag
        ]
        [ background
        , sceneView scene
        ]


mouseOffsetDecoder : Decoder Position
mouseOffsetDecoder =
    Decode.map2 Position
        (Decode.field "offsetX" Decode.float)
        (Decode.field "offsetY" Decode.float)


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
