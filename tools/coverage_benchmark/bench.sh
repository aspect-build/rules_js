#!/usr/bin/env bash
set -o errexit -o nounset -o pipefail

# Runs the arm matrix over a generated workspace and writes one TSV row per (arm, run).
#
#   bench.sh [--scale small|medium|large] [--runs N] [--root DIR] [--arms a,b,c] [--npm]
#
# Every arm gets its own output base. That is not a detail: this machine already carries
# warm output bases for this repo, and an invocation that lets bazel pick one attaches to
# a warm server and reports a warm number as a cold one. A cold arm therefore refuses to
# run if its base already exists.
#
# Likewise every test/coverage arm passes --nocache_test_results. Without it `bazel
# coverage` republishes a cached coverage.dat, the test action never runs, and a change to
# the coverage reporter measures as exactly zero.

SCALE=small
RUNS=3
ARMS=""
WITH_NPM=""
ROOT=""

while [ $# -gt 0 ]; do
    case "$1" in
    --scale)
        SCALE="$2"
        shift 2
        ;;
    --runs)
        RUNS="$2"
        shift 2
        ;;
    --root)
        ROOT="$2"
        shift 2
        ;;
    --arms)
        ARMS="$2"
        shift 2
        ;;
    --npm)
        WITH_NPM="--npm"
        shift
        ;;
    *)
        printf "unknown argument '%s'\n" "$1" >&2
        exit 1
        ;;
    esac
done

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly HERE
: "${ROOT:=${TMPDIR:-/tmp}/rules_js_coverage_bench}"

readonly WS="$ROOT/ws-$SCALE"
readonly RESULTS="$ROOT/results-$SCALE"
readonly REPO_CACHE="$ROOT/repository_cache" # shared: fetch npm once, not once per arm
mkdir -p "$RESULTS" "$REPO_CACHE"

# The default --instrumentation_filter bazel derives covers only the packages holding the
# tests, which in this workspace is //tests -- so nothing under //lib* would be
# instrumented and every arm would report empty coverage. Instrument the whole workspace,
# which is what a repo that actually wants coverage configures.
readonly FILTER='--instrumentation_filter=^//'

[ -n "$ARMS" ] || ARMS="build.cold,test.cold,cov.cold,cov.cold.nofilter,cov.cold.norunfiles,cov.cold.split,cov.null,toggle.test_then_cov"

"$HERE/generate.sh" "$WS" "$SCALE" ${WITH_NPM:+$WITH_NPM}

# Prints the bazel arguments for an arm on stdout, one per line, as
# "<command>\n<flag>...". Kept in one place so the arms cannot drift from their labels.
arm_argv() {
    case "$1" in
    build.cold) printf 'build\n' ;;
    test.cold) printf 'test\n--nocache_test_results\n' ;;
    cov.cold | cov.null) printf 'coverage\n--nocache_test_results\n%s\n' "$FILTER" ;;
    cov.cold.nofilter) printf 'coverage\n--nocache_test_results\n--instrumentation_filter=^//nonexistent\n' ;;
    cov.cold.norunfiles) printf 'coverage\n--nocache_test_results\n%s\n--nobuild_runfile_links\n' "$FILTER" ;;
    cov.cold.split)
        printf 'coverage\n--nocache_test_results\n%s\n--experimental_split_coverage_postprocessing\n--experimental_fetch_all_coverage_outputs\n' "$FILTER"
        ;;
    *)
        printf "unknown arm '%s'\n" "$1" >&2
        return 1
        ;;
    esac
}

# Runs one bazel invocation, appending a TSV row. $1 arm label, $2 run index, $3 output
# base, and the rest the bazel command + flags.
run_one() {
    local arm="$1" run="$2" base="$3"
    shift 3
    local tag="$arm.$run"
    local bep="$RESULTS/$tag.bep.json"
    local prof="$RESULTS/$tag.profile.gz"
    local log="$RESULTS/$tag.log"
    local start end status
    start=$(date +%s.%N)
    set +o errexit
    (
        cd "$WS" && bazel --output_base="$base" "$@" //... \
            --repository_cache="$REPO_CACHE" \
            --profile="$prof" \
            --build_event_json_file="$bep" --build_event_publish_all_actions \
            --execution_log_json_file="$RESULTS/$tag.execlog.json" \
            --test_output=all --jobs=8 --color=no --curses=no
    ) >"$log" 2>&1
    status=$?
    set -o errexit
    end=$(date +%s.%N)
    "$HERE/extract.sh" "$arm" "$run" "$SCALE" "$status" \
        "$(awk -v s="$start" -v e="$end" 'BEGIN { printf "%.2f", e - s }')" \
        "$base" "$RESULTS/$tag" >>"$RESULTS/results.tsv"
}

# Header, written once; extract.sh emits the matching columns.
# pre_exec_ms is the time before the first action ran (repository fetching + analysis);
# bazel_ms is bazel's own wall time. They overlap with execution under skymeld, so they
# are reported side by side rather than summed.
printf 'scale\tarm\trun\tstatus\twall_s\tpre_exec_ms\tbazel_ms\tactions\tbaseline_cov\ttests\ttest_s\tsymlink_s\tjavac_cpp\tmanifest\treport_ms\tcache_discarded\n' >"$RESULTS/results.tsv"

IFS=',' read -r -a arm_list <<<"$ARMS"
for arm in "${arm_list[@]}"; do
    for ((r = 1; r <= RUNS; r++)); do
        case "$arm" in
        toggle.*)
            # Deliberately shares one base across the two commands: the point is the
            # analysis-cache discard that toggling --collect_code_coverage causes. If
            # "discarding analysis cache" is absent from the log the arm degenerated into
            # a warm run and extract.sh flags the row.
            base="$ROOT/ob/$arm.$r"
            rm -rf "$base"
            if [ "$arm" = "toggle.test_then_cov" ]; then
                run_one "$arm.pre" "$r" "$base" test --nocache_test_results
                run_one "$arm" "$r" "$base" coverage --nocache_test_results "$FILTER"
            else
                run_one "$arm.pre" "$r" "$base" coverage --nocache_test_results "$FILTER"
                run_one "$arm" "$r" "$base" test --nocache_test_results
            fi
            ;;
        cov.null)
            # Cold run then an immediate rerun in the same base; only the second is timed.
            base="$ROOT/ob/$arm.$r"
            rm -rf "$base"
            mapfile -t argv < <(arm_argv cov.cold)
            run_one "$arm.warmup" "$r" "$base" "${argv[@]}"
            run_one "$arm" "$r" "$base" "${argv[@]}"
            ;;
        *)
            base="$ROOT/ob/$arm.$r"
            if [ -e "$base" ]; then
                printf "FATAL: output base %s already exists; a cold arm must start from nothing\n" "$base" >&2
                exit 1
            fi
            mapfile -t argv < <(arm_argv "$arm")
            run_one "$arm" "$r" "$base" "${argv[@]}"
            ;;
        esac
        # Shut the server down and reclaim the base: nine arms x three scales would
        # otherwise leave tens of GB behind, on top of what is already cached here.
        # bazel leaves its output tree read-only, so make it writable before removing it.
        (cd "$WS" && bazel --output_base="$base" shutdown >/dev/null 2>&1) || true
        chmod -R u+w "$base" 2>/dev/null || true
        rm -rf "$base"
    done
done

printf '\nresults: %s\n\n' "$RESULTS/results.tsv"
column -t -s$'\t' "$RESULTS/results.tsv"
