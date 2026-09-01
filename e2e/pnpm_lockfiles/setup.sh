#!/usr/bin/env bash

#   9.0 - pnpm v9.0.0 bumped the lockfile version to 9.0; this includes breaking changes regarding lifecycle hooks and patches
#  10.0 - pnpm v10 kept the lockfile version at 9.0, but has minor differences such as length of hashes, yaml key order etc.
#  11.0 - pnpm v11 kept the lockfile version at 9.0 and made several minor changes
#  12.0 - pnpm v12 kept the lockfile version at 9.0; adds integrity+gitHosted to URL resolutions, peer suffixes on URL deps, and rejects dependency aliases with path separators or bare @scope names

# pnpm v9.0.0 bumped the lockfile version to 9.0
pushd v90 && npx -y pnpm@~9 install --lockfile-only && popd

# pnpm v10
pushd v101 && npx -y pnpm@~10 install --lockfile-only && popd

# pnpm v11
pushd v110 && npx -y pnpm@~11 install --lockfile-only && popd

# pnpm v12
pushd v120 && npx -y pnpm@~12 install --lockfile-only && popd
