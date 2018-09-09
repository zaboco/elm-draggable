#!/usr/bin/env bash

ELM_MAKE='elm make'

cd examples/
$ELM_MAKE BasicExample.elm --output ../basic.html
$ELM_MAKE CustomEventsExample.elm --output ../custom.html
$ELM_MAKE ConstraintsExample.elm --output ../constraints.html
$ELM_MAKE PanAndZoomExample.elm --output ../pan-and-zoom.html
$ELM_MAKE MultipleTargetsExample.elm --output ../multiple.html
