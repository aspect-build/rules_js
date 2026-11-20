#!/usr/bin/env bash
set -euo pipefail

if [[ "${1:-}" != "apply" ]]; then
    echo "expected the apply subcommand" >&2
    exit 1
fi
shift
patch "$@"
printf '\nmodule.exports.PATCH_TOOL = true\n' >> index.js
