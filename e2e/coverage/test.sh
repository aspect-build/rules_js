#!/usr/bin/env bash
set -o errexit -o nounset -o pipefail

# Regression test for https://github.com/aspect-build/rules_js/issues/2901:
# `bazel coverage` produced empty (0%) lcov reports when the V8->lcov
# conversion ran in the _lcov_merger action, which does not have the
# instrumented sources. That happens when coverage postprocessing runs as its
# own action (--experimental_split_coverage_postprocessing, remote execution).
# The conversion now runs in the test action itself and the merger just
# publishes the resulting report.

coverage_dat="$(bazel info bazel-testlogs)/test/coverage.dat"

assert_coverage() {
    local mode="$1"

    fail() {
        echo "FAIL($mode): $1"
        echo "--- $coverage_dat ---"
        cat "$coverage_dat" 2>/dev/null || true
        exit 1
    }

    [[ -s "$coverage_dat" ]] || fail "coverage.dat is missing or empty"

    grep -q '^SF:lib.js$' "$coverage_dat" || fail "no coverage recorded for lib.js"

    # The function exercised by the test must be recorded as hit ...
    grep -q '^FNDA:1,covered$' "$coverage_dat" || fail "covered() not marked as executed"

    # ... and the one that is not exercised must be recorded as a miss.
    grep -q '^FNDA:0,uncovered$' "$coverage_dat" || fail "uncovered() not marked as unexecuted"

    # At least one line must have a non-zero execution count.
    grep -Eq '^DA:[0-9]+,[1-9]' "$coverage_dat" || fail "all line execution counts are zero"

    echo "PASS($mode)"
}

# --nocache_test_results: the two invocations below differ only in coverage
# postprocessing flags, which do not invalidate a cached test result — without
# it the second run would just republish the first run's coverage.dat.

# Default mode: the lcov merger runs inside the test action.
bazel coverage --nocache_test_results //:test
assert_coverage "inline-postprocessing"

# Split mode: the lcov merger runs as its own action, without the test's
# runfiles. This is the configuration from #2901 (also implied by remote
# execution) that used to yield an empty report.
bazel coverage --nocache_test_results \
    --experimental_split_coverage_postprocessing \
    --experimental_fetch_all_coverage_outputs \
    //:test
assert_coverage "split-postprocessing"
