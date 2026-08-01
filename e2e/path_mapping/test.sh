#!/usr/bin/env bash
# Proves that the --bazel-bindir launcher flag (js/private/js_binary.sh.tpl),
# combined with an argument derived from a File added to an Args object
# (bindir_path_mapping_check.bzl), lets Bazel's path mapping share a
# single cached action between two builds that differ only in compilation
# mode.
#
# A shared --disk_cache is required: -c opt and -c fastbuild are different
# configurations, so each gets its own action instance the first time Bazel
# visits it in a given build graph -- the incremental "did anything change"
# check within one build never gets a chance to compare across them. Only an
# explicit disk (or remote) cache lookup, keyed by the path-mapped action
# digest, can serve the second build's action from the first build's result.
set -o errexit -o nounset -o pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

scratch="$(mktemp -d)"
trap 'rm -rf "$scratch"' EXIT
disk_cache="$scratch/disk_cache"
exec_log="$scratch/exec_log.json"

# Force the BindirPathMappingCheck action to be treated as new on every run of
# this script.
invalidate="$(date +%s)"

bazel build -c fastbuild //bindir_path_mapping_check \
    --disk_cache="$disk_cache" \
    --action_env="BINDIR_PATH_MAPPING_CHECK_INVALIDATE=$invalidate"

bazel build -c opt //bindir_path_mapping_check \
    --disk_cache="$disk_cache" \
    --action_env="BINDIR_PATH_MAPPING_CHECK_INVALIDATE=$invalidate" \
    --execution_log_json_file="$exec_log"

matches="$(jq -s '[.[] | select(.mnemonic == "BindirPathMappingCheck")]' "$exec_log")"
count="$(echo "$matches" | jq 'length')"
if [ "$count" -eq 0 ]; then
    echo "FAIL: no BindirPathMappingCheck entry found in the -c opt execution log" >&2
    exit 1
fi

cache_hit="$(echo "$matches" | jq -r '.[0].cacheHit')"
if [ "$cache_hit" != "true" ]; then
    echo "FAIL: action was re-executed under -c opt (cacheHit=$cache_hit); path mapping did not share the cache entry from -c fastbuild" >&2
    exit 1
fi

echo "PASS: action was cache-shared across -c fastbuild and -c opt"

# Same proof as above, but exercising a plain js_run_binary target instead of
# a custom rule built on js_run_binary_action.
exec_log2="$scratch/exec_log2.json"

bazel build -c fastbuild //js_run_binary_path_mapping_check \
    --disk_cache="$disk_cache" \
    --action_env="JS_RUN_BINARY_PATH_MAPPING_CHECK_INVALIDATE=$invalidate"

bazel build -c opt //js_run_binary_path_mapping_check \
    --disk_cache="$disk_cache" \
    --action_env="JS_RUN_BINARY_PATH_MAPPING_CHECK_INVALIDATE=$invalidate" \
    --execution_log_json_file="$exec_log2"

matches2="$(jq -s '[.[] | select(.mnemonic == "JsRunBinaryPathMappingCheck")]' "$exec_log2")"
count2="$(echo "$matches2" | jq 'length')"
if [ "$count2" -eq 0 ]; then
    echo "FAIL: no JsRunBinaryPathMappingCheck entry found in the -c opt execution log" >&2
    exit 1
fi

cache_hit2="$(echo "$matches2" | jq -r '.[0].cacheHit')"
if [ "$cache_hit2" != "true" ]; then
    echo "FAIL: js_run_binary action was re-executed under -c opt (cacheHit=$cache_hit2); path mapping did not share the cache entry from -c fastbuild" >&2
    exit 1
fi

echo "PASS: js_run_binary action was cache-shared across -c fastbuild and -c opt"
