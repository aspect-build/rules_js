# Bazel rules for js

**EXPERIMENTAL** this code is currently pre-release and not subject to any stability guarantee.
It could be archived or there could be major breaking changes.
Our goal is to eventually have rough feature parity with rules_nodejs "builtin", but probably not until mid 2022 at the earliest.

This ruleset is a high-performance alternative to rules_nodejs.

The primary difference is that we don't run `npm install` or `yarn install`, instead
we use a Bazel-idiomatic approach to managing the third-party dependencies adapted from
[pnpm](https://pnpm.io/), similar to how [Rush](https://rushjs.io/) manages packages.

Features include:

-   Only downloads packages from npm which are needed for the requested targets to be built/tested. [#2121](https://github.com/bazelbuild/rules_nodejs/issues/2121)
-   Bazel downloader caches the npm package files,
    so no fetches are required when the repository rule is cache-busted.
-   Always represents npm packages as directories (TreeArtifact's in Bazel terminology) so there are few inputs to Bazel actions,
    making I/O operations much faster for setting up execroot/runfiles trees.
-   Uses the new "core" rules_nodejs which only downloads node.js for the requested platform and allows multiple versions.

See the [design doc](https://hackmd.io/gu2Nj0TKS068LKAf8KanuA)

In addition, as a clean rewrite many of the bugs in rules_nodejs are naturally resolved:

-   Drop four years of accumulated complexity.
-   No Bash dependency on Windows, [#1102](https://github.com/bazelbuild/rules_nodejs/issues/1102)
-   js_binary can be used as the `tool` in a genrule [#1553](https://github.com/bazelbuild/rules_nodejs/issues/1553), [#2600](https://github.com/bazelbuild/rules_nodejs/issues/2600)
-   Repository layout matches the distribution so you can trivially patch or point to sources.
-   We use gazelle to generate bzl_library targets so users can always generate documentation
    for rules that reference these. [#2874](https://github.com/bazelbuild/rules_nodejs/issues/2874)

## Installation

From the release you wish to use:
<https://github.com/aspect-build/rules_js/releases>
copy the WORKSPACE snippet into your `WORKSPACE` file.

## Usage

See the API documentation in the [docs](docs/) folder and the example usage in the [example](example/) folder.
Note that the example also relies on code in the `/WORKSPACE` file in the root of this repo.
