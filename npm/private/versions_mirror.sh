#!/usr/bin/env bash
set -o errexit -o nounset -o pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

JQ_FILTER='[
    .versions[]
    | select(.version | test("^[0-9.]+$"))
    | {key: .version, value: .dist.integrity}
] | sort_by(
    .key
    | split(".")
    | map(tonumber)
) | from_entries
'

(
    cat <<EOF
"""Mirror of npm registry metadata for the pnpm package.

AUTO-GENERATED; do not edit
"""

EOF
    echo -ne 'PNPM_VERSIONS = '
    curl --silent https://registry.npmjs.org/pnpm | jq "$JQ_FILTER"
) >$SCRIPT_DIR/versions.bzl
