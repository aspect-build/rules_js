#!/usr/bin/env bash
set -o errexit -o nounset -o pipefail

patch "$@"

# Leave a trace only this custom tool would produce so the test can
# distinguish it from the default `patch` from PATH.
echo 'module.exports += " (custom patch_tool)"' >>index.js
