#!/usr/bin/env bash

#   5.4 - pnpm v7.0.0 bumped the lockfile version to 5.4
#   6.0 - pnpm v8.0.0 bumped the lockfile version to 6.0; this included breaking changes
#   6.1 - pnpm v8.6.0 bumped the lockfile version to 6.1

mv v54/pnpm-lock.yaml . && npx pnpm@^7.0 install --lockfile-only && mv pnpm-lock.yaml v54/

# pnpm v8.0.0 bumped the lockfile version to 6.0, 8.6.0 bumped it to 6.1 which was then reverted to 6.0
# while still presenting minor differences from <8.6.0.
mv v60/pnpm-lock.yaml . && npx pnpm@8.5.1 install --lockfile-only && mv pnpm-lock.yaml v60/
mv v61/pnpm-lock.yaml . && npx pnpm@8.6.0 install --lockfile-only && mv pnpm-lock.yaml v61/
