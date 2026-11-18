#!/usr/bin/env bash
set -o errexit -o nounset -o pipefail

# Run the js_binary with only RUNFILES_MANIFEST_FILE set, pointing at a manifest
# that is not next to a runfiles tree.
manifest="$TEST_TMPDIR/custom_manifest"
cp "$TEST_SRCDIR/MANIFEST" "$manifest"
binary="$TEST_SRCDIR/${TEST_WORKSPACE}/runfiles/test_binary"

unset TEST_SRCDIR RUNFILES_DIR
out=$(RUNFILES_MANIFEST_FILE="$manifest" "$binary" test_fixture.md)

case "$out" in
*test_fixture.md*) ;;
*)
    echo "unexpected output: $out" >&2
    exit 1
    ;;
esac
