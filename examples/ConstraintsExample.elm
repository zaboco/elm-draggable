module ConstraintsExample exposing (..)

import Draggable
import Draggable.Vector as Vector exposing (Vector, getX, getY)
import Html exposing (Html)
import Svg exposing (Svg)
import Svg.Attributes as Attr


main : Program Never Model Msg
main =
    Html.program
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        }


type alias Model =
    { position : Vector
    , drag : Draggable.State
    , isDraggingX : Bool
    , isDraggingY : Bool
    }


type Msg
    = DragMsg Draggable.Msg
    | OnDragBy Vector
    | SetDraggingX Bool
    | SetDraggingY Bool


init : ( Model, Cmd Msg )
init =
    ( { position = Vector.init 100 100
      , drag = Draggable.init
      , isDraggingX = True
      , isDraggingY = True
      }
    , Cmd.none
    )


dragConfig : Draggable.Config Msg
dragConfig =
    Draggable.basicConfig OnDragBy


update : Msg -> Model -> ( Model, Cmd Msg )
update msg ({ position } as model) =
    case msg of
        OnDragBy delta ->
            ( { model | position = Vector.add delta position }, Cmd.none )

        DragMsg dragMsg ->
            Draggable.update dragConfig dragMsg model

        SetDraggingX flag ->
            ( { model | isDraggingX = flag }, Cmd.none )

        SetDraggingY flag ->
            ( { model | isDraggingY = flag }, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions { drag } =
    Draggable.subscriptions DragMsg drag



-- VIEW


type alias Size =
    { width : Float, height : Float }


sceneSize : Size
sceneSize =
    Size 400 400


boxSize : Size
boxSize =
    Size 60 60


view : Model -> Html Msg
view { position, isDraggingX, isDraggingY } =
    Svg.svg
        [ num Attr.width sceneSize.width
        , num Attr.height sceneSize.height
        ]
        [ background
        , verticalGuideline (getY position) isDraggingY
        , horizontalGuideline (getX position) isDraggingX
        , box position
        ]


box : Vector -> Svg Msg
box position =
    let
        { width, height } =
            boxSize

        ( x, y ) =
            ( getX position - width / 2
            , getY position - height / 2
            )
    in
        Svg.rect
            [ num Attr.width boxSize.width
            , num Attr.height boxSize.height
            , num Attr.x x
            , num Attr.y y
            , Attr.cursor "move"
            , Attr.fill "red"
            , Draggable.triggerOnMouseDown DragMsg
            ]
            []


verticalGuideline : Float -> Bool -> Svg Msg
verticalGuideline y isEnabled =
    Svg.line
        [ num Attr.x1 0
        , num Attr.x2 sceneSize.width
        , num Attr.y1 y
        , num Attr.y2 y
        , Attr.stroke (guidelineColor isEnabled)
        , Attr.strokeDasharray "5, 5"
        ]
        []


horizontalGuideline : Float -> Bool -> Svg Msg
horizontalGuideline x isEnabled =
    Svg.line
        [ num Attr.x1 x
        , num Attr.x2 x
        , num Attr.y1 0
        , num Attr.y2 sceneSize.height
        , Attr.stroke (guidelineColor isEnabled)
        , Attr.strokeDasharray "5, 5"
        ]
        []


guidelineColor : Bool -> String
guidelineColor isEnabled =
    if isEnabled then
        "black"
    else
        "gray"


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


num : (String -> Svg.Attribute msg) -> number -> Svg.Attribute msg
num attr value =
    attr (toString value)
