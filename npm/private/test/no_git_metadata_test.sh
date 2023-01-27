#!/usr/bin/env bash
set -o errexit -o nounset -o pipefail

PACKAGE_DIR="$1"

if [ -d "$PACKAGE_DIR/.git" ]; then
    echo "Expected $PACKAGE_DIR/.git to have been deleted"
    exit 1
fi
