#!/usr/bin/env bash

#   9.0 - pnpm v9.0.0 bumped the lockfile version to 9.0; this includes breaking changes regarding lifecycle hooks and patches
#  10.0 - pnpm v10 kept the lockfile version at 9.0, but has minor differences such as length of hashes, yaml key order etc.
#  11.0 - pnpm v11 rc introduced allowBuilds in pnpm-workspace.yaml (replacing onlyBuiltDependencies in package.json)

# pnpm v9.0.0 bumped the lockfile version to 9.0
pushd base && npx -y pnpm@~9 install --lockfile-only && mv pnpm-lock.yaml ../v90 && popd

# pnpm v10
pushd base && npx -y pnpm@~10 install --lockfile-only && mv pnpm-lock.yaml ../v101 && popd

# pnpm v11 rc
pushd base && npx -y pnpm@next-11 install --lockfile-only && mv pnpm-lock.yaml ../v110 && popd
