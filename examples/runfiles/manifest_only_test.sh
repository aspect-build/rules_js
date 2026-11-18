#!/usr/bin/env bash
set -o errexit -o nounset -o pipefail

# Runs the js_binary $1 with only RUNFILES_MANIFEST_FILE set, pointing at a
# manifest that is not next to a runfiles tree, so the launcher has to build one.
binary="$PWD/$1"
manifest="$TEST_TMPDIR/custom_manifest"
# The sandbox does not stage the test's own manifest, so write one from its
# runfiles tree.
(cd "$TEST_SRCDIR" && find . \( -type l -o -type f \) -print) | while IFS= read -r path; do
    printf '%s %s\n' "${path#./}" "$(readlink -f "$TEST_SRCDIR/$path")"
done >"$manifest"
# An empty file, and a line Bazel escapes because its key has a space and its
# target a backslash.
printf '%s\n' '_main/runfiles/empty_file ' ' _main/runfiles/with\sspace /nonexistent/back\bslash' >>"$manifest"

unset TEST_SRCDIR RUNFILES_DIR RUNFILES_MANIFEST_FILE

fail() {
    echo "FAIL: $1" >&2
    exit 1
}

# Without arguments the binary only loads @bazel/runfiles from the tree. With
# arguments it would resolve them through RUNFILES_MANIFEST_FILE, which
# @bazel/runfiles does without the repository mapping, so `examples/...` paths
# cannot resolve from any manifest.
run() {
    local out
    out=$(RUNFILES_MANIFEST_FILE="$1" "$binary")
    [ "$out" = "[]" ] || fail "unexpected output: $out"
}

only_tree() {
    local trees=("$TEST_TMPDIR"/js_binary_runfiles.*/*)
    [ ${#trees[@]} -eq 1 ] && [ -d "${trees[0]}" ] || fail "expected one runfiles tree, found: ${trees[*]}"
    echo "${trees[0]}"
}

run "$manifest"
tree=$(only_tree)
[ "$(cat "$tree/_main/runfiles/test_fixture.md")" = "$(cat "$PWD/runfiles/test_fixture.md")" ] ||
    fail "test_fixture.md is missing from the runfiles tree"
[ -f "$tree/_main/runfiles/empty_file" ] && [ ! -L "$tree/_main/runfiles/empty_file" ] && [ ! -s "$tree/_main/runfiles/empty_file" ] ||
    fail "empty_file is not an empty regular file"
[ "$(readlink "$tree/_main/runfiles/with space")" = '/nonexistent/back\slash' ] ||
    fail "escaped entry was not unescaped"

# A second launch with the same manifest reuses the tree.
touch "$tree/reused"
run "$manifest"
[ "$(only_tree)" = "$tree" ] && [ -e "$tree/reused" ] || fail "runfiles tree was not reused"

# A changed manifest at the same path replaces the tree.
printf '%s\n' '_main/runfiles/other_empty_file ' >>"$manifest"
run "$manifest"
new_tree=$(only_tree)
[ "$new_tree" != "$tree" ] && [ -f "$new_tree/_main/runfiles/other_empty_file" ] ||
    fail "runfiles tree was not rebuilt for a changed manifest"

# A line whose key unescapes to nothing is rejected, and leaves nothing behind.
bad_manifest="$TEST_TMPDIR/bad_manifest"
printf '%s\n' '  /nonexistent/target' >"$bad_manifest"
if RUNFILES_MANIFEST_FILE="$bad_manifest" "$binary"; then
    fail "a manifest line with an empty key was accepted"
fi
[ "$(only_tree)" = "$new_tree" ] || fail "a failed launch left a runfiles tree behind"
