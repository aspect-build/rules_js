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
        sha256 = "b361863788b15d9d0cebf6803c22e8d1afa689a0eefef96dec46bcce30527090",
        strip_prefix = "rules_nodejs-6.3.4",
        url = "https://github.com/bazel-contrib/rules_nodejs/releases/download/v6.3.4/rules_nodejs-v6.3.4.tar.gz",
    )

    http_archive(
        name = "aspect_bazel_lib",
        sha256 = "40ba9d0f62deac87195723f0f891a9803a7b720d7b89206981ca5570ef9df15b",
        strip_prefix = "bazel-lib-2.14.0",
        url = "https://github.com/bazel-contrib/bazel-lib/releases/download/v2.14.0/bazel-lib-v2.14.0.tar.gz",
    )
