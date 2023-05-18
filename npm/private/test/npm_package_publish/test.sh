#!/usr/bin/env bash

readonly PUBLISH_A="$1"
readonly PUBLISH_B="$2"

$PUBLISH_A | grep 'ERR_PNPM_PACKAGE_VERSION_NOT_FOUND  Package version is not defined in the package.json.'

if [ $? != 0 ]; then
    echo "FAIL: expected ERR_PNPM_PACKAGE_VERSION_NOT_FOUND  error"
    exit 1
fi

$PUBLISH_B | grep 'ERR_PNPM_NO_IMPORTER_MANIFEST_FOUND  No package.json (or package.yaml, or package.json5) was found in '

if [ $? != 0 ]; then
   echo "FAIL: expected ERR_PNPM_NO_IMPORTER_MANIFEST_FOUND  error"
   exit 1
fi
