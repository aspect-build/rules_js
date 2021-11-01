# Bazel rules for js

**EXPERIMENTAL** this code is currently pre-release and not subject to any stability guarantee. It could be archived or there could be major breaking changes.

This ruleset is a high-performance alternative to rules_nodejs.
The primary difference is that we don't run `npm install` or `yarn install`, instead
we use a Bazel-idiomatic approach to managing the third-party dependencies.

Features include:

-   Only downloads packages from npm which are needed for the requested targets to be built/tested.
-   Bazel downloader caches the npm package files,
    so no fetches are required when the repository rule is cache-busted.
-   Allows multiple versions of Node.js in the same workspace.

See the [design doc](https://hackmd.io/gu2Nj0TKS068LKAf8KanuA)

In addition, as a clean rewrite many of the bugs in rules_nodejs are naturally resolved:

-   Drop four years of accumulated complexity.
-   No Bash dependency on Windows.
-   nodejs_binary can be used as the `tool` in a genrule.
-   Repository layout matches the distribution so you can trivially patch or point to sources.
-   We use gazelle to generate bzl_library targets so users can always generate documentation
    for rules that reference these.

## Installation

Include this in your WORKSPACE file:

```starlark
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
http_archive(
    name = "aspect_rules_js",
    url = "https://github.com/aspect-dev/rules_js/releases/download/0.0.0/rules_js-0.0.0.tar.gz",
    sha256 = "",
)

load("@aspect_rules_js//js:repositories.bzl", "js_rules_dependencies")

# This fetches the aspect_rules_js dependencies, which are:
# - bazel_skylib
# - rules_nodejs
# If you want to have a different version of some dependency,
# you should fetch it *before* calling this.
# Alternatively, you can skip calling this function, so long as you've
# already fetched these dependencies.
rules_js_dependencies()
```

> note, in the above, replace the version and sha256 with the one indicated
> in the release notes for aspect_rules_js
> In the future, our release automation should take care of this.

## Usage

See the API documentation in the docs/ folder and the example usage in the test/ folder.
