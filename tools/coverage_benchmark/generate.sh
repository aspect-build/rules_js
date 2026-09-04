#!/usr/bin/env bash
set -o errexit -o nounset -o pipefail

# Materializes a synthetic rules_js workspace whose size is controlled by $SCALE, so a
# benchmark can tell a constant coverage overhead apart from one that grows with the
# number of instrumented files.
#
#   generate.sh <out-dir> <scale> [--npm]
#
# The workspace consumes this repo through local_path_override, so it measures the
# working tree rather than a released version.
#
# Shape: $LIBS packages of $SRCS sources each as js_library, $TESTS js_test targets that
# each require a slice of them, and a couple of js_run_binary targets so build-only
# targets are represented in the graph. Every source has one covered and one uncovered
# function, so a report over it is never trivially empty.
#
# --npm links a small node_modules tree. Only the runfiles-materialization arm needs it;
# it costs a pnpm resolve, so it is off by default.

if [ $# -lt 2 ]; then
    printf "usage: %s <out-dir> <scale: small|medium|large> [--npm]\n" "$0" >&2
    exit 1
fi

readonly OUT="$1"
readonly SCALE="$2"
readonly WITH_NPM="${3:-}"

# The repo root, found from this script rather than $PWD so the generator can run from
# anywhere.
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
readonly REPO

case "$SCALE" in
small) LIBS=10 SRCS=10 TESTS=5 ;;
medium) LIBS=100 SRCS=20 TESTS=50 ;;
large) LIBS=500 SRCS=20 TESTS=200 ;;
*)
    printf "unknown scale '%s'; expected small, medium or large\n" "$SCALE" >&2
    exit 1
    ;;
esac
readonly LIBS SRCS TESTS

# A fresh tree every time: a partially-regenerated workspace would silently change the
# target count between arms and make the scaling numbers meaningless.
rm -rf "$OUT"
mkdir -p "$OUT"

cat >"$OUT/MODULE.bazel" <<EOF
bazel_dep(name = "aspect_rules_js", version = "0.0.0")
local_path_override(
    module_name = "aspect_rules_js",
    path = "$REPO",
)
EOF

if [ "$WITH_NPM" = "--npm" ]; then
    cat >>"$OUT/MODULE.bazel" <<'EOF'

npm = use_extension("@aspect_rules_js//npm:extensions.bzl", "npm", dev_dependency = True)
npm.npm_translate_lock(
    name = "npm",
    pnpm_lock = "//:pnpm-lock.yaml",
    verify_node_modules_ignored = "//:.bazelignore",
)
use_repo(npm, "npm")
EOF
    cat >"$OUT/package.json" <<'EOF'
{
    "name": "coverage-benchmark",
    "private": true,
    "dependencies": {
        "typescript": "5.6.3",
        "webpack": "5.95.0"
    }
}
EOF
    printf 'node_modules\n' >"$OUT/.bazelignore"
    # corepack rather than a bare pnpm: pnpm is not installed directly on dev machines here.
    (cd "$OUT" && corepack pnpm install --lockfile-only --ignore-scripts >/dev/null)
fi

# Importing the preset means the arms inherit the same flags a rules_js user gets --
# including `common --nobuild_runfile_links` with `coverage --build_runfile_links`, which
# is one of the things being measured.
cat >"$OUT/.bazelrc" <<EOF
import $REPO/tools/preset.bazelrc
common --noenable_workspace
common --check_direct_dependencies=off
EOF

if [ "$WITH_NPM" = "--npm" ]; then
    cat >"$OUT/BUILD.bazel" <<'EOF'
load("@aspect_rules_js//npm:defs.bzl", "npm_link_all_packages")

npm_link_all_packages(name = "node_modules")
EOF
else
    : >"$OUT/BUILD.bazel"
fi

# One covered and one uncovered function per source: the covered half proves the report
# is real, the uncovered half proves `all`-style reporting of never-executed code still
# works after the c8 change.
gen_lib() {
    local dir="$1" i="$2" n
    mkdir -p "$OUT/$dir"
    : >"$OUT/$dir/BUILD.bazel"
    {
        printf 'load("@aspect_rules_js//js:defs.bzl", "js_library")\n\n'
        printf 'js_library(\n    name = "lib",\n    srcs = [\n'
        for ((n = 0; n < SRCS; n++)); do
            printf '        "src%d.js",\n' "$n"
        done
        # A non-JS src, so the manifest's non-JS content is measurable before and after
        # the js_library extensions filter lands.
        printf '        "data.json",\n'
        printf '    ],\n    visibility = ["//visibility:public"],\n)\n'
    } >"$OUT/$dir/BUILD.bazel"

    printf '{"lib": %d}\n' "$i" >"$OUT/$dir/data.json"
    for ((n = 0; n < SRCS; n++)); do
        cat >"$OUT/$dir/src$n.js" <<EOF
function covered$n() {
    return 'lib${i}src${n}'
}

function uncovered$n() {
    // Never called, so it must show up as an unexecuted line in the report.
    return 'unreachable'
}

module.exports = { covered$n, uncovered$n }
EOF
    done
}

for ((i = 0; i < LIBS; i++)); do
    gen_lib "lib$i" "$i"
done

mkdir -p "$OUT/tests"
{
    printf 'load("@aspect_rules_js//js:defs.bzl", "js_test")\n\n'
    for ((t = 0; t < TESTS; t++)); do
        printf 'js_test(\n    name = "test%d",\n    data = [\n        "test%d.js",\n' "$t" "$t"
        # Each test depends on a slice of the libraries, so the manifest is large but not
        # identical across tests.
        for ((k = 0; k < 5; k++)); do
            printf '        "//lib%d:lib",\n' "$(((t * 5 + k) % LIBS))"
        done
        printf '    ],\n    entry_point = "test%d.js",\n)\n\n' "$t"
    done
} >"$OUT/tests/BUILD.bazel"

for ((t = 0; t < TESTS; t++)); do
    {
        for ((k = 0; k < 5; k++)); do
            printf "require('../lib%d/src0.js').covered0()\n" "$(((t * 5 + k) % LIBS))"
        done
    } >"$OUT/tests/test$t.js"
done

# A couple of build-only targets, so the graph contains js_run_binary tools and their
# generated helper targets rather than tests alone.
mkdir -p "$OUT/tool"
cat >"$OUT/tool/BUILD.bazel" <<'EOF'
load("@aspect_rules_js//js:defs.bzl", "js_binary", "js_run_binary")

js_binary(
    name = "gen",
    entry_point = "gen.js",
)

js_run_binary(
    name = "generated",
    outs = ["generated.js"],
    # The bin-relative path, not $(location): this action supports path mapping, which
    # rewrites the real output path, and BAZEL_BINDIR is the mapped value.
    args = ["tool/generated.js"],
    tool = ":gen",
)
EOF
cat >"$OUT/tool/gen.js" <<'EOF'
// A build-time tool: never a test, so nothing here should ever be instrumented.
const fs = require('fs')
const path = require('path')
// js_run_binary runs the tool with the working directory already set to BAZEL_BINDIR, so
// the bin-relative argument is used as-is. Joining it onto BAZEL_BINDIR would double the
// path and the declared output would never appear -- see js_run_binary.bzl's `chdir` docs.
const out = process.argv[process.argv.length - 1]
fs.mkdirSync(path.dirname(out), { recursive: true })
fs.writeFileSync(out, 'module.exports = 1\n')
EOF

printf 'generated %s workspace at %s: %d libs x %d srcs, %d tests\n' \
    "$SCALE" "$OUT" "$LIBS" "$SRCS" "$TESTS"
