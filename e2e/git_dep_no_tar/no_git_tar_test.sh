#!/usr/bin/env bash
set -o errexit -o nounset -o pipefail

PACKAGE_DIR1="$1"

if [ ! -f "$PACKAGE_DIR1/package.json" ]; then
    echo "Expected $PACKAGE_DIR1/package.json to be present."
    exit 1
fi
