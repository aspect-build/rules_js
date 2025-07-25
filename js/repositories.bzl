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
        sha256 = "51b5105a760b353773f904d2bbc5e664d0987fbaf22265164de65d43e910d8ac",
        urls = ["https://github.com/bazelbuild/bazel-skylib/releases/download/1.8.1/bazel-skylib-1.8.1.tar.gz"],
    )

    http_archive(
        name = "rules_nodejs",
        sha256 = "8bfd114e95e88df5ecc66b03b726944f47a8b46db4b3b6ace87cfc316713bd1c",
        strip_prefix = "rules_nodejs-6.4.0",
        url = "https://github.com/bazel-contrib/rules_nodejs/releases/download/v6.4.0/rules_nodejs-v6.4.0.tar.gz",
    )

    http_archive(
        name = "aspect_bazel_lib",
        sha256 = "3522895fa13b97e8b27e3b642045682aa4233ae1a6b278aad6a3b483501dc9f2",
        strip_prefix = "bazel-lib-2.20.0",
        url = "https://github.com/bazel-contrib/bazel-lib/releases/download/v2.20.0/bazel-lib-v2.20.0.tar.gz",
    )
