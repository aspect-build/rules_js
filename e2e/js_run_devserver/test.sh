#!/usr/bin/env bash
set -o errexit -o nounset -o pipefail

BZLMOD_FLAG="${BZLMOD_FLAG:-}"

# Integration test for js_run_devserver run with ibazel

# shellcheck disable=SC2086
bazel run $BZLMOD_FLAG -- @pnpm//:pnpm --dir "$PWD" install

./serve_test.sh //src:serve
./serve_test.sh //src:serve_alt
./serve_test.sh //src:serve_simple
./serve_test.sh //src:serve_simple_bin
./serve_test.sh //src:serve_naughty
./serve_test.sh //src:serve_naughty_bin
./multirun_test.sh //src:serve_multi
echo "test.sh: PASS"