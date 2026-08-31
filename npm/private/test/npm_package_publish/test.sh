#!/usr/bin/env bash

# --- begin runfiles.bash initialization v3 ---
# Copy-pasted from the Bazel Bash runfiles library v3. Without a runfiles tree, which is the
# default on Windows, a runfiles path only means something to rlocation.
set -uo pipefail
set +e
f=bazel_tools/tools/bash/runfiles/runfiles.bash
# shellcheck disable=SC1090
source "${RUNFILES_DIR:-/dev/null}/$f" 2>/dev/null ||
    source "$(grep -sm1 "^$f " "${RUNFILES_MANIFEST_FILE:-/dev/null}" | cut -f2- -d' ')" 2>/dev/null ||
    source "$0.runfiles/$f" 2>/dev/null ||
    source "$(grep -sm1 "^$f " "$0.runfiles_manifest" | cut -f2- -d' ')" 2>/dev/null ||
    source "$(grep -sm1 "^$f " "$0.exe.runfiles_manifest" | cut -f2- -d' ')" 2>/dev/null ||
    {
        echo >&2 "ERROR: cannot find $f"
        exit 1
    }
f=
set -e
# --- end runfiles.bash initialization v3 ---

# Both publish commands below are expected to fail; the assertions are on what they logged.
set +e

# rlocation gives back a Windows path on Windows, which tar reads as a host:path remote spec and
# bash cannot exec through its backslashes.
to_local_path() {
    if command -v cygpath >/dev/null 2>&1; then
        cygpath -u "$1"
    else
        echo "$1"
    fi
}

readonly PUBLISH_A="$(to_local_path "$(rlocation "$1")")"
readonly PUBLISH_B="$(to_local_path "$(rlocation "$2")")"

# assert that it prints package name from package.json to stderr,
# to ensure package directory is properly passed and npm can read it.
$PUBLISH_A 2>pub_a.log

cat pub_a.log | grep 'npm notice package: @mycorp/pkg-to-publish@'

# shellcheck disable=SC2181
if [ $? != 0 ]; then
    echo "FAIL: expected 'npm notice package: @mycorp/pkg-to-publish@' error, GOT: $(cat pub_a.log)"
    exit 1
fi

# asserting that npm_package has no package.json in it's srcs and we fail correctly.
# npm publish requires a package.json in the root of the package directory.
$PUBLISH_B 2>pub_b.log

cat pub_b.log | grep 'npm error enoent Could not read package.json:'

# shellcheck disable=SC2181
if [ $? != 0 ]; then
    echo "FAIL: expected 'npm error enoent Could not read package.json:' error, GOT: $(cat pub_b.log)"
    exit 1
fi
