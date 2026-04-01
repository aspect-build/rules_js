#!/usr/bin/env bash

readonly PUBLISH_A="$1"
readonly PUBLISH_B="$2"

# assert that it prints package name from package.json to stderr,
# to ensure package directory is properly passed and npm can read it.
$PUBLISH_A 2>pub_a.log

cat pub_a.log | grep 'npm notice package: @mycorp/pkg-to-publish@'

# shellcheck disable=SC2181
if [ $? != 0 ]; then
    echo "FAIL: expected 'npm notice package: @mycorp/pkg-to-publish@' error, GOT: $(cat pub_a.log)"
    exit 1
fi

# asserting that npm_package has no package.json in it's srcs and we fail correctly.
# npm publish requires a package.json in the root of the package directory.
$PUBLISH_B 2>pub_b.log

cat pub_b.log | grep 'npm error enoent Could not read package.json:'

# shellcheck disable=SC2181
if [ $? != 0 ]; then
    echo "FAIL: expected 'npm error enoent Could not read package.json:' error, GOT: $(cat pub_b.log)"
    exit 1
fi
