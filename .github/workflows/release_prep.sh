#!/usr/bin/env bash

set -o errexit -o nounset -o pipefail

# Set by GH actions, see
# https://docs.github.com/en/actions/learn-github-actions/environment-variables#default-environment-variables
TAG=${GITHUB_REF_NAME}
# The prefix is chosen to match what GitHub generates for source archives
PREFIX="rules_js-${TAG:1}"
ARCHIVE="rules_js-$TAG.tar.gz"
git archive --format=tar --prefix="${PREFIX}/" "${TAG}" | gzip > "$ARCHIVE"
SHA=$(shasum -a 256 "$ARCHIVE" | awk '{print $1}')

cat << EOF

## Using Bzlmod with Bazel 6:

Add to your \`MODULE.bazel\` file:
\`\`\`starlark
bazel_dep(name = "aspect_rules_js", version = "${TAG:1}")

####### Node.js version #########
# By default you get the node version from DEFAULT_NODE_VERSION in @rules_nodejs//nodejs:repositories.bzl
# Optionally you can pin a different node version:
bazel_dep(name = "rules_nodejs", version = "5.8.2")
node = use_extension("@rules_nodejs//nodejs:extensions.bzl", "node")
node.toolchain(node_version = "16.14.2")
#################################

npm = use_extension("@aspect_rules_js//npm:extensions.bzl", "npm", dev_dependency = True)

npm.npm_translate_lock(
    name = "npm",
    pnpm_lock = "//:pnpm-lock.yaml",
    verify_node_modules_ignored = "//:.bazelignore",
)

use_repo(npm, "npm")
\`\`\`

## Using WORKSPACE

Paste this snippet into your \`WORKSPACE\` file:

\`\`\`starlark
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

http_archive(
    name = "aspect_rules_js",
    sha256 = "${SHA}",
    strip_prefix = "${PREFIX}",
    url = "https://github.com/aspect-build/rules_js/releases/download/${TAG}/${ARCHIVE}",
)
EOF

awk 'f;/--SNIP--/{f=1}' e2e/workspace/WORKSPACE
echo "\`\`\`" 
