# Ensure pnpm only writes within the bazel test dir.
export XDG_CACHE_HOME="$TEST_TMPDIR/.cache"
export XDG_CONFIG_HOME="$TEST_TMPDIR/.config"
export XDG_DATA_HOME="$TEST_TMPDIR/.local/share"
export XDG_STATE_HOME="$TEST_TMPDIR/.local/state"

$1 --help
