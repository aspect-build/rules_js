#!/usr/bin/env bash
# One-off test outside of Bazel to assert which repositories
# are *not* fetched by our rules.
# Avoids accidental eager fetches, per our blog post
# https://blog.aspect.dev/avoid-eager-fetches
set -o nounset -o errexit

# Some target pattern we think should *not* require the fetch
TARGETS="//..."

TMP="$(mktemp -d)"
# "build --nobuild" is how you say "analyze"
bazel 2>/dev/null --output_base="$TMP" build --nobuild --symlink_prefix=/ "$TARGETS"

# Assert that the external repository wasn't fetched
if ls 2>/dev/null "$TMP"/external/*unused* ; then
    echo >&2 "FAIL: an unused dependency was fetched"
    exit 1
fi
