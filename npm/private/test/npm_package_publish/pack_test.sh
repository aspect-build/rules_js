#!/usr/bin/env bash
set -o errexit -o nounset -o pipefail

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

# rlocation gives back a Windows path on Windows, which tar reads as a host:path remote spec and
# bash cannot exec through its backslashes.
to_local_path() {
    if command -v cygpath >/dev/null 2>&1; then
        cygpath -u "$1"
    else
        echo "$1"
    fi
}

# Each argument is the runfiles path of a .tgz artifact produced by a `packable` npm_package.
for arg in "$@"; do
    tarball=$(to_local_path "$(rlocation "$arg")")
    if [ ! -f "$tarball" ]; then
        echo "FAIL: expected tarball at $arg"
        exit 1
    fi

    contents=$(tar -tzf "$tarball")

    # npm/pnpm pack everything under a top-level "package/" directory.
    echo "$contents" | grep -q '^package/package.json$' || {
        echo "FAIL: expected package/package.json in $tarball, GOT:"
        echo "$contents"
        exit 1
    }

    echo "$contents" | grep -q '^package/index.js$' || {
        echo "FAIL: expected package/index.js in $tarball, GOT:"
        echo "$contents"
        exit 1
    }
done
