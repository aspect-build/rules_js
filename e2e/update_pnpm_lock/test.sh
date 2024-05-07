#!/usr/bin/env bash
set -o errexit -o nounset -o pipefail -o xtrace

BZLMOD_FLAG="${BZLMOD_FLAG:---enable_bzlmod=1}"

# sedi makes `sed -i` work on both OSX & Linux
# See https://stackoverflow.com/questions/2320564/i-need-my-sed-i-command-for-in-place-editing-to-work-with-both-gnu-sed-and-bsd
_sedi() {
    case $(uname) in
    Darwin*) sedi=('-i' '') ;;
    *) sedi=('-i') ;;
    esac

    sed "${sedi[@]}" "$@"
}

if ! bazel test "$BZLMOD_FLAG" //...; then
    echo "ERROR: expected 'bazel test $BZLMOD_FLAG //...' to pass"
    exit 1
fi

diff="$(git diff .)"
if [ "$diff" ]; then
    echo "ERROR: expected 'git diff .' to be empty"
    exit 1
fi

_sedi 's#"@types/node": "18.11.18"#"@types/node": "16"#' package.json

export ASPECT_RULES_JS_FROZEN_PNPM_LOCK=1

if bazel test "$BZLMOD_FLAG" //...; then
    echo "ERROR: expected 'ASPECT_RULES_JS_FROZEN_PNPM_LOCK=1 bazel test $BZLMOD_FLAG //...' to fail"
    exit 1
fi

export ASPECT_RULES_JS_DISABLE_UPDATE_PNPM_LOCK=1

if ! bazel test "$BZLMOD_FLAG" //...; then
    echo "ERROR: expected 'ASPECT_RULES_JS_DISABLE_UPDATE_PNPM_LOCK=1 bazel test $BZLMOD_FLAG //...' to pass"
    exit 1
fi

diff="$(git diff pnpm-lock.yaml)"
if [ "$diff" ]; then
    echo "ERROR: expected 'git diff pnpm-lock.yaml' to be empty"
    exit 1
fi

ASPECT_RULES_JS_FROZEN_PNPM_LOCK=
ASPECT_RULES_JS_DISABLE_UPDATE_PNPM_LOCK=

# Have to make another change to package.json to invalidate the repository rule
_sedi 's#"@types/node": "16"#"@types/node": "14"#' package.json

# Trigger the update of the pnpm lockfile which should exit non-zero
if bazel run "$BZLMOD_FLAG" @npm//:sync; then
    echo "ERROR: expected 'update_pnpm_lock' to exit with non-zero exit code on update"
    exit 1
fi

# The lockfile should be updated
diff="$(git diff pnpm-lock.yaml)"
if [ -z "$diff" ]; then
    echo "ERROR: expected 'git diff pnpm-lock.yaml' to not be empty"
    exit 1
fi

# The action cache file should be updated
action_cache_file=".aspect/external_repository_action_cache/npm_translate_lock_LTE4Nzc1MDcwNjU="
diff="$(git diff "$action_cache_file")"
if [ -z "$diff" ]; then
    echo "ERROR: expected 'git diff $action_cache_file' to not be empty"
    exit 1
fi

# The lockfile has been updated and sync should now exit 0
if ! bazel run "$BZLMOD_FLAG" @npm//:sync; then
    echo "ERROR: expected 'update_pnpm_lock' to exit zero once the lockfile is up to date"
    exit 1
fi

if ! bazel test "$BZLMOD_FLAG" //...; then
    echo "ERROR: expected 'bazel test $BZLMOD_FLAG //...' to pass"
    exit 1
fi

echo "All tests passed"
