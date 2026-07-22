#!/usr/bin/env bash
set -o errexit -o nounset -o pipefail

# Each argument is a .tgz artifact produced by a `packable` npm_package.
for tarball in "$@"; do
    if [ ! -f "$tarball" ]; then
        echo "FAIL: expected tarball at $tarball"
        exit 1
    fi

    contents=$(tar -tzf "$tarball")

    # npm/pnpm pack everything under a top-level "package/" directory.
    echo "$contents" | grep -q '^package/package.json$' || {
        echo "FAIL: expected package/package.json in $tarball, GOT:"
        echo "$contents"
        exit 1
    }

    echo "$contents" | grep -q '^package/index.js$' || {
        echo "FAIL: expected package/index.js in $tarball, GOT:"
        echo "$contents"
        exit 1
    }
done
