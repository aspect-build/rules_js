#!/usr/bin/env bash

# Unit tests for the _lcov_merger script (js/private/coverage/coverage.sh.tpl).
# It is pure bash reading COVERAGE_DIR/COVERAGE_OUTPUT_FILE, so its branches can be
# driven directly here rather than only through a `bazel coverage` run, which
# //js/private/test/coverage does but only on CI's one coverage leg.

set -o errexit -o nounset -o pipefail

merger="$PWD/$1"

die() {
    printf "FAIL: %s\n" "$*" >&2
    exit 1
}

# Runs the merger in a fresh COVERAGE_DIR. Sets `output` to the published report and
# `stderr` to what the merger wrote to stderr.
#
# $1: contents of COVERAGE_OUTPUT_FILE before the merger runs.
# $2: contents of the stashed report, or the literal "<none>" for no stash at all.
run_merger() {
    dir="$(mktemp -d "${TEST_TMPDIR:-/tmp}/merger.XXXXXX")"
    printf "%s" "$1" >"$dir/coverage.dat"
    [ "$2" = "<none>" ] || printf "%s" "$2" >"$dir/_rules_js_report.lcov"

    stderr="$(COVERAGE_DIR="$dir" COVERAGE_OUTPUT_FILE="$dir/coverage.dat" "$merger" 2>&1 >/dev/null)"
    output="$(cat "$dir/coverage.dat")"
}

# The test program wrote its own report; the merger must not overwrite it.
# https://github.com/aspect-build/rules_js/pull/430
run_merger "# from the test itself" "SF:c8.js"
[ "$output" = "# from the test itself" ] || die "the test's own report was overwritten with '$output'"

# Same, with no stash at all: a rule that publishes a report it never generates still
# must not clobber what the test wrote, and has nothing to warn about.
run_merger "# from the test itself" "<none>"
[ "$output" = "# from the test itself" ] || die "the test's own report was overwritten with '$output'"
[ "$stderr" = "" ] || die "the test's own report: expected no warning, got '$stderr'"

# Nothing in COVERAGE_OUTPUT_FILE, a real stash: publish the stash.
run_merger "" "SF:c8.js"
[ "$output" = "SF:c8.js" ] || die "expected the stash to be published, got '$output'"
# cp, not mv: COVERAGE_DIR may be materialized read-only by the executor.
[ -e "$dir/_rules_js_report.lcov" ] || die "the stash was consumed (mv) rather than copied (cp)"

# coverage.js ran but had nothing to report: empty coverage, but not a misconfigured
# rule, so no warning.
run_merger "" ""
[ "$output" = "" ] || die "empty stash: expected empty coverage, got '$output'"
[ "$stderr" = "" ] || die "empty stash: expected no warning, got '$stderr'"

# No stash at all: the test rule wired up _lcov_merger without _coverage_report.
run_merger "" "<none>"
[ "$output" = "" ] || die "no stash: expected empty coverage, got '$output'"
case "$stderr" in
*"WARNING: no coverage report was generated in the test action"*) ;;
*) die "no stash: expected a warning about the missing report, got '$stderr'" ;;
esac

# Run outside a coverage run: a legible error, not an unbound-variable failure or a
# stash path resolved against the filesystem root.
expect_fatal() {
    local status=0
    local stderr
    stderr="$("$@" "$merger" 2>&1 >/dev/null)" || status=$?
    [ "$status" = 1 ] || die "$1 $2: expected exit 1, got $status"
    case "$stderr" in
    *"FATAL: COVERAGE_DIR and COVERAGE_OUTPUT_FILE must both be set"*) ;;
    *) die "$1 $2: expected a FATAL message, got '$stderr'" ;;
    esac
}

expect_fatal env -u COVERAGE_DIR COVERAGE_OUTPUT_FILE=/dev/null
expect_fatal env -u COVERAGE_OUTPUT_FILE COVERAGE_DIR=/dev/null
