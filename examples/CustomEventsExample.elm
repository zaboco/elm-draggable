module CustomEventsExample exposing (..)

import Html exposing (Html)
import Html.Attributes as A
import Draggable exposing (DragEvent(..))
import Html.Events


type alias Position =
    { x : Float
    , y : Float
    }


type alias Model =
    { xy : Position
    , clicksCount : Int
    , isDragging : Bool
    , isClicked : Bool
    , drag : Draggable.State String
    }


type Msg
    = StartDrag (Draggable.State String)
    | UpdateDrag (Draggable.State String) DragEvent
    | ReleaseButton


main : Program Never Model Msg
main =
    Html.program
        { init = ( model, Cmd.none )
        , update = \msg model -> ( update msg model, Cmd.none )
        , subscriptions = subscriptions
        , view = view
        }


model : Model
model =
    { xy = Position 32 32
    , drag = Draggable.init
    , clicksCount = 0
    , isDragging = False
    , isClicked = False
    }


update : Msg -> Model -> Model
update msg ({ xy } as model) =
    case msg of
        StartDrag drag ->
            { model | drag = drag, isClicked = True }

        UpdateDrag drag event ->
            { model | drag = drag }
                |> updateOnDrag event

        ReleaseButton ->
            { model | isClicked = False }


updateOnDrag : DragEvent -> Model -> Model
updateOnDrag dragEvent ({ xy } as model) =
    case dragEvent of
        DragBy ( dx, dy ) ->
            { model | xy = Position (xy.x + dx) (xy.y + dy) }

        DragStart ->
            { model | isDragging = True }

        DragEnd ->
            { model | isDragging = False }

        Click ->
            { model | clicksCount = model.clicksCount + 1 }


subscriptions : Model -> Sub Msg
subscriptions { drag } =
    Draggable.newSubscription UpdateDrag drag


view : Model -> Html Msg
view { xy, isDragging, isClicked, clicksCount } =
    let
        translate =
            "translate(" ++ (toString xy.x) ++ "px, " ++ (toString xy.y) ++ "px)"

        status =
            if isDragging then
                "Release me"
            else
                "Drag me"

        color =
            if isClicked then
                "limegreen"
            else
                "lightgray"

        style =
            [ "transform" => translate
            , "padding" => "16px"
            , "background-color" => color
            , "width" => "100px"
            , "text-align" => "center"
            , "cursor" => "move"
            ]
    in
        Html.div
            [ A.style style
            , Draggable.newMouseTrigger "" StartDrag
            , Html.Events.onMouseUp ReleaseButton
            ]
            [ Html.text status
            , Html.br [] []
            , Html.text <| (toString clicksCount) ++ " clicks"
            ]


(=>) : a -> b -> ( a, b )
(=>) =
    (,)
