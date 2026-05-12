#!/usr/bin/env bash
set -o errexit -o nounset -o pipefail

# --- begin runfiles.bash initialization v3 ---
# Copy-pasted from the Bazel Bash runfiles library v3.
set -uo pipefail; set +e; f=bazel_tools/tools/bash/runfiles/runfiles.bash
# shellcheck disable=SC1090
source "${RUNFILES_DIR:-/dev/null}/$f" 2>/dev/null || \
  source "$(grep -sm1 "^$f " "${RUNFILES_MANIFEST_FILE:-/dev/null}" | cut -f2- -d' ')" 2>/dev/null || \
  source "$0.runfiles/$f" 2>/dev/null || \
  source "$(grep -sm1 "^$f " "$0.runfiles_manifest" | cut -f2- -d' ')" 2>/dev/null || \
  source "$(grep -sm1 "^$f " "$0.exe.runfiles_manifest" | cut -f2- -d' ')" 2>/dev/null || \
  { echo>&2 "ERROR: cannot find $f"; exit 1; }; f=; set -e
# --- end runfiles.bash initialization v3 ---

HELLO=$(rlocation "pnpm_patched/package/hello.txt")

if [ ! -f "${HELLO}" ]; then
    echo "ERROR: expected hello.txt to exist at ${HELLO}"
    exit 1
fi

CONTENT=$(cat "${HELLO}")
if [ "${CONTENT}" != "hello" ]; then
    echo "ERROR: expected content 'hello', got '${CONTENT}'"
    exit 1
fi

echo "PASS: pnpm patch applied successfully"
