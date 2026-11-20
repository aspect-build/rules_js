#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"
tool=subdir/patch-tool.sh
output=bazel-bin/subdir/node_modules/@aspect-test/e/index.js

check_marker() {
    bazel build --remote_download_outputs=all //subdir:node_modules/@aspect-test/e
    if ! grep -Fxq "module.exports.PATCH_TOOL = $1" "$output"; then
        echo "Expected PATCH_TOOL = $1 in $output" >&2
        exit 1
    fi
}

# Editing only the tool must invalidate the previously patched package.
check_marker true
backup=$(mktemp)
cp "$tool" "$backup"
trap 'cat "$backup" >"$tool" && rm "$backup"' EXIT
sed 's/PATCH_TOOL = true/PATCH_TOOL = false/' "$backup" >"$tool"
check_marker false
