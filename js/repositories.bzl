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

    # Transitive dependencies of aspect_bazel_lib.
    # Prior to upgrading bazel-lib past 2.16.0, users didn't need to call the bazel_lib_dependencies function.
    # We include them here to avoid breakages for users who may have been relying on the implicit presence of these dependencies.
    http_archive(
        name = "tar.bzl",
        sha256 = "8710443803496e1b9b5b66f56ae55aa586338cb09a4ddeb9bb3d6df4e6da44c7",
        strip_prefix = "tar.bzl-0.2.0",
        url = "https://github.com/alexeagle/tar.bzl/releases/download/v0.2.0/tar.bzl-v0.2.0.tar.gz",
    )
    http_archive(
        name = "jq.bzl",
        sha256 = "7b63435aa19cc6a0cfd1a82fbdf2c7a2f0a94db1a79ff7a4469ffa94286261ab",
        strip_prefix = "jq.bzl-0.1.0",
        url = "https://github.com/bazel-contrib/jq.bzl/releases/download/v0.1.0/jq.bzl-v0.1.0.tar.gz",
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
        sha256 = "6fd3b1e1a38ca744f9664be4627ced80895c7d2ee353891c172f1ab61309c933",
        strip_prefix = "bazel-lib-3.0.0",
        url = "https://github.com/bazel-contrib/bazel-lib/releases/download/v3.0.0/bazel-lib-v3.0.0.tar.gz",
    )

    http_archive(
        name = "aspect_tools_telemetry_report",
        sha256 = "3d6372792dd0654b2e77806bf9b358e06706234f179132575a178d0ce7312790",
        strip_prefix = "tools_telemetry-0.3.3",
        url = "https://github.com/aspect-build/tools_telemetry/releases/download/v0.3.3/tools_telemetry-v0.3.3.tar.gz",
    )
