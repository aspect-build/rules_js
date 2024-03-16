#!/usr/bin/env bash
set -o errexit -o nounset -o pipefail

./graph.sh

# Check if graphs have changed and fail test

# TODO: ./graph.sh is non-deterministic with minor changes in the graph
# if [[ `git status --porcelain` ]]; then
#     echo "ERROR: expected no changes in graphs"
#     exit 1
# fi

exit 1
