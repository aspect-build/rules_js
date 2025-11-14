#!/usr/bin/env bash

set -o errexit -o nounset -o pipefail

# Don't include e2e or examples in the distribution artifact, to reduce size
echo >.git/info/attributes "examples export-ignore"
echo >>.git/info/attributes "js/private/test/image/non_ascii export-ignore"
# But **do** include e2e/bzlmod since the BCR wants to run presubmit test
# and it only sees our release artifact.
# shellcheck disable=2010
ls e2e | grep -v bzlmod | awk 'NF{print "e2e/" $0 " export-ignore"}' >>.git/info/attributes

# Argument provided by reusable workflow caller, see
# https://github.com/bazel-contrib/.github/blob/d197a6427c5435ac22e56e33340dff912bc9334e/.github/workflows/release_ruleset.yaml#L72
TAG=$1
# The prefix is chosen to match what GitHub generates for source archives
PREFIX="rules_js-${TAG:1}"
ARCHIVE="rules_js-$TAG.tar.gz"
git archive --format=tar --prefix="${PREFIX}/" "${TAG}" | gzip >"$ARCHIVE"

# Add generated API docs to the release
# see https://github.com/bazelbuild/bazel-central-registry/blob/main/docs/stardoc.md
docs="$(mktemp -d)"
targets="$(mktemp)"
bazel --output_base="$docs" query --output=label --output_file="$targets" 'kind("starlark_doc_extract rule", //...)'
bazel --output_base="$docs" build --target_pattern_file="$targets"
tar --create --auto-compress \
    --directory "$(bazel --output_base="$docs" info bazel-bin)" \
    --file "$GITHUB_WORKSPACE/${ARCHIVE%.tar.gz}.docs.tar.gz" .

cat <<EOF

Many companies are successfully building with rules_js.
If you're getting value from the project, please let us know!
Just comment on our [Adoption Discussion](https://github.com/aspect-build/rules_js/discussions/1000).

## Using Bzlmod:

Add to your \`MODULE.bazel\` file:
\`\`\`starlark
bazel_dep(name = "aspect_rules_js", version = "${TAG:1}")

####### Node.js version #########
# By default you get the node version from DEFAULT_NODE_VERSION in @rules_nodejs//nodejs:repositories.bzl
# Optionally you can pin a different node version:
bazel_dep(name = "rules_nodejs", version = "6.6.0")
node = use_extension("@rules_nodejs//nodejs:extensions.bzl", "node", dev_dependency = True)
node.toolchain(node_version = "18.14.2")
#################################

npm = use_extension("@aspect_rules_js//npm:extensions.bzl", "npm", dev_dependency = True)

npm.npm_translate_lock(
    name = "npm",
    pnpm_lock = "//:pnpm-lock.yaml",
    verify_node_modules_ignored = "//:.bazelignore",
)

use_repo(npm, "npm")

pnpm = use_extension("@aspect_rules_js//npm:extensions.bzl", "pnpm")

# Allows developers to use the matching pnpm version, for example:
# bazel run -- @pnpm --dir $PWD install
use_repo(pnpm, "pnpm")
\`\`\`
EOF

echo "\`\`\`"
