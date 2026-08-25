#!/usr/bin/env bash

# Runs the hermetic launcher the way a coverage-enabled test action runs it: COVERAGE_DIR
# and COVERAGE_MANIFEST in the environment, no NODE_V8_COVERAGE and no
# JS_BINARY__COVERAGE_REPORT, since producing both of those is the launcher's job. What
# comes out is the lcov report that the merger publishes, so this covers the whole chain --
# launcher.cjs, coverage.cjs and coverage.js.

set -o errexit -o nounset -o pipefail

launcher="$1"

export JS_BINARY__PATCH_NODE_FS=1

export COVERAGE_DIR="$TEST_TMPDIR/coverage"
mkdir -p "$COVERAGE_DIR"

# The instrumented sources, as bazel lists them for the test action. Deliberately not
# inside COVERAGE_DIR, every file of which c8 reads back as a V8 profile.
export COVERAGE_MANIFEST="$TEST_TMPDIR/coverage_manifest.txt"
cat >"$COVERAGE_MANIFEST" <<'MANIFEST'
js/private/test/hermetic_launcher/coverage_probe.js
js/private/test/hermetic_launcher/coverage_child.js
MANIFEST

# The value names no real directory, which keeps the launcher on the runfiles branch and
# out of a chdir this test is not set up for.
"$launcher" --bazel-bindir not/a/real/bindir

# The name coverage.js stashes the report under for the merger to read back.
report="$COVERAGE_DIR/_rules_js_report.lcov"

fail() {
    echo "FAIL: $1" >&2
    if [ -f "$report" ]; then
        echo "--- $report ---" >&2
        cat "$report" >&2
    fi
    ls -l "$COVERAGE_DIR" >&2
    exit 1
}

if [ ! -f "$report" ]; then
    fail "no lcov report at '$report'"
fi

expect() {
    grep -q "$1" "$report" || fail "expected '$1' in the report"
}

# Real V8 data for the process the launcher started, which it can only have if
# NODE_V8_COVERAGE was set before that node started.
expect '^SF:js/private/test/hermetic_launcher/coverage_probe\.js$'
expect '^FNDA:1,probeCovered$'
expect '^FNDA:0,probeUncovered$'

# ...and for the child, which inherited NODE_V8_COVERAGE instead, and whose profile the
# root process therefore reports late enough to include.
expect '^SF:js/private/test/hermetic_launcher/coverage_child\.js$'
expect '^FNDA:1,childCovered$'
expect '^FNDA:0,childUncovered$'

echo "PASS"
