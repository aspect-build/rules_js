#!/usr/bin/env bash
set -o errexit -o nounset -o pipefail

cp "$1" "$BUILD_WORKSPACE_DIRECTORY/$2"
