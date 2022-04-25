#!/usr/bin/env bash
# Bundle our program with its two dependencies, because they're large:
# ┌─────────────────┬──────────────┬────────┐
# │ name            │ children     │ size   │
# ├─────────────────┼──────────────┼────────┤
# │ @pnpm/lifecycle │ 277          │ 14.71M │
# ├─────────────────┼──────────────┼────────┤
# │ @pnpm/logger    │ 15           │ 0.56M  │
# ├─────────────────┼──────────────┼────────┤
# │ 2 modules       │ 202 children │ 11.73M │
# └─────────────────┴──────────────┴────────┘
# This avoids users having to fetch all those packages just to run the postinstall hooks.

npx @vercel/ncc@0.33.4 build lifecycle-hooks.js -o min -m
