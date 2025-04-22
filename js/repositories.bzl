"""Declare runtime dependencies

These are needed for local dev, and users must install them as well.
See https://docs.bazel.build/versions/main/skylark/deploying.html#dependencies
"""

load("//js/private:maybe.bzl", http_archive = "maybe_http_archive")

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
        sha256 = "0b9b764ee5af1cbec01bcd2ca9ebd4aa4bbd700b17d7b8bb015769195fd88d20",
        strip_prefix = "bazel-lib-2.15.0",
        url = "https://github.com/bazel-contrib/bazel-lib/releases/download/v2.15.0/bazel-lib-v2.15.0.tar.gz",
    )
