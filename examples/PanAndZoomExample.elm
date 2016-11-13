module PanAndZoomExample exposing (..)

import Draggable
import Draggable.Delta as Delta exposing (Delta)
import Html exposing (Html)
import Html.App
import Mouse exposing (Position)
import Svg exposing (Svg)
import Svg.Attributes as Attr


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
    , center : Position
    , size : Size Float
    , drag : Draggable.State
    }


type Msg
    = DragMsg Draggable.Msg
    | OnDragBy Delta


init : ( Model, Cmd Msg )
init =
    ( { zoom = 1
      , center = Position 0 0
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
                    rawDelta |> Delta.scale (-zoom)
            in
                ( { model | center = center |> Delta.translate delta }, Cmd.none )

        DragMsg dragMsg ->
            Draggable.update dragConfig dragMsg model


subscriptions : Model -> Sub Msg
subscriptions { drag } =
    Draggable.subscriptions DragMsg drag


view : Model -> Html Msg
view { center, size } =
    let
        ( cx, cy ) =
            ( toFloat center.x, toFloat center.y )

        ( halfWidth, halfHeight ) =
            ( size.width / 2, size.height / 2 )

        ( top, left, bottom, right ) =
            ( cy - halfHeight, cx - halfWidth, cy + halfHeight, cx + halfWidth )

        panning =
            "translate(" ++ toString (-left) ++ ", " ++ toString (-top) ++ ")"
    in
        Svg.svg
            [ num Attr.width size.width
            , num Attr.height size.height
            , Draggable.triggerOnMouseDown DragMsg
            ]
            [ background
            , Svg.g
                [ Attr.transform panning
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


background : Svg Msg
background =
    Svg.rect [ Attr.x "0", Attr.y "0", Attr.width "100%", Attr.height "100%", Attr.fill "#eee" ] []


num : (String -> Svg.Attribute msg) -> number -> Svg.Attribute msg
num attr value =
    attr (toString value)
