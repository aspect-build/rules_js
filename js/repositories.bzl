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
        sha256 = "6e78f0e57de26801f6f564fa7c4a48dc8b36873e416257a92bbb0937eeac8446",
        urls = ["https://github.com/bazelbuild/bazel-skylib/releases/download/1.8.2/bazel-skylib-1.8.2.tar.gz"],
    )

    http_archive(
        name = "rules_nodejs",
        sha256 = "3c9e09932f6e35a36fd247e0f31c22bdad9dc864f18d324bb42595e5cc79be0b",
        strip_prefix = "rules_nodejs-6.6.2",
        url = "https://github.com/bazel-contrib/rules_nodejs/releases/download/v6.6.2/rules_nodejs-v6.6.2.tar.gz",
    )

    http_archive(
        name = "aspect_bazel_lib",
        sha256 = "53cadea9109e646a93ed4dc90c9bbcaa8073c7c3df745b92f6a5000daf7aa3da",
        strip_prefix = "bazel-lib-2.21.2",
        url = "https://github.com/bazel-contrib/bazel-lib/releases/download/v2.21.2/bazel-lib-v2.21.2.tar.gz",
    )

    # Transitive dependencies of aspect_bazel_lib.
    # Prior to upgrading bazel-lib past 2.16.0, users didn't need to call the bazel_lib_dependencies function.
    # We include them here to avoid breakages for users who may have been relying on the implicit presence of these dependencies.
    http_archive(
        name = "tar.bzl",
        sha256 = "a0d64064a598d7a1e58196d17de0deed6d3d2d8bfe1407ed9e68b24c31c38e8d",
        strip_prefix = "tar.bzl-0.7.0",
        url = "https://github.com/alexeagle/tar.bzl/releases/download/v0.7.0/tar.bzl-v0.7.0.tar.gz",
    )
    http_archive(
        name = "jq.bzl",
        sha256 = "21617eb71fb775a748ef5639131ab943ef39946bd2a4ce96ea60b03f985db0c5",
        strip_prefix = "jq.bzl-0.4.0",
        url = "https://github.com/bazel-contrib/jq.bzl/releases/download/v0.4.0/jq.bzl-v0.4.0.tar.gz",
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
        sha256 = "fea3bc2f9b7896ab222756c27147b1f1b8f489df8114e03d252ffff475f8bce6",
        strip_prefix = "tools_telemetry-0.2.8",
        url = "https://github.com/aspect-build/tools_telemetry/releases/download/v0.2.8/tools_telemetry-v0.2.8.tar.gz",
    )
