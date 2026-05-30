#!/usr/bin/env bash

readonly PUBLISH_A="$1"
readonly PUBLISH_B="$2"
readonly PUBLISH_PNPM="$3"

# Assert that pnpm reads package.json from the package directory.
$PUBLISH_A >pub_a.log 2>&1

cat pub_a.log | grep 'ERR_PNPM_PACKAGE_VERSION_NOT_FOUND'

# shellcheck disable=SC2181
if [ $? != 0 ]; then
    echo "FAIL: expected 'ERR_PNPM_PACKAGE_VERSION_NOT_FOUND' error, GOT: $(cat pub_a.log)"
    exit 1
fi

# asserting that npm_package has no package.json in it's srcs and we fail correctly.
# pnpm publish requires a package.json in the root of the package directory.
$PUBLISH_B >pub_b.log 2>&1

cat pub_b.log | grep 'ERR_PNPM_NO_IMPORTER_MANIFEST_FOUND'

# shellcheck disable=SC2181
if [ $? != 0 ]; then
    echo "FAIL: expected 'ERR_PNPM_NO_IMPORTER_MANIFEST_FOUND' error, GOT: $(cat pub_b.log)"
    exit 1
fi

readonly TMP_WORKSPACE="$(mktemp -d)"
trap 'rm -rf "${TMP_WORKSPACE}"' EXIT

cat >"${TMP_WORKSPACE}/pnpm-workspace.yaml" <<'EOF'
packages:
    - packages/*
catalog:
    typescript: 5.9.3
EOF

# Ensure pnpm publish can read workspace-level catalog settings when publishing
# a generated package directory.
BUILD_WORKSPACE_DIRECTORY="${TMP_WORKSPACE}" \
    "$PUBLISH_PNPM" --dry-run --json >pub_pnpm.log 2>pub_pnpm.err

# shellcheck disable=SC2181
if [ $? != 0 ]; then
    echo "FAIL: expected pnpm publish dry-run to pass, GOT stdout: $(cat pub_pnpm.log), stderr: $(cat pub_pnpm.err)"
    exit 1
fi

cat pub_pnpm.log | grep '"name": "@mycorp/pkg-to-publish-pnpm"'

# shellcheck disable=SC2181
if [ $? != 0 ]; then
    echo "FAIL: expected pnpm publish dry-run output to include package name, GOT: $(cat pub_pnpm.log)"
    exit 1
fi

# The source package.json is 132 bytes. pnpm rewrites catalog: to the concrete
# version before packing, producing the smaller manifest below.
cat pub_pnpm.log | grep '"size": 116'

# shellcheck disable=SC2181
if [ $? != 0 ]; then
    echo "FAIL: expected pnpm publish to resolve catalog: in package.json, GOT: $(cat pub_pnpm.log)"
    exit 1
fi
