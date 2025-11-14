#!/usr/bin/env bash
set -o errexit -o nounset -o pipefail

if ! bazel test --nobuild_runfile_links //...; then
    echo "ERROR: expected 'bazel test --nobuild_runfile_links //...' to pass"
    exit 1
fi
