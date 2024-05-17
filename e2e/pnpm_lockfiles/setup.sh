#!/usr/bin/env bash

#   5.4 - pnpm v7.0.0 bumped the lockfile version to 5.4
#   6.0 - pnpm v8.0.0 bumped the lockfile version to 6.0; this included breaking changes
#   6.1 - pnpm v8.6.0 bumped the lockfile version to 6.1
#   9.0 - pnpm v9.0.0 bumped the lockfile version to 9.0; this includes breaking changes regarding lifecycle hooks and patches

pushd base && npx pnpm@^7.0 install --lockfile-only && mv pnpm-lock.yaml ../v54/ && popd

# pnpm v8.0.0 bumped the lockfile version to 6.0, 8.6.0 bumped it to 6.1 which was then reverted to 6.0
# while still presenting minor differences from <8.6.0.
pushd base && npx pnpm@8.5.1 install --lockfile-only && mv pnpm-lock.yaml ../v60/ && popd
pushd base && npx pnpm@8.6.0 install --lockfile-only && mv pnpm-lock.yaml ../v61/ && popd

# pnpm v9.0.0 bumped the lockfile version to 9.0
pushd base && npx pnpm@^9.0 install --lockfile-only && mv pnpm-lock.yaml ../v90 && popd
