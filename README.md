# Bazel rules for js

## Installation

Include this in your WORKSPACE file:

```starlark
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
http_archive(
    name = "build_aspect_rules_js",
    url = "https://github.com/aspect-dev/rules_js/releases/download/0.0.0/rules_js-0.0.0.tar.gz",
    sha256 = "",
)

load("@build_aspect_rules_js//js:repositories.bzl", "js_rules_dependencies")

# This fetches the rules_js dependencies, which are:
# - bazel_skylib
# If you want to have a different version of some dependency,
# you should fetch it *before* calling this.
# Alternatively, you can skip calling this function, so long as you've
# already fetched these dependencies.
rules_js_dependencies()
```

> note, in the above, replace the version and sha256 with the one indicated
> in the release notes for rules_js
> In the future, our release automation should take care of this.
