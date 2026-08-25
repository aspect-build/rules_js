#!/usr/bin/env bash

# Pins what the fixed_args classifier decides, using the verdict every js_binary
# publishes in its hermetic_launcher_report output group. The differential test covers
# the case that works; these are the cases that must not, because getting them wrong
# means an argument silently reaching the program unexpanded.
#
# Arguments are (report file, expected verdict) pairs. The report line is the target
# label followed by the verdict, and only the verdict is checked -- the label spelling
# depends on how the workspace is being built. Whitespace is squeezed out of both sides
# because a test argument containing a space would not survive as one argument.

set -o errexit -o nounset -o pipefail

status=0

while [ "$#" -gt 0 ]; do
    report="$1"
    expected="$2"
    shift 2

    line="$(cat "$report")"
    actual="${line#* }"
    actual="${actual// /}"

    if [ "$actual" != "$expected" ]; then
        echo "FAIL: $report: expected '$expected', got '$actual'" >&2
        status=1
    fi
done

if [ "$status" -eq 0 ]; then
    echo "PASS"
fi

exit "$status"
