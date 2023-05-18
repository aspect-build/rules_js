#!/usr/bin/env bash

readonly PUBLISH_A="$1"
readonly PUBLISH_B="$2"

$PUBLISH_A 2>&1 | grep 'npm notice package: @mycorp/pkg-b@'

if [ $? != 0 ]; then
    echo "FAIL: expected 'npm notice package: @mycorp/pkg-b@' error"
    exit 1
fi

$PUBLISH_B 2>&1 | grep 'npm ERR! enoent This is related to npm not being able to find a file.'

if [ $? != 0 ]; then
   echo "FAIL: expected 'npm ERR! enoent This is related to npm not being able to find a file.' error"
   exit 1
fi
