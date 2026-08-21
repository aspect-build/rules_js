#!/usr/bin/env bash

# Runs the hermetic launcher directly, with no bash launcher involved, and checks
# that launcher.cjs reconstructed the runtime contract that js_binary.sh.tpl would
# otherwise have set up.
#
# Exports only JS_BINARY__PATCH_NODE_FS, which is a per-target value the launcher
# binary cannot carry and which js_run_binary always passes through the action
# environment. Everything else asserted here has to be derived by the preload.

set -o errexit -o nounset -o pipefail

export JS_BINARY__PATCH_NODE_FS=1

launcher="$1"

if [ ! -x "$launcher" ]; then
    echo "FAIL: '$launcher' is not executable" >&2
    exit 1
fi

# No entry point argument -- the launcher already knows it. The --bazel-bindir flag
# is what js_run_binary prepends to every action; the preload must consume it. The
# value names no real directory, which keeps the launcher on the runfiles branch and
# out of a chdir this test is not set up for.
output="$("$launcher" --bazel-bindir not/a/real/bindir hello world)"

fail() {
    echo "FAIL: $1" >&2
    echo "--- launcher output ---" >&2
    echo "$output" >&2
    exit 1
}

expect() {
    if [[ "$output" != *"$1"$'\n'* && "$output" != *"$1" ]]; then
        fail "expected '$1'"
    fi
}

# The flag is consumed, its value is exported, and the program's own arguments survive.
expect "args=hello world"
expect "bazel_bindir=not/a/real/bindir"

# Without JS_BINARY__FS_PATCH_ROOTS from the preload, bootstrap.cjs patches nothing.
expect "depth=."
expect "fs_patched=yes"
expect "patch_roots_match=yes"

expect "runfiles_absolute=yes"
expect "execroot_absolute=yes"

expect "wrapper_is_file=yes"
expect "wrapper_first_on_path=yes"
expect "node_binary_is_file=yes"
expect "node_patches_match=yes"
expect "exec_path_is_file=yes"

expect "compile_cache_disabled=1"

# Also what makes a `--` separator before the entry point unnecessary: the launcher
# resolves it by prefixing the absolute runfiles root, so node can never mistake it for
# an option. js_binary.bzl spends no argument slot guarding that.
expect "main_absolute=yes"
expect "preserve_symlinks_main=yes"

echo "PASS"
