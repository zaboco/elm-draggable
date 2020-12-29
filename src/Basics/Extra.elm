module Basics.Extra exposing
    ( compose2
    )

-- Allows post-composing functions to two parameter functions
compose2 : (c -> d) -> (a -> b -> c) -> (a -> b -> d)
compose2 = (<<) << (<<)
