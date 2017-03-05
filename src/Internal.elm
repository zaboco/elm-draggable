module Internal exposing (..)

import Mouse exposing (Position)


type State a
    = NotDragging
    | DraggingTentative a Position
    | Dragging Position


type alias Delta =
    ( Float, Float )



-- utility


distanceTo : Position -> Position -> Delta
distanceTo end start =
    ( toFloat (end.x - start.x)
    , toFloat (end.y - start.y)
    )



{-
   logInvalidState drag msg result =
       let
           str =
               String.join ""
                   [ "Invalid drag state: "
                   , toString drag
                   , ": "
                   , toString msg
                   ]

           _ =
               Debug.log str
       in
           result
-}
