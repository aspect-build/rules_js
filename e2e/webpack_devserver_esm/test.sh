#!/usr/bin/env bash
set -o errexit -o nounset -o pipefail

# Integration test for js_run_devserver run with ibazel

bazel run -- @pnpm --dir "$PWD" install

./serve_test.sh //:dev
