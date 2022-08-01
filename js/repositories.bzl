"""Declare runtime dependencies

These are needed for local dev, and users must install them as well.
See https://docs.bazel.build/versions/main/skylark/deploying.html#dependencies
"""

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("@bazel_tools//tools/build_defs/repo:utils.bzl", "maybe")

# WARNING: any changes in this function may be BREAKING CHANGES for users
# because we'll fetch a dependency which may be different from one that
# they were previously fetching later in their WORKSPACE setup, and now
# ours took precedence. Such breakages are challenging for users, so any
# changes in this function should be marked as BREAKING in the commit message
# and released only in semver majors.
def rules_js_dependencies():
    "Dependencies for users of aspect_rules_js"

    # The minimal version of bazel_skylib we require
    maybe(
        http_archive,
        name = "bazel_skylib",
        sha256 = "c6966ec828da198c5d9adbaa94c05e3a1c7f21bd012a0b29ba8ddbccb2c93b0d",
        urls = ["https://github.com/bazelbuild/bazel-skylib/releases/download/1.1.1/bazel-skylib-1.1.1.tar.gz"],
    )

    maybe(
        http_archive,
        name = "rules_nodejs",
        sha256 = "4d48998e3fa1e03c684e6bdf7ac98051232c7486bfa412e5b5475bbaec7bb257",
        urls = ["https://github.com/bazelbuild/rules_nodejs/releases/download/5.5.0/rules_nodejs-core-5.5.0.tar.gz"],
    )

    maybe(
        http_archive,
        name = "aspect_bazel_lib",
        sha256 = "e034e4aea098c91ac05ac7e08f01a302275378a0bc0814c4939e96552c912212",
        strip_prefix = "bazel-lib-1.9.2",
        url = "https://github.com/aspect-build/bazel-lib/archive/refs/tags/v1.9.2.tar.gz",
    )
