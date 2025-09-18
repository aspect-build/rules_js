#!/usr/bin/env bash
set -o errexit -o nounset -o pipefail -o xtrace

BZLMOD_FLAG="${BZLMOD_FLAG:---enable_bzlmod=1}"

# Test that package_visibility restrictions are enforced for local node_modules references
build_output=$(bazel build "$BZLMOD_FLAG" //packages/from-local:from_local_lib 2>&1 || true)
if ! echo "$build_output" | grep -q "is not visible from"; then
    echo "ERROR: expected visibility error message 'is not visible from' but got:"
    echo "$build_output"
    exit 1
fi

echo "package_visibility enforcement test passed"