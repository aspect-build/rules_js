#!/usr/bin/env bash
{{rlocation_function}}

set -o pipefail -o errexit -o nounset

node="$(rlocation {{node}})"
entry_point="$(rlocation {{entry_point}})"

"$node" "$entry_point"