module MultipleTargetsExample exposing (main)

import Draggable exposing (DragEvent(..))
import Html exposing (Html)
import Html.Attributes
import Math.Vector2 as Vector2 exposing (Vec2, getX, getY)
import Svg exposing (Svg)
import Svg.Attributes as Attr
import Svg.Keyed
import Svg.Lazy exposing (lazy)


main : Program Never Model Msg
main =
    Html.program
        { init = ( model, Cmd.none )
        , update = \msg model -> ( update msg model, Cmd.none )
        , subscriptions = subscriptions
        , view = view
        }


type alias Box =
    { id : Id
    , position : Vec2
    , clicked : Bool
    }


type alias Id =
    String


box : Id -> Vec2 -> Box
box id position =
    Box id position False


dragBoxBy : Vec2 -> Box -> Box
dragBoxBy delta box =
    { box | position = box.position |> Vector2.add delta }


toggleClicked : Box -> Box
toggleClicked box =
    { box | clicked = not box.clicked }


type alias BoxGroup =
    { uid : Int
    , movingBox : Maybe Box
    , idleBoxes : List Box
    }


emptyGroup : BoxGroup
emptyGroup =
    BoxGroup 0 Nothing []


addBox : Vec2 -> BoxGroup -> BoxGroup
addBox position ({ uid, idleBoxes } as group) =
    { group
        | idleBoxes = (box (toString uid) position) :: idleBoxes
        , uid = uid + 1
    }


boxGroup : List Vec2 -> BoxGroup
boxGroup positions =
    positions
        |> List.foldl addBox emptyGroup


allBoxes : BoxGroup -> List Box
allBoxes { movingBox, idleBoxes } =
    movingBox
        |> Maybe.map (flip (::) idleBoxes)
        |> Maybe.withDefault idleBoxes


startDragging : Id -> BoxGroup -> BoxGroup
startDragging id ({ idleBoxes, movingBox } as group) =
    let
        ( targetAsList, others ) =
            List.partition (.id >> ((==) id)) idleBoxes
    in
        { group
            | idleBoxes = others
            , movingBox = targetAsList |> List.head
        }


stopDragging : BoxGroup -> BoxGroup
stopDragging group =
    { group
        | idleBoxes = allBoxes group
        , movingBox = Nothing
    }


dragActiveBy : Vec2 -> BoxGroup -> BoxGroup
dragActiveBy delta group =
    { group | movingBox = group.movingBox |> Maybe.map (dragBoxBy delta) }


toggleActive : BoxGroup -> BoxGroup
toggleActive group =
    { group | movingBox = group.movingBox |> Maybe.map toggleClicked }


type alias Model =
    { boxGroup : BoxGroup
    , drag : Draggable.State ()
    }


type Msg
    = StartDrag String (Draggable.State ())
    | UpdateDrag (Draggable.State ()) DragEvent


boxPositions : List Vec2
boxPositions =
    let
        indexToPosition =
            toFloat >> ((*) 60) >> ((+) 10) >> (Vector2.vec2 10)
    in
        List.range 0 10 |> List.map indexToPosition


model : Model
model =
    { boxGroup = boxGroup boxPositions
    , drag = Draggable.init
    }


updateOnDrag : DragEvent -> Model -> Model
updateOnDrag dragEvent ({ boxGroup } as model) =
    case dragEvent of
        DragBy delta ->
            { model | boxGroup = boxGroup |> dragActiveBy (Vector2.fromTuple delta) }

        Click ->
            { model | boxGroup = boxGroup |> toggleActive |> stopDragging }

        DragEnd ->
            { model | boxGroup = boxGroup |> stopDragging }

        _ ->
            model


update : Msg -> Model -> Model
update msg ({ boxGroup } as model) =
    case msg of
        StartDrag id drag ->
            { model
                | drag = drag
                , boxGroup = boxGroup |> startDragging id
            }

        UpdateDrag drag event ->
            { model | drag = drag }
                |> updateOnDrag event


subscriptions : Model -> Sub Msg
subscriptions { drag } =
    Draggable.subscriptions UpdateDrag drag



-- VIEW


boxSize : Vec2
boxSize =
    Vector2.vec2 50 50


view : Model -> Html Msg
view { boxGroup } =
    Html.div
        []
        [ Html.p
            [ Html.Attributes.style [ ( "padding-left", "8px" ) ] ]
            [ Html.text "Drag any box around. Click it to toggle its color." ]
        , Svg.svg
            [ Attr.style "height: 100vh; width: 100vw; position: fixed;"
            ]
            [ background
            , boxesView boxGroup
            ]
        ]


boxesView : BoxGroup -> Svg Msg
boxesView boxGroup =
    boxGroup
        |> allBoxes
        |> List.reverse
        |> List.map boxKeyedView
        |> Svg.Keyed.node "g" []


boxKeyedView : Box -> ( String, Svg Msg )
boxKeyedView box =
    ( box.id, lazy boxView box )


boxView : Box -> Svg Msg
boxView { id, position, clicked } =
    let
        color =
            if clicked then
                "red"
            else
                "lightblue"
    in
        Svg.rect
            [ num Attr.width <| getX boxSize
            , num Attr.height <| getY boxSize
            , num Attr.x (getX position)
            , num Attr.y (getY position)
            , Attr.fill color
            , Attr.stroke "black"
            , Attr.cursor "move"
            , Draggable.mouseTrigger () (StartDrag id)
            ]
            []


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
