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
        sha256 = "37eaae51158b99d444c6ff277c212874aafa45302feb7dc58659113d23446165",
        strip_prefix = "rules_nodejs-6.5.0",
        url = "https://github.com/bazel-contrib/rules_nodejs/releases/download/v6.5.0/rules_nodejs-v6.5.0.tar.gz",
    )

    http_archive(
        name = "aspect_bazel_lib",
        sha256 = "53cadea9109e646a93ed4dc90c9bbcaa8073c7c3df745b92f6a5000daf7aa3da",
        strip_prefix = "bazel-lib-2.21.2",
        url = "https://github.com/bazel-contrib/bazel-lib/releases/download/v2.21.2/bazel-lib-v2.21.2.tar.gz",
    )

    http_archive(
        name = "aspect_tools_telemetry_report",
        sha256 = "fea3bc2f9b7896ab222756c27147b1f1b8f489df8114e03d252ffff475f8bce6",
        strip_prefix = "tools_telemetry-0.2.8",
        url = "https://github.com/aspect-build/tools_telemetry/releases/download/v0.2.8/tools_telemetry-v0.2.8.tar.gz",
    )
