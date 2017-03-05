module FreeDrawingExample exposing (main)

import Draggable exposing (Delta)
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
    = UpdateDragBy (Draggable.State ()) Draggable.Delta
    | StartDrag (Draggable.State ()) Position


model : Model
model =
    { scene = Empty, drag = Draggable.init }


update : Msg -> Model -> Model
update msg model =
    case msg of
        StartDrag drag startPoint ->
            { model | drag = drag, scene = Path startPoint [] }

        UpdateDragBy drag delta ->
            case model.scene of
                Empty ->
                    model

                Path startPoint deltasSoFar ->
                    { model | drag = drag, scene = Path startPoint (delta :: deltasSoFar) }


subscriptions : Model -> Sub Msg
subscriptions { drag } =
    Draggable.basicSubscription UpdateDragBy drag


view : Model -> Html Msg
view { scene } =
    Svg.svg
        [ Attr.style "height: 90vh; width: 90vw; margin: 5vh 5vw;"
        , Attr.fill "none"
        , Attr.stroke "black"
        , Draggable.newCustomMouseTrigger mouseOffsetDecoder StartDrag
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
        { init = ( model, Cmd.none )
        , update = \msg model -> ( update msg model, Cmd.none )
        , subscriptions = subscriptions
        , view = view
        }
