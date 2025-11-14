#!/usr/bin/env bash
set -o errexit -o nounset -o pipefail

# Integration test for js_run_devserver run with ibazel

bazel run -- @pnpm --dir "$PWD" install

./serve_test.sh //src:serve
./serve_test.sh //src:serve_alt
./serve_test.sh //src:serve_simple
./serve_test.sh //src:serve_simple_bin
./serve_test.sh //src:serve_naughty
./serve_test.sh //src:serve_naughty_bin

bazel_version=$(head -n 1 .bazelversion)
bazel_major=${bazel_version::1}
if [[ "$bazel_major" -ge 7 ]]; then
    # multirun rule from https://github.com/ash2k/bazel-tools not compatible with Bazel 7
    echo "SKIPPING js_run_devserver + multirun tests since com_github_ash2k_bazel_tools is not compatible with Bazel 7"
else
    ./multirun_test.sh //src:serve_multi
fi

echo "test.sh: PASS"
