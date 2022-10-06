"""Declare runtime dependencies

These are needed for local dev, and users must install them as well.
See https://docs.bazel.build/versions/main/skylark/deploying.html#dependencies
"""

load("@bazel_tools//tools/build_defs/repo:http.bzl", _http_archive = "http_archive")
load("@bazel_tools//tools/build_defs/repo:utils.bzl", "maybe")

def http_archive(name, **kwargs):
    maybe(_http_archive, name = name, **kwargs)

# WARNING: any changes in this function may be BREAKING CHANGES for users
# because we'll fetch a dependency which may be different from one that
# they were previously fetching later in their WORKSPACE setup, and now
# ours took precedence. Such breakages are challenging for users, so any
# changes in this function should be marked as BREAKING in the commit message
# and released only in semver majors.
def rules_js_dependencies():
    "Dependencies for users of aspect_rules_js"

    # The minimal version of bazel_skylib we require
    http_archive(
        name = "bazel_skylib",
        sha256 = "f7be3474d42aae265405a592bb7da8e171919d74c16f082a5457840f06054728",
        urls = ["https://github.com/bazelbuild/bazel-skylib/releases/download/1.2.1/bazel-skylib-1.2.1.tar.gz"],
    )

    http_archive(
        name = "rules_nodejs",
        sha256 = "33e309ba281fc73626a356a839bf5e5279360e7a2caea419c45c8017b5b3f7e2",
        urls = ["https://github.com/bazelbuild/rules_nodejs/releases/download/5.7.0/rules_nodejs-core-5.7.0.tar.gz"],
    )

    http_archive(
        name = "aspect_bazel_lib",
        sha256 = "79381b0975ba7d2d5653239e5bab12cf54d89b10217fe771b8edd95047a2e44b",
        strip_prefix = "bazel-lib-1.12.1",
        url = "https://github.com/aspect-build/bazel-lib/archive/refs/tags/v1.12.1.tar.gz",
    )
