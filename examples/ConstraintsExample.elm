module ConstraintsExample exposing (main)

import Browser
import Browser.Events
import Char
import Draggable
import Draggable.Events exposing (onDragBy, onDragEnd, onDragStart)
import Html exposing (Html)
import Json.Decode as D exposing (Decoder)
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
    | DragMsg (Draggable.Msg String)
    | OnDragBy Draggable.Delta
    | SetDragHorizontally Bool
    | SetDragVertically Bool
    | SetDragging Bool


init : flags -> ( Model, Cmd Msg )
init _ =
    ( { position = Position 100 100
      , drag = Draggable.init
      , dragHorizontally = True
      , dragVertically = True
      , isDragging = False
      }
    , Cmd.none
    )


dragConfig : Draggable.Config String Msg
dragConfig =
    Draggable.customConfig
        [ onDragBy OnDragBy
        , onDragStart (\_ -> SetDragging True)
        , onDragEnd (SetDragging False)
        ]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg ({ position, dragVertically, dragHorizontally } as model) =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        OnDragBy ( dx, dy ) ->
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
            ( { model | position = newPosition }, Cmd.none )

        DragMsg dragMsg ->
            Draggable.update dragConfig dragMsg model

        SetDragHorizontally flag ->
            ( { model | dragHorizontally = flag }, Cmd.none )

        SetDragVertically flag ->
            ( { model | dragVertically = flag }, Cmd.none )

        SetDragging flag ->
            ( { model | isDragging = flag }, Cmd.none )


boolToNumber : Bool -> Float
boolToNumber bool =
    if bool then
        1

    else
        0


subscriptions : Model -> Sub Msg
subscriptions { drag, dragHorizontally, dragVertically } =
    let
        decoder : Bool -> Decoder Msg
        decoder preventDragging =
            keyDecoder
                |> D.andThen
                    (\key ->
                        case key of
                            "a" ->
                                if dragHorizontally == preventDragging then
                                    D.succeed <| SetDragHorizontally (not preventDragging)

                                else
                                    D.fail "No need to handle key"

                            "w" ->
                                if dragVertically == preventDragging then
                                    D.succeed <| SetDragVertically (not preventDragging)

                                else
                                    D.fail "No need to handle key"

                            _ ->
                                D.fail "Ignoring key"
                    )

        handleKey : Bool -> String -> Msg
        handleKey pressed code =
            case code of
                "a" ->
                    if dragHorizontally == pressed then
                        SetDragHorizontally (not pressed)

                    else
                        NoOp

                "w" ->
                    if dragVertically == pressed then
                        SetDragVertically (not pressed)

                    else
                        NoOp

                _ ->
                    NoOp
    in
    Sub.batch
        [ Browser.Events.onKeyDown <| decoder True
        , Browser.Events.onKeyUp <| decoder False
        , Draggable.subscriptions DragMsg drag
        ]


keyDecoder : Decoder String
keyDecoder =
    D.field "key" D.string



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
        , Draggable.mouseTrigger "" DragMsg
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


num : (String -> Svg.Attribute msg) -> Float -> Svg.Attribute msg
num attr value =
    attr (String.fromFloat value)
