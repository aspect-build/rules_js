#!/usr/bin/env bash
set -o errexit -o nounset -o pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

JQ_FILTER='[
    .versions[]
    | select(.version | test("^(9|10|11|12)\\.[0-9.]+$"))
    | {key: .version, value: .dist.integrity}
] | sort_by(
    .key
    | split(".")
    | map(tonumber)
) | from_entries
'

# pnpm 12+ is distributed as a native binary per platform, one npm package per
# platform. Mirror the integrity of each platform package for those versions.
EXE_PLATFORMS=(
    darwin-arm64
    darwin-x64
    linux-arm64
    linux-arm64-musl
    linux-x64
    linux-x64-musl
    win32-arm64
    win32-x64
)

EXE_JQ_FILTER='[
    .versions[]
    | select(.version | test("^12\\.[0-9.]+$"))
    | {platform: $platform, version: .version, integrity: .dist.integrity}
]'

EXE_GROUP_FILTER='add | group_by(.version) | map({
    key: .[0].version,
    value: (map({key: .platform, value: .integrity}) | from_entries)
}) | sort_by(
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
    echo
    echo -ne 'PNPM_EXE_VERSIONS = '
    for platform in "${EXE_PLATFORMS[@]}"; do
        curl --silent "https://registry.npmjs.org/@pnpm/exe.$platform" | jq --arg platform "$platform" "$EXE_JQ_FILTER"
    done | jq --slurp "$EXE_GROUP_FILTER"
) >$SCRIPT_DIR/versions.bzl
