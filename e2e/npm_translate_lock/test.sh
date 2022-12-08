#!/usr/bin/env bash
set -o errexit -o nounset -o pipefail

# @rollup npm package should use registry.npmjs.org as per @rollup:registry=https://registry.npmjs.org/ override
if ! grep registry.npmjs.org/@rollup > /dev/null < repositories_checked.bzl; then
  echo "Expected to find registry.npmjs.org/@rollup in repositories_checked.bzl"
  exit 1
fi
if ! grep -v registry.yarnpkg.com/@rollup > /dev/null < repositories_checked.bzl; then
  echo "Expected to not find registry.yarnpkg.com/@rollup in repositories_checked.bzl"
  exit 1
fi

# all other npm packages (which includes @types) should use registry.yarnpkg.com as per the default registry=https://registry.yarnpkg.com
if ! grep registry.yarnpkg.com/@types > /dev/null < repositories_checked.bzl; then
  echo "Expected to find registry.yarnpkg.com/@types in repositories_checked.bzl"
  exit 1
fi
if ! grep -v registry.npmjs.org/@types > /dev/null < repositories_checked.bzl; then
  echo "Expected to not find registry.npmjs.org/@types in repositories_checked.bzl"
  exit 1
fi

echo "All tests passed"
