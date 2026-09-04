#!/usr/bin/env bash
set -o errexit -o nounset -o pipefail

# Reduces one benchmark invocation's artifacts to a single TSV row.
#
#   extract.sh <arm> <run> <scale> <status> <wall_s> <output_base> <artifact-prefix>
#
# Reads <prefix>.bep.json, <prefix>.execlog.json and <prefix>.log. A missing or
# unparseable artifact yields "-" rather than failing the sweep; the status column says
# whether the run itself succeeded.
#
# Every helper must print exactly one whitespace-free token, or the TSV row wraps and the
# table becomes unreadable -- hence the `tr -d` and the single-branch fallbacks.

readonly ARM="$1" RUN="$2" SCALE="$3" STATUS="$4" WALL="$5" BASE="$6" PREFIX="$7"

# Actions that *executed*, by type. BaselineCoverage is a FileWriteAction, not a spawn, so
# it never appears in the execution log -- only BEP with --build_event_publish_all_actions
# sees it. Keeping graph size and executed count in different columns is the whole point.
action_count() {
    local n=-
    if [ -s "$PREFIX.bep.json" ]; then
        n=$(jq -r --arg t "$1" '
            select(.id.actionCompleted != null) | select((.action.type // "") == $t) | 1
        ' "$PREFIX.bep.json" 2>/dev/null | wc -l | tr -d ' \n') || n=-
    fi
    printf '%s' "${n:--}"
}

actions_total() {
    local n=-
    if [ -s "$PREFIX.bep.json" ]; then
        n=$(jq -r 'select(.id.actionCompleted != null) | 1' "$PREFIX.bep.json" 2>/dev/null |
            wc -l | tr -d ' \n') || n=-
    fi
    printf '%s' "${n:--}"
}

# Bazel 7 interleaves analysis and execution (skymeld), so these two overlap and must not
# be added together. `pre_exec` is the time before the first action ran, which is where
# repository fetching and analysis of the coverage tooling shows up.
timing_ms() {
    local v=-
    if [ -s "$PREFIX.bep.json" ]; then
        v=$(jq -r --arg k "$1" '
            select(.buildMetrics != null) | .buildMetrics.timingMetrics[$k] // empty
        ' "$PREFIX.bep.json" 2>/dev/null | head -1 | tr -d ' \n') || v=-
    fi
    printf '%s' "${v:--}"
}

# Summed spawn wall time for one mnemonic, in seconds.
spawn_seconds() {
    local v=-
    if [ -s "$PREFIX.execlog.json" ]; then
        v=$(jq -s --arg m "$1" '
            [ .[] | select(.mnemonic == $m)
                  | (.metrics.totalTime // "0s") | rtrimstr("s") | tonumber ]
            | add // 0 | . * 100 | round / 100
        ' "$PREFIX.execlog.json" 2>/dev/null | tr -d ' \n') || v=-
    fi
    printf '%s' "${v:--}"
}

# Largest instrumented-files manifest the run produced: the input whose size drives the
# reporter's cost, and the number the js_library extensions filter is meant to cut.
manifest_lines() {
    local n
    n=$(find "$BASE" -name '*.instrumented_files' -print0 2>/dev/null |
        xargs -0 -r wc -l 2>/dev/null |
        awk '$2 != "total" { if ($1 + 0 > m) m = $1 + 0 } END { print m + 0 }' | tr -d ' \n')
    printf '%s' "${n:-0}"
}

# Total reporter time, summed over the tests, from the JS_BINARY__LOG_DEBUG timings the
# coverage reporter emits. "-" when that instrumentation is absent or debug is off.
report_ms() {
    local v=-
    if [ -s "$PREFIX.log" ]; then
        v=$(awk '/coverage report generated in/ {
                for (i = 1; i <= NF; i++) if ($i ~ /^[0-9.]+ms$/) { sub(/ms$/, "", $i); t += $i }
             } END { if (t > 0) printf "%.0f", t; else printf "-" }' "$PREFIX.log" | tr -d ' \n') || v=-
    fi
    printf '%s' "${v:--}"
}

# A toggle arm that did not actually discard the analysis cache degenerated into a warm
# run; surface that rather than letting the row look valid.
analysis_discarded() {
    if [ -s "$PREFIX.log" ] && grep -q "discarding analysis cache" "$PREFIX.log"; then
        printf 'yes'
    elif [ -s "$PREFIX.log" ]; then
        printf 'no'
    else
        printf -- '-'
    fi
}

jvm_cpp_actions() {
    local a b
    a=$(action_count Javac)
    b=$(action_count CppCompile)
    if [ "$a" = "-" ] || [ "$b" = "-" ]; then printf -- '-'; else printf '%s' "$((a + b))"; fi
}

printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
    "$SCALE" "$ARM" "$RUN" "$STATUS" "$WALL" \
    "$(timing_ms actionsExecutionStartInMs)" \
    "$(timing_ms wallTimeInMs)" \
    "$(actions_total)" \
    "$(action_count BaselineCoverage)" \
    "$(action_count TestRunner)" \
    "$(spawn_seconds TestRunner)" \
    "$(spawn_seconds SymlinkTree)" \
    "$(jvm_cpp_actions)" \
    "$(manifest_lines)" \
    "$(report_ms)" \
    "$(analysis_discarded)"
