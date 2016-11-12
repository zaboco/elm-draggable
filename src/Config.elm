module Config exposing (Config(..))

import Internal


type Config msg
    = Config (Internal.Config msg)
