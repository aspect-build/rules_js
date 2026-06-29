#!/usr/bin/env bash

set -euo pipefail

readonly PUBLISH="$1"

# pnpm publish should pick up the transformed package.json and report the package name.
# It will fail with an auth error since we're not actually publishing, but the output
# should contain the package name proving the package.json was correctly resolved.
$PUBLISH >pub.log 2>&1 || true

if grep -q '@test/pnpm-pkg' pub.log; then
    echo "PASS: pnpm publish found @test/pnpm-pkg in output"
    exit 0
fi

echo "FAIL: expected pnpm publish output to reference '@test/pnpm-pkg', GOT:"
cat pub.log
exit 1
