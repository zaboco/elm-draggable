#!/usr/bin/env bash

function getVersion() {
    echo `cat elm.json | perl -n -e'/\"version\": \"(.+)\"/ && print $1'`
}

./smoke-test.sh
if [[ $? > 0 ]]; then
    echo "Smoke test failed. Not publishing."
    exit 1;
fi

OLD_VERSION=$(getVersion)

elm diff
elm bump

NEW_VERSION=$(getVersion)

if [[ $NEW_VERSION == $OLD_VERSION ]]; then
    echo "Version has not changed. Not publishing."
    exit 1;
fi

git add elm.json
git commit -m "bump to $NEW_VERSION"

git tag -a $NEW_VERSION -m "release version $NEW_VERSION"
git push origin $NEW_VERSION

elm publish
