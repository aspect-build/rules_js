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

BZLMOD_FLAG="${BZLMOD_FLAG:-}"

# Verify patches should initially succeed
if ! bazel build $BZLMOD_FLAG //...; then
  echo "ERROR: expected 'bazel build $BZLMOD_FLAG //...' to pass"
  exit 1
fi

# Should succeed after adding an ignored patch extension
touch patches/foo.diff
if ! bazel build $BZLMOD_FLAG //...; then
  echo "ERROR: expected 'bazel build $BZLMOD_FLAG //...' to pass"
  exit 1
fi
rm patches/foo.diff

# Should fail after adding a patch that isn't in `patches`
bazel clean --expunge # Need to invalidate the repository cache to see the missing file
touch patches/foo.patch
if bazel build $BZLMOD_FLAG //...; then
  echo "ERROR: expected 'bazel build $BZLMOD_FLAG //...' to fail"
  exit 1
fi
rm patches/foo.patch

# Remove one of the patches
if [ $BZLMOD_FLAG ]; then
  _sedi 's#"@gregmagolan/test-a": \["//:patches/test-a.patch"\],##' MODULE.bazel
else
  _sedi 's#"@gregmagolan/test-a": \["//:patches/test-a.patch"\],##' WORKSPACE
fi

# Should fail when not all patches are included
if bazel build $BZLMOD_FLAG //...; then
  echo "ERROR: expected bazel build $BZLMOD_FLAG //...' to fail"
  exit 1
fi

echo "All tests passed"
