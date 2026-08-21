#!/usr/bin/env bash

# Guards the differential test: it only means anything if its two sides really ran
# through different launchers. Each side records the preload node was given, which is
# bootstrap.cjs for the bash launcher and launcher.cjs for the hermetic one.

set -o errexit -o nounset -o pipefail

bash_launcher="$(cat "$1")"
hermetic_launcher="$(cat "$2")"
debug_launcher="$(cat "$3")"

if [ "$bash_launcher" != "bootstrap.cjs" ]; then
    echo "FAIL: expected report_bash to run through the bash launcher, got preload '$bash_launcher'" >&2
    exit 1
fi

if [ "$hermetic_launcher" != "launcher.cjs" ]; then
    echo "FAIL: expected report_hermetic to run through the hermetic launcher, got preload '$hermetic_launcher'" >&2
    exit 1
fi

# A raised log level must not push a target back onto the bash launcher.
if [ "$debug_launcher" != "launcher.cjs" ]; then
    echo "FAIL: expected report_debug to run through the hermetic launcher, got preload '$debug_launcher'" >&2
    exit 1
fi

echo "PASS"
