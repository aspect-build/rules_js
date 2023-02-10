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

print_step() {
  printf "\n\n+----------------------------------------------------------------------+"
  # shellcheck disable=SC2059,SC2145
  printf "\n  $@"
  printf "\n+----------------------------------------------------------------------+\n"
}

BZLMOD_FLAG="${BZLMOD_FLAG:-}"

print_step "It should initially pass"
# shellcheck disable=SC2086
if ! bazel test $BZLMOD_FLAG //...; then
  echo "ERROR: expected 'bazel test $BZLMOD_FLAG //...' to pass"
  exit 1
fi

print_step "It should fail a bazel test run after updating a dependency when ASPECT_RULES_JS_FROZEN_PNPM_LOCK=1"

diff="$(git diff .)"
if [ "$diff" ]; then
  echo "ERROR: expected 'git diff .' to be empty"
  exit 1
fi

_sedi 's#"@types/node": "18.11.18"#"@types/node": "16"#' package.json

export ASPECT_RULES_JS_FROZEN_PNPM_LOCK=1

# shellcheck disable=SC2086
if bazel test $BZLMOD_FLAG //...; then
  echo "ERROR: expected 'ASPECT_RULES_JS_FROZEN_PNPM_LOCK=1 bazel test $BZLMOD_FLAG //...' to fail"
  exit 1
fi

ASPECT_RULES_JS_FROZEN_PNPM_LOCK=

print_step "It should update the lockfile after a running the invalide target with ASPECT_RULES_JS_FROZEN_PNPM_LOCK unset"
# shellcheck disable=SC2086
if ! bazel run $BZLMOD_FLAG @npm//:sync; then
  echo "ERROR: expected 'bazel run $BZLMOD_FLAG @npm//:sync' to pass"
  exit 1
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

print_step "It should pass a bazel test run"

# shellcheck disable=SC2086
if ! bazel test $BZLMOD_FLAG //...; then
  echo "ERROR: expected 'bazel test $BZLMOD_FLAG //...' to pass"
  exit 1
fi

print_step "It should bootstrap the lockfile when pnpm_lock is missing"

rm pnpm-lock.yaml

# shellcheck disable=SC2086
if [ ! $BZLMOD_FLAG ]; then
  _sedi 's#pnpm_lock = "//:pnpm-lock.yaml"#\# pnpm_lock = "//:pnpm-lock.yaml"#' WORKSPACE
else
  _sedi 's#pnpm_lock = "//:pnpm-lock.yaml"#\# pnpm_lock = "//:pnpm-lock.yaml"#' MODULE.bazel
fi

# shellcheck disable=SC2086
if bazel test $BZLMOD_FLAG //...; then
  echo "ERROR: expected 'bazel test $BZLMOD_FLAG //...' to fail"
  exit 1
fi

if [ ! -e pnpm-lock.yaml ]; then
  echo "ERROR: expected the pnpm-lock.yaml file to have been boostraped by npm_translate_lock"
  exit 1
fi

# Under WORKSPACE, the `pnpm_lock` attribute does not need to be restored at this point
# as the @//:pnpm-lock.yaml label can be implicitly used. However, under bzlmod it must be
# restored due to the module extension needing to explicitly parse the the pnpm lockfile.
# By the time the read occurs the bootstrapping logic will not have executed so the file
# doesn't exist.
# shellcheck disable=SC2086
if [ $BZLMOD_FLAG ]; then
  _sedi 's#\# pnpm_lock = "//:pnpm-lock.yaml"#pnpm_lock = "//:pnpm-lock.yaml"#' MODULE.bazel
fi

print_step "It should pass a test after the lockfile has been bootstrapped"

# shellcheck disable=SC2086
if ! bazel test $BZLMOD_FLAG //...; then
  echo "ERROR: expected 'bazel test $BZLMOD_FLAG //...' to pass"
  exit 1
fi

echo "All tests passed"
