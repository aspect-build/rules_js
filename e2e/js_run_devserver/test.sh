#!/usr/bin/env bash
set -o errexit -o nounset -o pipefail

# Integration test for js_run_devserver run with ibazel

bazel run -- @pnpm//:pnpm --dir "$PWD" install

./serve_test.sh //src:serve
./serve_test.sh //src:serve_alt
./serve_test.sh //src:serve_simple
./multirun_test.sh //src:serve_multi
