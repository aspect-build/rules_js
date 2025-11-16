#!/usr/bin/env bash
set -o errexit -o nounset -o pipefail

# E2E: Ensure js_binary launcher resolves workspace-relative JS_BINARY__CHDIR correctly
# when run from another workspace via @module syntax.

BZLMOD_FLAG="${BZLMOD_FLAG:---enable_bzlmod=1}"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

# Run inside the subject workspace
echo "Running js_binary inside sub workspace..."
pushd workspace >/dev/null
bazel run "$BZLMOD_FLAG" -- //:bin
popd >/dev/null
echo "OK: inside run succeeded"

# Run from outside via @module reference
echo "Running js_binary from consumer workspace (@js_binary_workspace)..."
bazel run "$BZLMOD_FLAG" -- @workspace//:bin
echo "OK: external run succeeded"
