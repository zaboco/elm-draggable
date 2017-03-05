module ConstraintsExample exposing (..)

import Char
import Draggable exposing (DragEvent(..))
import Html exposing (Html)
import Keyboard exposing (KeyCode)
import Svg exposing (Svg)
import Svg.Attributes as Attr


main : Program Never Model Msg
main =
    Html.program
        { init = ( model, Cmd.none )
        , update = \msg model -> ( update msg model, Cmd.none )
        , subscriptions = subscriptions
        , view = view
        }


type alias Position =
    { x : Float
    , y : Float
    }


type alias Model =
    { position : Position
    , drag : Draggable.State String
    , dragHorizontally : Bool
    , dragVertically : Bool
    , isDragging : Bool
    }


type Msg
    = NoOp
    | StartDrag (Draggable.State String)
    | UpdateDrag (Draggable.State String) DragEvent
    | SetDragHorizontally Bool
    | SetDragVertically Bool


model : Model
model =
    { position = Position 100 100
    , drag = Draggable.init
    , dragHorizontally = True
    , dragVertically = True
    , isDragging = False
    }


update : Msg -> Model -> Model
update msg model =
    case msg of
        NoOp ->
            model

        StartDrag drag ->
            { model | drag = drag }

        UpdateDrag drag event ->
            { model | drag = drag }
                |> updateOnDrag event

        SetDragHorizontally flag ->
            { model | dragHorizontally = flag }

        SetDragVertically flag ->
            { model | dragVertically = flag }


updateOnDrag : DragEvent -> Model -> Model
updateOnDrag dragEvent ({ position, dragVertically, dragHorizontally } as model) =
    case dragEvent of
        DragBy ( dx, dy ) ->
            let
                ( fx, fy ) =
                    ( boolToNumber dragHorizontally
                    , boolToNumber dragVertically
                    )

                newPosition =
                    Position
                        (position.x + dx * fx)
                        (position.y + dy * fy)
            in
                { model | position = newPosition }

        DragStart ->
            { model | isDragging = True }

        DragEnd ->
            { model | isDragging = False }

        _ ->
            model


boolToNumber : Bool -> number
boolToNumber bool =
    if bool then
        1
    else
        0


subscriptions : Model -> Sub Msg
subscriptions { drag } =
    Sub.batch
        [ Keyboard.downs (handleKey True)
        , Keyboard.ups (handleKey False)
        , Draggable.subscriptions UpdateDrag drag
        ]


handleKey : Bool -> Keyboard.KeyCode -> Msg
handleKey pressed code =
    case (Char.fromCode code) of
        'A' ->
            SetDragHorizontally (not pressed)

        'W' ->
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
            [ Attr.cursor cursor
            , Attr.style "height: 100vh; width: 100vw;"
            ]
            [ background
            , verticalGuideline position.x dragVertically
            , horizontalGuideline position.y dragHorizontally
            , box position isDragging
            ]


box : Position -> Bool -> Svg Msg
box position isDragging =
    let
        { width, height } =
            boxSize

        ( x, y ) =
            ( position.x - width / 2
            , position.y - height / 2
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
            , Draggable.mouseTrigger "" StartDrag
            ]
            []


horizontalGuideline : number -> Bool -> Svg Msg
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


verticalGuideline : number -> Bool -> Svg Msg
verticalGuideline x isEnabled =
    Svg.g [] <|
        [ Svg.text_
            [ num Attr.x x
            , num Attr.y 20
            , Attr.textAnchor "middle"
            ]
            [ Svg.text "W" ]
        , Svg.line
            (guidelineStyle isEnabled
                [ num Attr.x1 x
                , num Attr.x2 x
                , num Attr.y1 25
                , num Attr.y2 sceneSize.height
                ]
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
