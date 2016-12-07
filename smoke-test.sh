#!/usr/bin/env bash

status=0
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

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

if [ $status -eq 0 ]; then
    echo -e "${GREEN}SUCCESS!${NC}"
else
    echo -e "${RED}${status} ERRORS!${NC}"
fi


exit $status
