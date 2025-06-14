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
        sha256 = "8bfd114e95e88df5ecc66b03b726944f47a8b46db4b3b6ace87cfc316713bd1c",
        strip_prefix = "rules_nodejs-6.4.0",
        url = "https://github.com/bazel-contrib/rules_nodejs/releases/download/v6.4.0/rules_nodejs-v6.4.0.tar.gz",
    )

    http_archive(
        name = "aspect_bazel_lib",
        sha256 = "db7da732db4dece80cd6d368220930950c9306ff356ebba46498fe64e65a3945",
        strip_prefix = "bazel-lib-2.19.3",
        url = "https://github.com/bazel-contrib/bazel-lib/releases/download/v2.19.3/bazel-lib-v2.19.3.tar.gz",
    )
