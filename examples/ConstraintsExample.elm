module ConstraintsExample exposing (..)

import Char
import Draggable exposing (onDragBy, onDragEnd, onDragStart)
import Draggable.Vector as Vector exposing (Vector, getX, getY)
import Html exposing (Html)
import Keyboard exposing (KeyCode)
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
    , dragHorizontally : Bool
    , dragVertically : Bool
    , isDragging : Bool
    }


type Msg
    = NoOp
    | DragMsg Draggable.Msg
    | OnDragBy Vector
    | SetDragHorizontally Bool
    | SetDragVertically Bool
    | SetDragging Bool


init : ( Model, Cmd Msg )
init =
    ( { position = Vector.init 100 100
      , drag = Draggable.init
      , dragHorizontally = True
      , dragVertically = True
      , isDragging = False
      }
    , Cmd.none
    )


dragConfig : Draggable.Config Msg
dragConfig =
    Draggable.customConfig
        [ onDragBy OnDragBy
        , onDragStart (SetDragging True)
        , onDragEnd (SetDragging False)
        ]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg ({ position, dragVertically, dragHorizontally } as model) =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        OnDragBy rawDelta ->
            let
                dx =
                    if dragVertically then
                        getX rawDelta
                    else
                        0

                dy =
                    if dragHorizontally then
                        getY rawDelta
                    else
                        0

                delta =
                    Vector.init dx dy
            in
                ( { model | position = Vector.add delta position }, Cmd.none )

        DragMsg dragMsg ->
            Draggable.update dragConfig dragMsg model

        SetDragHorizontally flag ->
            ( { model | dragHorizontally = flag }, Cmd.none )

        SetDragVertically flag ->
            ( { model | dragVertically = flag }, Cmd.none )

        SetDragging flag ->
            ( { model | isDragging = flag }, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions { drag } =
    Sub.batch
        [ Keyboard.downs (handleKey True)
        , Keyboard.ups (handleKey False)
        , Draggable.subscriptions DragMsg drag
        ]


handleKey : Bool -> Keyboard.KeyCode -> Msg
handleKey pressed code =
    case (Char.fromCode code) of
        'W' ->
            SetDragHorizontally (not pressed)

        'A' ->
            SetDragVertically (not pressed)

        _ ->
            NoOp



-- VIEW


type alias Size =
    { width : Float, height : Float }


sceneSize : Size
sceneSize =
    Size 9999 9999


boxSize : Size
boxSize =
    Size 60 60


view : Model -> Html Msg
view { position, dragHorizontally, dragVertically, isDragging } =
    let
        cursor =
            if isDragging then
                "none"
            else
                "default"
    in
        Svg.svg
            [ Attr.width "100%"
            , Attr.height "100%"
            , Attr.cursor cursor
            ]
            [ background
            , horizontalGuideline (getY position) dragVertically
            , verticalGuideline (getX position) dragHorizontally
            , box position isDragging
            ]


box : Vector -> Bool -> Svg Msg
box position isDragging =
    let
        { width, height } =
            boxSize

        ( x, y ) =
            ( getX position - width / 2
            , getY position - height / 2
            )

        cursor =
            if isDragging then
                "none"
            else
                "move"
    in
        Svg.rect
            [ num Attr.width boxSize.width
            , num Attr.height boxSize.height
            , num Attr.x x
            , num Attr.y y
            , Attr.cursor cursor
            , Attr.fill "red"
            , Draggable.triggerOnMouseDown DragMsg
            ]
            []


horizontalGuideline : Float -> Bool -> Svg Msg
horizontalGuideline y isEnabled =
    Svg.g [] <|
        [ Svg.text_
            [ num Attr.x 20
            , num Attr.y y
            , Attr.textAnchor "end"
            , Attr.alignmentBaseline "middle"
            ]
            [ Svg.text "A" ]
        , Svg.line
            (guidelineStyle isEnabled
                [ num Attr.x1 25
                , num Attr.x2 sceneSize.width
                , num Attr.y1 y
                , num Attr.y2 y
                ]
            )
            []
        ]


verticalGuideline : Float -> Bool -> Svg Msg
verticalGuideline x isEnabled =
    Svg.g [] <|
        [ Svg.text_
            [ num Attr.x x
            , num Attr.y 20
            , Attr.textAnchor "middle"
            ]
            [ Svg.text "W" ]
        , Svg.line
            ([ num Attr.x1 x
             , num Attr.x2 x
             , num Attr.y1 25
             , num Attr.y2 sceneSize.height
             ]
                |> guidelineStyle isEnabled
            )
            []
        ]


guidelineStyle : Bool -> List (Svg.Attribute msg) -> List (Svg.Attribute msg)
guidelineStyle isEnabled otherAttributes =
    let
        color =
            if isEnabled then
                "black"
            else
                "#ccc"

        attributes =
            [ Attr.stroke color
            , Attr.strokeDasharray "10, 10"
            ]
    in
        otherAttributes ++ attributes


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
