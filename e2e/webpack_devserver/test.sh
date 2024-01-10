#!/usr/bin/env bash
set -o errexit -o nounset -o pipefail

# Integration test for js_run_devserver run with ibazel

BZLMOD_FLAG="${BZLMOD_FLAG:---enable_bzlmod=1}"

bazel run "$BZLMOD_FLAG" -- @pnpm//:pnpm --dir "$PWD" install

./serve_test.sh //:dev
./serve_test.sh //:dev_cjs
