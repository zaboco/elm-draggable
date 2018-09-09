module PanAndZoomExample exposing (main)

import Browser
import Browser.Events
import Draggable
import Html exposing (Html)
import Html.Events
import Json.Decode as Decode exposing (Decoder)
import Math.Vector2 as Vector2 exposing (Vec2, getX, getY)
import Svg exposing (Svg)
import Svg.Attributes as Attr


main : Program () Model Msg
main =
    Browser.element
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
    , center : Vec2
    , size : Size Float
    , drag : Draggable.State ()
    }


type Msg
    = DragMsg (Draggable.Msg ())
    | OnDragBy Vec2
    | Zoom Float


init : flags -> ( Model, Cmd Msg )
init _ =
    ( { zoom = 1
      , center = Vector2.vec2 0 0
      , size = Size 300 300
      , drag = Draggable.init
      }
    , Cmd.none
    )


dragConfig : Draggable.Config () Msg
dragConfig =
    Draggable.basicConfig (OnDragBy << (\( dx, dy ) -> Vector2.vec2 dx dy))


update : Msg -> Model -> ( Model, Cmd Msg )
update msg ({ center, zoom } as model) =
    case msg of
        OnDragBy rawDelta ->
            let
                delta =
                    rawDelta
                        |> Vector2.scale (-1 / zoom)
            in
            ( { model | center = center |> Vector2.add delta }, Cmd.none )

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

        ( top, left ) =
            ( cy - halfHeight, cx - halfWidth )

        ( bottom, right ) =
            ( cy + halfHeight, cx + halfWidth )

        panning =
            "translate(" ++ String.fromFloat -left ++ ", " ++ String.fromFloat -top ++ ")"

        zooming =
            "scale(" ++ String.fromFloat zoom ++ ")"
    in
    Svg.svg
        [ num Attr.width size.width
        , num Attr.height size.height
        , handleZoom Zoom
        , Draggable.mouseTrigger () DragMsg
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
        alwaysPreventDefaultAndStopPropagation msg =
            { message = msg, stopPropagation = True, preventDefault = True }

        zoomDecoder : Decoder msg
        zoomDecoder =
            Decode.float
                |> Decode.field "deltaY"
                |> Decode.map onZoom
    in
    Html.Events.custom
        "wheel"
    <|
        Decode.map alwaysPreventDefaultAndStopPropagation zoomDecoder


background : Svg Msg
background =
    Svg.rect [ Attr.x "0", Attr.y "0", Attr.width "100%", Attr.height "100%", Attr.fill "#eee" ] []


num : (String -> Svg.Attribute msg) -> Float -> Svg.Attribute msg
num attr value =
    attr (String.fromFloat value)
