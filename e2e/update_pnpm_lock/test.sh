#!/usr/bin/env bash
set -o errexit -o nounset -o pipefail

# sedi makes `sed -i` work on both OSX & Linux
# See https://stackoverflow.com/questions/2320564/i-need-my-sed-i-command-for-in-place-editing-to-work-with-both-gnu-sed-and-bsd
_sedi () {
  case $(uname) in
    Darwin*) sedi=('-i' '') ;;
    *) sedi=('-i') ;;
  esac

  sed "${sedi[@]}" "$@"
}

if ! bazel test $BZLMOD_FLAG //...; then
  echo "ERROR: expected 'bazel test //...' to pass"
  exit 1
fi

diff="$(git diff .)"
if [ "$diff" ]; then
  echo "ERROR: expected 'git diff .' to be empty"
  exit 1
fi

_sedi 's#"@types/node": "18.11.18"#"@types/node": "16"#' package.json

export ASPECT_RULES_JS_FROZEN_PNPM_LOCK=1

if bazel test $BZLMOD_FLAG //...; then
  echo "ERROR: expected 'ASPECT_RULES_JS_FROZEN_PNPM_LOCK=1 bazel test //...' to fail"
  exit 1
fi

ASPECT_RULES_JS_FROZEN_PNPM_LOCK=

# Trigger the update of the pnpm lockfile
if [ ! $BZLMOD_FLAG ]; then
  if ! bazel sync $BZLMOD_FLAG --only=npm; then
    echo "ERROR: expected 'bazel sync' to pass"
    exit 1
  fi
else
  # bazel sync isn't load bearing under bzlmod.
  # Intead, run a build to trigger updating the lockfile.
  if bazel build $BZLMOD_FLAG //...; then
    echo "ERROR: expected 'bazel build //...' to fail"
    exit 1
  fi
fi


diff="$(git diff pnpm-lock.yaml)"
if [ -z "$diff" ]; then
  echo "ERROR: expected 'git diff pnpm-lock.yaml' to not be empty"
  exit 1
fi

action_cache_file=".aspect/rules/external_repository_action_cache/npm_translate_lock_LTE4Nzc1MDcwNjU="
diff="$(git diff "$action_cache_file")"
if [ -z "$diff" ]; then
  echo "ERROR: expected 'git diff $action_cache_file' to not be empty"
  exit 1
fi

if ! bazel test $BZLMOD_FLAG //...; then
  echo "ERROR: expected 'bazel test //...' to pass"
  exit 1
fi

echo "All tests passed"
