#!/usr/bin/env bash
set -o errexit -o nounset -o pipefail

# Coverage behavior for `bazel test` / `bazel coverage`.
#
# Every target executes the same covered()/uncovered() code and differs only in how
# the source is provided or the test exits — see BUILD.bazel for what each exercises.
#
# //:first_party_npmpkg_test is an UNSUPPORTED scenario, kept as executable
# documentation: first-party code repackaged with npm_package runs from a copy in
# the .aspect_rules_js store with no link back to source, so coverage comes out
# empty. Use js_library linking (//:first_party_jslib_test) for first-party
# coverage. See docs/troubleshooting.md and
# https://github.com/aspect-build/rules_js/issues/2933.
#
# Coverage is checked twice: inline (the _lcov_merger runs in the test action) and
# split (--experimental_split_coverage_postprocessing, required for remote
# execution), where the merger runs as its own action without the test's runfiles.
# Both must report the same coverage: the report is generated in the test action,
# and the merger only publishes it.

readonly WORKING_TARGETS=(//:test //:expected_exit_test //:first_party_jslib_test)
readonly UNSUPPORTED_TARGETS=(//:first_party_npmpkg_test)
readonly ALL_TARGETS=("${WORKING_TARGETS[@]}" "${UNSUPPORTED_TARGETS[@]}")

testlogs="$(bazel info bazel-testlogs)"

# Prints nothing and returns 0 if the report is real; otherwise prints the reason and
# returns 1. Keyed off the function names rather than the SF: path so it is agnostic
# to how the source resolves.
coverage_is_real() {
    local dat="$1"
    [[ -s "$dat" ]] || {
        echo "coverage.dat is missing or empty"
        return 1
    }
    grep -q '^FNDA:1,covered$' "$dat" || {
        echo "covered() not marked as executed"
        return 1
    }
    grep -q '^FNDA:0,uncovered$' "$dat" || {
        echo "uncovered() not marked as unexecuted"
        return 1
    }
    grep -Eq '^DA:[0-9]+,[1-9]' "$dat" || {
        echo "all line execution counts are zero"
        return 1
    }
}

assert_coverage() {
    local target="$1" mode="$2" dat="$testlogs/${1#//:}/coverage.dat" reason
    if reason="$(coverage_is_real "$dat")"; then
        echo "PASS($target, $mode)"
    else
        echo "FAIL($target, $mode): $reason"
        cat "$dat" 2>/dev/null || true
        exit 1
    fi
}

# The unsupported case must report empty coverage, the documented behavior. If it
# ever produces a real report the script fails, so the docs get revisited rather than
# the stale expectation rotting unnoticed in a green log.
check_unsupported() {
    local target="$1" mode="$2" dat="$testlogs/${1#//:}/coverage.dat" reason
    if reason="$(coverage_is_real "$dat")"; then
        echo "UNSUPPORTED($target, $mode) now produces coverage — update docs/troubleshooting.md and https://github.com/aspect-build/rules_js/issues/2933."
        exit 1
    else
        echo "UNSUPPORTED($target, $mode): empty coverage, as documented ($reason)"
    fi
}

# The code under test executes in every scenario. If this passes but coverage below
# is empty, the failure is in coverage reporting, not test execution.
bazel test --nocache_test_results "${ALL_TARGETS[@]}"

# --nocache_test_results on the coverage runs below: they differ only in
# post-processing flags, which do not invalidate a cached test result — without it a
# later run would just republish an earlier run's coverage.dat.
#
# No --instrument_test_targets: every covered source here lives in a js_library the
# test depends on, so the default instrumentation already picks it up.

bazel coverage --nocache_test_results "${ALL_TARGETS[@]}"
for t in "${WORKING_TARGETS[@]}"; do assert_coverage "$t" inline; done
for t in "${UNSUPPORTED_TARGETS[@]}"; do check_unsupported "$t" inline; done

bazel coverage --nocache_test_results \
    --experimental_split_coverage_postprocessing \
    --experimental_fetch_all_coverage_outputs \
    "${ALL_TARGETS[@]}"
for t in "${WORKING_TARGETS[@]}"; do assert_coverage "$t" split; done
for t in "${UNSUPPORTED_TARGETS[@]}"; do check_unsupported "$t" split; done
