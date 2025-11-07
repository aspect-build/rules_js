"""Declare runtime dependencies

These are needed for local dev, and users must install them as well.
See https://docs.bazel.build/versions/main/skylark/deploying.html#dependencies
"""

load("@bazel_tools//tools/build_defs/repo:http.bzl", _http_archive = "http_archive")
load("@bazel_tools//tools/build_defs/repo:utils.bzl", "maybe")

def http_archive(**kwargs):
    maybe(_http_archive, **kwargs)

# buildifier: disable=function-docstring
def rules_js_dependencies():
    http_archive(
        name = "bazel_skylib",
        sha256 = "bc283cdfcd526a52c3201279cda4bc298652efa898b10b4db0837dc51652756f",
        urls = ["https://github.com/bazelbuild/bazel-skylib/releases/download/1.7.1/bazel-skylib-1.7.1.tar.gz"],
    )

    http_archive(
        name = "rules_nodejs",
        sha256 = "164f1bd7e2a67ab3f6caf5b49b53c7dd625d293513154fa720e30d39eaa8285f",
        strip_prefix = "rules_nodejs-6.3.5",
        url = "https://github.com/bazel-contrib/rules_nodejs/releases/download/v6.3.5/rules_nodejs-v6.3.5.tar.gz",
    )

    http_archive(
        name = "aspect_bazel_lib",
        sha256 = "e5131e44db23459bd1ed04635f2ae5436bc83f5e38629e07b75c0bf206f09245",
        strip_prefix = "bazel-lib-2.17.1",
        url = "https://github.com/bazel-contrib/bazel-lib/releases/download/v2.17.1/bazel-lib-v2.17.1.tar.gz",
    )

    # A transitive dependency of aspect_bazel_lib.
    # Prior to upgrading bazel-lib past 2.16.0, users didn't need to call the bazel_lib_dependencies function.
    # We include it here to avoid breakages for users who may have been relying on the implicit presence of this dependency.
    http_archive(
        name = "tar.bzl",
        sha256 = "a147d473a359742db2a43c8a9a8e04e31321582e6bb669dafc5ba6b2c59845d1",
        strip_prefix = "tar.bzl-0.6.0",
        url = "https://github.com/bazel-contrib/tar.bzl/releases/download/v0.6.0/tar.bzl-v0.6.0.tar.gz",
    )

    http_archive(
        name = "bazel_lib",
        sha256 = "6fd3b1e1a38ca744f9664be4627ced80895c7d2ee353891c172f1ab61309c933",
        strip_prefix = "bazel-lib-3.0.0",
        url = "https://github.com/bazel-contrib/bazel-lib/releases/download/v3.0.0/bazel-lib-v3.0.0.tar.gz",
    )

    http_archive(
        name = "aspect_tools_telemetry_report",
        sha256 = "fea3bc2f9b7896ab222756c27147b1f1b8f489df8114e03d252ffff475f8bce6",
        strip_prefix = "tools_telemetry-0.2.8",
        url = "https://github.com/aspect-build/tools_telemetry/releases/download/v0.2.8/tools_telemetry-v0.2.8.tar.gz",
    )
