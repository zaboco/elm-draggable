#!/usr/bin/env bash

cd examples/
elm-make BasicExample.elm --output ../basic.html
elm-make CustomEventsExample.elm --output ../custom.html
elm-make ConstraintsExample.elm --output ../constraints.js
elm-make PanAndZoomExample.elm --output ../pan-and-zoom.html
elm-make MultipleTargetsExample.elm --output ../multiple.html
