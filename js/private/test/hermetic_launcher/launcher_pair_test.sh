#!/usr/bin/env bash

# Guards a two-sided differential test: it only means anything if its two sides really
# ran through different launchers. Each side records the preload node was given, which
# is bootstrap.cjs for the bash launcher and launcher.cjs for the hermetic one.
#
# Without this, a change that disqualified the hermetic side would put both sides on
# the bash launcher and the diff_test would still pass.
#
# Arguments: a name for the pair, then its bash-side and hermetic-side record.

set -o errexit -o nounset -o pipefail

pair="$1"
bash_launcher="$(cat "$2")"
hermetic_launcher="$(cat "$3")"

if [ "$bash_launcher" != "bootstrap.cjs" ]; then
    echo "FAIL: expected the bash side of $pair to run through the bash launcher, got preload '$bash_launcher'" >&2
    exit 1
fi

if [ "$hermetic_launcher" != "launcher.cjs" ]; then
    echo "FAIL: expected the hermetic side of $pair to run through the hermetic launcher, got preload '$hermetic_launcher'" >&2
    exit 1
fi

echo "PASS"
