#!/usr/bin/env bash
set -o errexit -o nounset -o pipefail

# Integration test for use_home_npmrc

# sedi makes `sed -i` work on both OSX & Linux
# See https://stackoverflow.com/questions/2320564/i-need-my-sed-i-command-for-in-place-editing-to-work-with-both-gnu-sed-and-bsd
_sedi() {
    case $(uname) in
    Darwin*) sedi=('-i' '') ;;
    *) sedi=('-i') ;;
    esac

    sed "${sedi[@]}" "$@"
}

# Move the local .npmrc to ~/ and update MODULE.bazel to use_home_npmrc=True
cp -f .npmrc ~/.npmrc
rm .npmrc
_sedi 's#npmrc = "//:.npmrc",#use_home_npmrc = True,#' MODULE.bazel

# Have to make another change to package.json to invalidate the repository rule
_sedi 's#"@types/node": "22.18.13"#"@types/node": "22"#' package.json

# Allow updating the lockfile for this test
unset ASPECT_RULES_JS_FROZEN_PNPM_LOCK

# Trigger the update of the pnpm lockfile which should exit non-zero
if bazel run @npm//:sync; then
    echo "ERROR: expected 'update_pnpm_lock' to exit with non-zero exit code on update"
    exit 1
fi

if ! git status --porcelain | grep -q "\.aspect/rules/external_repository_action_cache/npm_translate_lock_"; then
    echo "ERROR: expected .aspect/rules/external_repository_action_cache/npm_translate_lock_* to be updated by sync"
    exit 1
fi
if ! git status --porcelain | grep -q "pnpm-lock.yaml"; then
    echo "ERROR: expected pnpm-lock.yaml to be updated by sync"
    exit 1
fi

# The lockfile has been updated and sync should now exit 0
if ! bazel run @npm//:sync; then
    echo "ERROR: expected 'update_pnpm_lock' to exit zero once the lockfile is up to date"
    exit 1
fi

export ASPECT_RULES_JS_FROZEN_PNPM_LOCK=1

bazel test //...
