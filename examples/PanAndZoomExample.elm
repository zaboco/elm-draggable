module PanAndZoomExample exposing (..)

import Draggable
import Draggable.Vector as Vector exposing (Vector, getX, getY)
import Json.Decode as Decode exposing ((:=))
import Html exposing (Html)
import Html.App
import Svg exposing (Svg)
import Svg.Attributes as Attr
import VirtualDom


main : Program Never
main =
    Html.App.program
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        }


type alias Size num =
    { width : num
    , height : num
    }


type alias Model =
    { zoom : Float
    , center : Vector
    , size : Size Float
    , drag : Draggable.State
    }


type Msg
    = DragMsg Draggable.Msg
    | OnDragBy Vector
    | Zoom Float


init : ( Model, Cmd Msg )
init =
    ( { zoom = 1
      , center = Vector.init 0 0
      , size = Size 300 300
      , drag = Draggable.init
      }
    , Cmd.none
    )


dragConfig : Draggable.Config Msg
dragConfig =
    Draggable.basicConfig OnDragBy


update : Msg -> Model -> ( Model, Cmd Msg )
update msg ({ center, zoom } as model) =
    case msg of
        OnDragBy rawDelta ->
            let
                delta =
                    rawDelta
                        |> Vector.scale (-1 / zoom)
            in
                ( { model | center = center |> Vector.add delta }, Cmd.none )

        Zoom factor ->
            let
                newZoom =
                    zoom
                        |> (+) (factor * 0.05)
                        |> clamp 0.5 5
            in
                ( { model | zoom = newZoom }, Cmd.none )

        DragMsg dragMsg ->
            Draggable.update dragConfig dragMsg model


subscriptions : Model -> Sub Msg
subscriptions { drag } =
    Draggable.subscriptions DragMsg drag


view : Model -> Html Msg
view { center, size, zoom } =
    let
        ( cx, cy ) =
            ( getX center, getY center )

        ( halfWidth, halfHeight ) =
            ( size.width / zoom / 2, size.height / zoom / 2 )

        ( top, left, bottom, right ) =
            ( cy - halfHeight, cx - halfWidth, cy + halfHeight, cx + halfWidth )

        panning =
            "translate(" ++ toString -left ++ ", " ++ toString -top ++ ")"

        zooming =
            "scale(" ++ toString zoom ++ ")"
    in
        Svg.svg
            [ num Attr.width size.width
            , num Attr.height size.height
            , handleZoom Zoom
            , Draggable.triggerOnMouseDown DragMsg
            ]
            [ background
            , Svg.g
                [ Attr.transform (zooming ++ " " ++ panning)
                , Attr.stroke "black"
                , Attr.fill "none"
                ]
                [ Svg.line
                    [ num Attr.x1 left
                    , num Attr.x2 right
                    , num Attr.y1 0
                    , num Attr.y2 0
                    ]
                    []
                , Svg.line
                    [ num Attr.x1 0
                    , num Attr.x2 0
                    , num Attr.y1 top
                    , num Attr.y2 bottom
                    ]
                    []
                , Svg.circle
                    [ num Attr.cx 0
                    , num Attr.cy 0
                    , num Attr.r 10
                    ]
                    []
                ]
            ]


handleZoom : (Float -> msg) -> Svg.Attribute msg
handleZoom onZoom =
    let
        ignoreDefaults =
            VirtualDom.Options True True
    in
        VirtualDom.onWithOptions "wheel" ignoreDefaults (Decode.map onZoom <| "deltaY" := Decode.float)


background : Svg Msg
background =
    Svg.rect [ Attr.x "0", Attr.y "0", Attr.width "100%", Attr.height "100%", Attr.fill "#eee" ] []


num : (String -> Svg.Attribute msg) -> number -> Svg.Attribute msg
num attr value =
    attr (toString value)
