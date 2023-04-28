#!/usr/bin/env bash
set -o errexit -o nounset -o pipefail

BZLMOD_FLAG="${BZLMOD_FLAG:-}"

# Integration test for js_run_devserver run with ibazel

# shellcheck disable=SC2086
bazel run $BZLMOD_FLAG -- @pnpm//:pnpm --dir "$PWD" install

# Ports must align with those in BUILD args[]
./serve_test.sh 8080 //src:serve
./serve_test.sh 8081 //src:serve_alt
./serve_test.sh 8082 //src:serve_simple
./serve_test.sh 8083 //src:serve_simple_bin
./serve_test.sh 8090 //src:serve_naughty
./serve_test.sh 8091 //src:serve_naughty_bin
./multirun_test.sh 8080 8081 //src:serve_multi
