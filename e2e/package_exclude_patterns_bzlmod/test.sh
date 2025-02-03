#!/usr/bin/env bash
set -o errexit -o nounset -o pipefail

TARGET_DIR="bazel-bin/node_modules/is-odd"

# Check if the directory exists
if [[ ! -d "$TARGET_DIR" ]]; then
    echo "Error: Directory $TARGET_DIR does not exist."
    exit 1
fi

# Check if package.json exists
if [[ ! -f "$TARGET_DIR/package.json" ]]; then
    echo "Error: package.json not found in $TARGET_DIR."
    exit 1
fi

# Check if any README file exists
if ls "$TARGET_DIR"/README* >/dev/null 2>&1; then
    echo "Error: Unexpected README file found in $TARGET_DIR."
    exit 1
fi

echo "All tests passed"
