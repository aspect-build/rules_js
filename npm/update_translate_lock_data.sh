#!/usr/bin/env bash
# This script asks pnpm for the list of workspace packages, then updates the data[] attribute of
# the /WORKSPACE file to list them all.
#
# --- begin runfiles.bash initialization v2 ---
# Copy-pasted from the Bazel Bash runfiles library v2.
set -uo pipefail; set +e; f=bazel_tools/tools/bash/runfiles/runfiles.bash
# shellcheck source=/dev/null
source "${RUNFILES_DIR:-/dev/null}/$f" 2>/dev/null || \
    source "$(grep -sm1 "^$f " "${RUNFILES_MANIFEST_FILE:-/dev/null}" | cut -f2- -d' ')" 2>/dev/null || \
    source "$0.runfiles/$f" 2>/dev/null || \
    source "$(grep -sm1 "^$f " "$0.runfiles_manifest" | cut -f2- -d' ')" 2>/dev/null || \
    source "$(grep -sm1 "^$f " "$0.exe.runfiles_manifest" | cut -f2- -d' ')" 2>/dev/null || \
    { echo>&2 "ERROR: cannot find $f"; exit 1; }; f=; set -e
# --- end runfiles.bash initialization v2 ---

# We always start from the workspace root
cd "$BUILD_WORKSPACE_DIRECTORY"
# User provides the subdirectory of their bazel workspace where the pnpm workspace is rooted
dir=${1:-.}

if [[ ! -d "$dir" ]]; then
    echo >&2 "ERROR: argument $dir is not a directory in the Bazel workspace root $BUILD_WORKSPACE_DIRECTORY"
    exit 1
fi
cd "$dir"

if [[ ! -e "pnpm-workspace.yaml" ]]; then
    echo >&2 "ERROR: pnpm-workspace.yaml not found in $(pwd)"
    echo >&2 "If your pnpm workspace is rooted in a subfolder of your Bazel workspace, provide that folder as an argument, e.g."
    echo >&2 "  bazel run @aspect_rules_js//npm:update_translate_lock_data frontend"
    exit 1
fi

echo >&2 "Finding packages in the pnpm workspace rooted at $(pwd)"

pnpm_location="pnpm/pnpm.sh"
pnpm="$(rlocation "${pnpm_location}")" \
    || (echo >&2 "ERROR: Failed to locate ${pnpm_location}" && exit 1)
echo >&2 "Paste this snippet into your 'npm_translate_lock()':"
echo "    data = ["
for folder in $(BAZEL_BINDIR=. "$pnpm" recursive ls --depth -1 --porcelain); do
    json="${folder#"$PWD"}:package.json"
    echo "        \"//${json#/}\","
done
echo "    ]"
