#!/usr/bin/env bash
set -o errexit -o nounset -o pipefail -o xtrace

BZLMOD_FLAG="${BZLMOD_FLAG:---enable_bzlmod=1}"

# Change visibility to restricted (since bazel test //... already validated the public case works)
sed -i 's/"some-dep": \["\/\/visibility:public"\]/"some-dep": ["\/\/packages\/nonexistent:__subpackages__"]/' MODULE.bazel
sed -i 's/"some-dep": \["\/\/visibility:public"\]/"some-dep": ["\/\/packages\/nonexistent:__subpackages__"]/' WORKSPACE

# Clear Bazel cache to ensure new visibility is loaded
bazel clean --expunge 2>/dev/null || true

# Test that package_visibility restrictions are enforced for local node_modules references
build_output=$(bazel build "$BZLMOD_FLAG" //packages/from-local:from_local_lib 2>&1 || true)
if ! echo "$build_output" | grep -q "is not visible from"; then
    echo "ERROR: expected visibility error message 'is not visible from' but got:"
    echo "$build_output"
    exit 1
fi

echo "package_visibility enforcement test passed"
