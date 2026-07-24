#!/usr/bin/env bash
set -o errexit -o nounset -o pipefail

# Coverage behavior for `bazel test` / `bazel coverage`.
#
# All targets execute the same covered()/uncovered() code; they differ only in
# how the source is provided, which is what the coverage tooling trips over:
#
#   //:test                     relative require("./lib.js") — source inside the
#                               test's runfiles src root.
#   //:first_party_jslib_test   first-party js_library linked by name
#                               (require("@repro/jslib")) — the store entry
#                               symlinks to the library's real dir, so node
#                               resolves back into the src root.
#   //:first_party_npmpkg_test  first-party npm_package linked by name
#                               (require("@repro/lib")) — the sources are
#                               repackaged into the .aspect_rules_js store, so
#                               the executed realpath is under node_modules at a
#                               path with no relation to the coverage manifest.
#
# The first two must produce real coverage. The npm_package case is a KNOWN,
# still-open failure, distinct from the #2901 split-postprocessing fix and
# tracked in https://github.com/aspect-build/rules_js/issues/2933; it is checked
# but does not fail this script.
#
# Coverage is checked in two configurations:
#   inline  the _lcov_merger runs inside the test action.
#   split   the _lcov_merger runs as its own action, without the test's runfiles
#           (--experimental_split_coverage_postprocessing, implied by remote
#           execution) — the configuration from #2901.

readonly WORKING_TARGETS=(test first_party_jslib_test)
readonly KNOWN_BROKEN_TARGETS=(first_party_npmpkg_test)
readonly ALL_TARGETS=("${WORKING_TARGETS[@]}" "${KNOWN_BROKEN_TARGETS[@]}")

testlogs="$(bazel info bazel-testlogs)"

# Prints nothing and returns 0 if the report is real (exercised function is a
# hit, unexercised one a miss, and at least one line has a non-zero execution
# count); otherwise prints the reason and returns 1. Keyed off the function
# names rather than the SF: path so it is agnostic to how the source resolves.
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

# Hard assertion: fails the script if coverage is not real.
assert_coverage() {
    local target="$1" mode="$2" dat="$testlogs/$1/coverage.dat" reason
    if reason="$(coverage_is_real "$dat")"; then
        echo "PASS($target, $mode)"
    else
        echo "FAIL($target, $mode): $reason"
        cat "$dat" 2>/dev/null || true
        exit 1
    fi
}

# Soft check for the known-broken case: reports status without failing, and
# flags if it starts passing so it can be promoted to a hard assertion.
check_known_broken() {
    local target="$1" mode="$2" dat="$testlogs/$1/coverage.dat" reason
    if reason="$(coverage_is_real "$dat")"; then
        echo "UNEXPECTED PASS($target, $mode): coverage now works — promote to assert_coverage and close the follow-up."
    else
        echo "KNOWN FAILURE($target, $mode): $reason (store-linked npm_package first-party imports; tracked in https://github.com/aspect-build/rules_js/issues/2933)"
    fi
}

labeled_targets() {
    local t
    for t in "${ALL_TARGETS[@]}"; do echo "//:$t"; done
}

# The code under test executes in every scenario. If this passes but coverage
# below is empty, the failure is in coverage reporting, not test execution.
# shellcheck disable=SC2046
bazel test --nocache_test_results $(labeled_targets)

# --nocache_test_results: the coverage runs below differ only in post-processing
# flags, which do not invalidate a cached test result — without it a later run
# would just republish an earlier run's coverage.dat.

# shellcheck disable=SC2046
bazel coverage --nocache_test_results $(labeled_targets)
for t in "${WORKING_TARGETS[@]}"; do assert_coverage "$t" inline; done
for t in "${KNOWN_BROKEN_TARGETS[@]}"; do check_known_broken "$t" inline; done

# shellcheck disable=SC2046
bazel coverage --nocache_test_results \
    --experimental_split_coverage_postprocessing \
    --experimental_fetch_all_coverage_outputs \
    $(labeled_targets)
for t in "${WORKING_TARGETS[@]}"; do assert_coverage "$t" split; done
for t in "${KNOWN_BROKEN_TARGETS[@]}"; do check_known_broken "$t" split; done
