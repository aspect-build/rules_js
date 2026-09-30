#!/usr/bin/env bash
set -o errexit -o nounset -o pipefail

# `bazel run` hands the binary the caller's environment, so a BAZEL_BINDIR exported in the
# shell reaches the launcher as an absolute path. Regression test for #3046, where the launcher
# changed into it and reported JS_BINARY__EXECROOT=/.
#
# Run under both launchers here: CI skips test.sh on the hermetic launcher leg.
run() {
    echo "bazel run $* with BAZEL_BINDIR='${BAZEL_BINDIR-(unset)}'"
    if ! bazel run "$@" //:bazel_run_env; then
        echo "ERROR: expected 'bazel run //:bazel_run_env' to pass"
        exit 1
    fi
}

for launcher_flag in --@aspect_rules_js//js:use_hermetic_launcher=false --@aspect_rules_js//js:use_hermetic_launcher=true; do
    (unset BAZEL_BINDIR && run "$launcher_flag")
    BAZEL_BINDIR="$PWD" run "$launcher_flag"
done
