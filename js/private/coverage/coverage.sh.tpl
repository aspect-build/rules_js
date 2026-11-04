#!/usr/bin/env bash

set -o pipefail -o errexit -o nounset

# The _lcov_merger step: publishes the lcov report the test action already generated
# (see coverage.js). Computes nothing, so it needs no node or runfiles. See #2901.
#
# The only placeholder is the trailing comment, so this file is valid bash as-is,
# letting shellcheck lint it directly rather than a snapshot of its expansion.

# Bazel always sets both for an _lcov_merger; fail legibly rather than with an
# unbound-variable error if this is run outside a coverage run.
if [ -z "${COVERAGE_DIR:-}" ] || [ -z "${COVERAGE_OUTPUT_FILE:-}" ]; then
    printf "FATAL: COVERAGE_DIR and COVERAGE_OUTPUT_FILE must both be set; this script is only usable as a bazel _lcov_merger\n" >&2
    exit 1
fi

# COVERAGE_DIR is the only channel bazel carries from the test action to this one.
# coverage.js writes this exact filename; keep the two in sync.
stash="$COVERAGE_DIR/_rules_js_report.lcov"

if [ -s "$COVERAGE_OUTPUT_FILE" ]; then
    # The test reported its own coverage (jest, nyc, ...); it owns the output file.
    # See https://github.com/aspect-build/rules_js/pull/430.
    :
elif [ -s "$stash" ]; then
    # cp, not mv: an executor is free to materialize COVERAGE_DIR read-only.
    cp "$stash" "$COVERAGE_OUTPUT_FILE"
elif [ ! -e "$stash" ]; then
    # No stash at all: coverage.js never ran, so the test rule is missing a
    # _coverage_report attr. An empty stash means it ran with nothing to report.
    printf "WARNING: no coverage report was generated in the test action, reporting empty coverage. See https://github.com/aspect-build/rules_js/issues/2901\n" >&2
fi

#{{merge_assertions}}
