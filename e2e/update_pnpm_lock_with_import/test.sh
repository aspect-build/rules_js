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

if ! bazel test //...; then
  echo "ERROR: expected 'bazel test //...' to pass"
  exit 1
fi

diff="$(git diff .)"
if [ "$diff" ]; then
  echo "ERROR: expected 'git diff .' to be empty"
  exit 1
fi

_sedi 's#"@types/node": "18.11.11"#"@types/node": "16"#' package.json

export ASPECT_RULES_JS_FROZEN_PNPM_LOCK=1

if bazel test //...; then
  echo "ERROR: expected 'ASPECT_RULES_JS_FROZEN_PNPM_LOCK=1 bazel test //...' to fail"
  exit 1
fi

ASPECT_RULES_JS_FROZEN_PNPM_LOCK=

if ! bazel sync --only=npm; then
  echo "ERROR: expected 'bazel sync --only=npm' to pass"
  exit 1
fi

diff="$(git diff pnpm-lock.yaml)"
if [ -z "$diff" ]; then
  echo "ERROR: expected 'git diff pnpm-lock.yaml' to not be empty"
  exit 1
fi

action_cache_file=".aspect/rules/external_repository_action_cache/npm_translate_lock_NDg3NzUwNzA2NQ=="
diff="$(git diff "$action_cache_file")"
if [ -z "$diff" ]; then
  echo "ERROR: expected 'git diff $action_cache_file' to not be empty"
  exit 1
fi

if ! bazel test //...; then
  echo "ERROR: expected 'bazel test //...' to pass"
  exit 1
fi

# test bootstrapping code path
rm pnpm-lock.yaml
_sedi 's#pnpm_lock = "//:pnpm-lock.yaml"#\# pnpm_lock = "//:pnpm-lock.yaml"#' WORKSPACE

if bazel test //...; then
  echo "ERROR: expected 'bazel test //...' to fail"
  exit 1
fi

if [ ! -e pnpm-lock.yaml ]; then
  echo "ERROR: expected the pnpm-lock.yaml file to have been boostraped by npm_translate_lock"
  exit 1
fi

if ! bazel test //...; then
  echo "ERROR: expected 'bazel test //...' to pass"
  exit 1
fi

echo "All tests passed"
