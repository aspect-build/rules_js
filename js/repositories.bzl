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
        sha256 = "37eaae51158b99d444c6ff277c212874aafa45302feb7dc58659113d23446165",
        strip_prefix = "rules_nodejs-6.5.0",
        url = "https://github.com/bazel-contrib/rules_nodejs/releases/download/v6.5.0/rules_nodejs-v6.5.0.tar.gz",
    )

    http_archive(
        name = "aspect_bazel_lib",
        sha256 = "fc8fe1be58ae39f84a8613d554534760c7f0819d407afcc98bbcbd990523bfed",
        strip_prefix = "bazel-lib-2.16.0",
        url = "https://github.com/bazel-contrib/bazel-lib/releases/download/v2.16.0/bazel-lib-v2.16.0.tar.gz",
    )
