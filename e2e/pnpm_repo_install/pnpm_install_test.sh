# Ensure pnpm only writes within the bazel test dir.
export XDG_CACHE_HOME="$TEST_TMPDIR/.cache"
export XDG_CONFIG_HOME="$TEST_TMPDIR/.config"
export XDG_DATA_HOME="$TEST_TMPDIR/.local/share"
export XDG_STATE_HOME="$TEST_TMPDIR/.local/state"

pnpm_version=`$1 --version`
if [[ $pnpm_version != "$2" ]]; then
  echo "Expected pnpm version '$2', got '$pnpm_version'"
  exit 1
fi

$1 install react-router
