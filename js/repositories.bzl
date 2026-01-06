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
        sha256 = "3b5b49006181f5f8ff626ef8ddceaa95e9bb8ad294f7b5d7b11ea9f7ddaf8c59",
        urls = ["https://github.com/bazelbuild/bazel-skylib/releases/download/1.9.0/bazel-skylib-1.9.0.tar.gz"],
    )

    http_archive(
        name = "rules_nodejs",
        sha256 = "3c9e09932f6e35a36fd247e0f31c22bdad9dc864f18d324bb42595e5cc79be0b",
        strip_prefix = "rules_nodejs-6.6.2",
        url = "https://github.com/bazel-contrib/rules_nodejs/releases/download/v6.6.2/rules_nodejs-v6.6.2.tar.gz",
    )

    http_archive(
        name = "aspect_bazel_lib",
        sha256 = "5f77cc224c1ae4391f125a6fcff6bfb5f08da278fc281443a2a7e16886cf0606",
        strip_prefix = "bazel-lib-2.22.2",
        url = "https://github.com/bazel-contrib/bazel-lib/releases/download/v2.22.2/bazel-lib-v2.22.2.tar.gz",
    )

    # Transitive dependencies of aspect_bazel_lib.
    # Prior to upgrading bazel-lib past 2.16.0, users didn't need to call the bazel_lib_dependencies function.
    # We include them here to avoid breakages for users who may have been relying on the implicit presence of these dependencies.
    http_archive(
        name = "tar.bzl",
        sha256 = "8710443803496e1b9b5b66f56ae55aa586338cb09a4ddeb9bb3d6df4e6da44c7",
        strip_prefix = "tar.bzl-0.2.0",
        url = "https://github.com/alexeagle/tar.bzl/releases/download/v0.8.0/tar.bzl-v0.2.0.tar.gz",
    )
    http_archive(
        name = "jq.bzl",
        sha256 = "d642668f79bc0c9ccdc0b8c89964f71e6bb3cd564013ca642f8f544732a97f8c",
        strip_prefix = "jq.bzl-0.5.0",
        url = "https://github.com/bazel-contrib/jq.bzl/releases/download/v0.5.0/jq.bzl-v0.5.0.tar.gz",
    )
    http_archive(
        name = "rules_shell",
        sha256 = "e6b87c89bd0b27039e3af2c5da01147452f240f75d505f5b6880874f31036307",
        strip_prefix = "rules_shell-0.6.1",
        url = "https://github.com/bazelbuild/rules_shell/releases/download/v0.6.1/rules_shell-v0.6.1.tar.gz",
    )
    # End aspect_bazel_lib transitive dependencies

    http_archive(
        name = "bazel_lib",
        sha256 = "fd0fe4df9b6b7837d5fd765c04ffcea462530a08b3d98627fb6be62a693f4e12",
        strip_prefix = "bazel-lib-3.1.0",
        url = "https://github.com/bazel-contrib/bazel-lib/releases/download/v3.1.0/bazel-lib-v3.1.0.tar.gz",
    )

    http_archive(
        name = "aspect_tools_telemetry_report",
        sha256 = "fea3bc2f9b7896ab222756c27147b1f1b8f489df8114e03d252ffff475f8bce6",
        strip_prefix = "tools_telemetry-0.2.8",
        url = "https://github.com/aspect-build/tools_telemetry/releases/download/v0.2.8/tools_telemetry-v0.2.8.tar.gz",
    )
