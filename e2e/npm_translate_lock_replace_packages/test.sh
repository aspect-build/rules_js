#!/usr/bin/env bash
set -o errexit -o nounset -o pipefail

BZLMOD_FLAG="${BZLMOD_FLAG:---enable_bzlmod=1}"

print_step() {
    printf "\n\n+----------------------------------------------------------------------+"
    # shellcheck disable=SC2059,SC2145
    printf "\n  $@"
    printf "\n+----------------------------------------------------------------------+\n"
}

# sedi makes `sed -i` work on both OSX & Linux
# See https://stackoverflow.com/questions/2320564/i-need-my-sed-i-command-for-in-place-editing-to-work-with-both-gnu-sed-and-bsd
_sedi() {
    case $(uname) in
    Darwin*) sedi=('-i' '') ;;
    *) sedi=('-i') ;;
    esac

    sed "${sedi[@]}" "$@"
}

print_step "Should fail when non-root module uses npm_replace_package"

# Add npm_replace_package to the non-root utils_module
_sedi '/use_repo(npm_utils, "npm_utils")/i\
npm_utils.npm_replace_package(\
    package = "lodash@4.17.21",\
    replacement = "@lodash_replacement_module//:lodash_replacement",\
)' utils_module/MODULE.bazel

# Build should fail with the expected error
output=$(bazel build "$BZLMOD_FLAG" //... 2>&1) || true

if echo "$output" | grep -q 'The "npm.npm_replace_package" tag can only be used in the root Bazel module'; then
    echo "SUCCESS: Got expected error about npm_replace_package in non-root module"
else
    echo "ERROR: Expected error message about npm_replace_package not found"
    echo "Output was:"
    echo "$output"
    git checkout utils_module/MODULE.bazel
    exit 1
fi

# Restore the original file
git checkout utils_module/MODULE.bazel

print_step "All tests passed"
