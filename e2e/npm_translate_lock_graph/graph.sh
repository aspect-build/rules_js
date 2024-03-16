#!/usr/bin/env bash
set -o errexit -o nounset -o pipefail

exclued="@aspect_rules_js//\|platform\|@aspect_bazel_lib//"

bazel query --notool_deps "deps(//:node_modules)" --output graph --order_output=full | grep -v "$exclued" | dot -Tpng >graph-node_modules.png

# Basic single dependency between packages
bazel query --notool_deps "deps(//:node_modules/is-number) union deps(//:node_modules/is-odd)" --output graph --order_output=full | grep -v "$exclued" | dot -Tpng >graph-basic.png

# Basic dependencies between workspace projects
bazel query --notool_deps "deps(//:node_modules/@test/a) union deps(//:node_modules/@test/b)" --output graph --order_output=full | grep -v "$exclued" | dot -Tpng >graph-refs.png

# Package with lifecycle hooks
bazel query --notool_deps "deps(//:node_modules/@aspect-test/c)" --output graph --order_output=full | grep -v "$exclued" | dot -Tpng >graph-c.png

# Complex package with multiple dependencies, circular dependencies, indirect lifecycle hooks
bazel query --notool_deps "deps(//:node_modules/@aspect-test/a) union deps(//:node_modules/@aspect-test/b)" --output graph --order_output=full | grep -v "$exclued" | dot -Tpng >graph-ab.png

# Complex package with multiple dependencies, circular dependencies, indirect lifecycle hooks
bazel query --notool_deps "deps(//:node_modules/@aspect-test/b) union deps(//:node_modules/@aspect-test/c)" --output graph --order_output=full | grep -v "$exclued" | dot -Tpng >graph-bc.png
