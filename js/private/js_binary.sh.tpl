#!/usr/bin/env bash

# This bash script is a trivial wrapper around the JavaScript launcher that sits
# beside it, which in turn runs the NodeJS JavaScript file entry point with the
# following bazel label:
#     {{entry_point_label}}
#
# The script's was generated to execute the js_binary target
#     {{target_label}}
#
# The template used to generate this script is
#     {{template_label}}
#
# All of the launcher logic lives in the JavaScript launcher. The only things
# that have to happen before node can run at all are locating the runfiles tree
# and resolving node and the launcher out of it, so that is all this does.

set -o pipefail -o errexit -o nounset

# Depended on by the runfiles initialization snippet below.
function logf_fatal {
    printf "FATAL: %s[%s]: %s\n" "{{log_prefix_rule_set}}" "{{log_prefix_rule}}" "$1" >&2
}

# ==============================================================================
# Initialize RUNFILES environment variable
# ==============================================================================
{{initialize_runfiles}}
# Read by the JavaScript launcher, which unsets it again so that the program
# under test sees the same environment it always has.
export RUNFILES

# ==============================================================================
# Run the JavaScript launcher
# ==============================================================================
{{bindir_prelude}}
node_bin="{{node_bin_expr}}"
launcher_js="{{launcher_js_expr}}"

exec "$node_bin" "$launcher_js" "$@"
