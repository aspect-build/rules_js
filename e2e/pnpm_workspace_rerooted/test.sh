#!/usr/bin/env bash
set -o errexit -o nounset

# put node on the path
node_path=$(dirname "$1")
if [[ "$node_path" == external/* ]]; then
    node_path="${node_path:9}"
fi
PATH="$PWD/../$node_path:$PATH"

node ./root/node_modules/typescript/bin/tsc --version
./root/node_modules/.bin/tsc --version
