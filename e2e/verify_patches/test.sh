#!/usr/bin/env bash
set -o errexit -o nounset -o pipefail

print_step() {
  printf "\n\n+----------------------------------------------------------------------+"
  # shellcheck disable=SC2059,SC2145
  printf "\n  $@"
  printf "\n+----------------------------------------------------------------------+\n"
}

# sedi makes `sed -i` work on both OSX & Linux
# See https://stackoverflow.com/questions/2320564/i-need-my-sed-i-command-for-in-place-editing-to-work-with-both-gnu-sed-and-bsd
_sedi () {
  case $(uname) in
    Darwin*) sedi=('-i' '') ;;
    *) sedi=('-i') ;;
  esac

  sed "${sedi[@]}" "$@"
}


BZLMOD_FLAG="${BZLMOD_FLAG:-}"

print_step "Should initially succeed"
# shellcheck disable=SC2086
if ! bazel build $BZLMOD_FLAG //...; then
  # shellcheck disable=SC2059
  printf "ERROR: expected 'bazel build $BZLMOD_FLAG //...' to pass"
  exit 1
fi

print_step "Should pass the generated patch list test when adding an excluded patch format"
touch patches/foo.diff
# shellcheck disable=SC2086
if ! bazel test $BZLMOD_FLAG //patches:patches_update_test; then
  # shellcheck disable=SC2059
  printf "ERROR: expected 'bazel test $BZLMOD_FLAG //patches:patches_update_test' to pass"
  exit 1
fi
rm patches/foo.diff

print_step "Should fail the generated patch list test when adding a new patch"

patch="diff --git a/main.js b/main.js
index bdc8c4e..4f9c0fb 100755
--- a/main.js
+++ b/main.js
@@ -1,4 +1,5 @@
 const testA = require('@gregmagolan/test-a');
 console.log(\"Hello world!\")
+console.log(\"foobar\")"
echo "$patch" > patches/foo.patch

# shellcheck disable=SC2086
if bazel test $BZLMOD_FLAG //patches:patches_update_test; then
  # shellcheck disable=SC2059
  printf "ERROR: expected 'bazel test $BZLMOD_FLAG //patches:patches_update_test' to fail"
  exit 1
fi

print_step "Should succeed running the patches update target"
# shellcheck disable=SC2086
if ! bazel run $BZLMOD_FLAG //patches:patches_update; then
  # shellcheck disable=SC2059
  printf "ERROR: expected 'bazel run $BZLMOD_FLAG //patches:patches_update' to pass"
  exit 1
fi

print_step "Should fail the build because the new patch isn't in 'patches'"
# shellcheck disable=SC2086
if bazel build $BZLMOD_FLAG //...; then
  # shellcheck disable=SC2059
  printf "ERROR: expected 'bazel build $BZLMOD_FLAG //...' to fail"
  exit 1
fi

print_step "Should pass the build after adding the new patch to 'patches'"
# shellcheck disable=SC2086
if [ $BZLMOD_FLAG ]; then
  _sedi 's#"//:patches/test-b.patch"#"//:patches/test-b.patch", "//:patches/foo.patch"#' MODULE.bazel
else
  _sedi 's#"//:patches/test-b.patch"#"//:patches/test-b.patch", "//:patches/foo.patch"#' WORKSPACE
fi

# shellcheck disable=SC2086
if ! bazel build $BZLMOD_FLAG //...; then
  # shellcheck disable=SC2059
  printf "ERROR: expected 'bazel build $BZLMOD_FLAG //...' to pass"
  exit 1
fi

print_step "Should succeed the generated patch list test"

# shellcheck disable=SC2086
if ! bazel test $BZLMOD_FLAG //patches:patches_update_test; then
  # shellcheck disable=SC2059
  printf "ERROR: expected 'bazel test $BZLMOD_FLAG //patches:patches_update_test' to pass"
  exit 1
fi

print_step "All tests passed"

