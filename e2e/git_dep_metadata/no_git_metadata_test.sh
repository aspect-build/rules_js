#!/usr/bin/env bash
set -o errexit -o nounset -o pipefail

PACKAGE_DIR1="$1"
PACKAGE_DIR2="$2"

if [ -d "$PACKAGE_DIR1/.git" ]; then
    echo "Expected $PACKAGE_DIR1/.git to have been deleted"
    exit 1
fi

if [ -d "$PACKAGE_DIR2/.git" ]; then
    echo "Expected $PACKAGE_DIR2/.git to have been deleted"
    exit 1
fi
