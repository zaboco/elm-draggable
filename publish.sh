#!/usr/bin/env bash

function getVersion() {
    echo `cat elm-package.json | perl -n -e'/\"version\": \"(.+)\"/ && print $1'`
}

OLD_VERSION=$(getVersion)

elm package diff
elm package bump

NEW_VERSION=$(getVersion)

if [[ $NEW_VERSION == $OLD_VERSION ]]; then
    echo "Version has not changed. Not publishing."
    exit 1;
fi

git add elm-package.json
git commit -m "bump to $NEW_VERSION"

git tag -a $NEW_VERSION -m "release version $NEW_VERSION"
git push origin $NEW_VERSION

elm package publish


