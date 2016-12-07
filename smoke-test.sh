#!/usr/bin/env bash

status=0

echo Compiling main library
echo ======================

elm-make --warn --yes --docs documentation.json
((status+=$?))

echo
echo Compiling examples
echo ======================

cd examples
for f in *.elm; do
    echo "$f:"
    elm-make --warn --yes $f
    ((status+=$?))
    echo
done

exit $status
