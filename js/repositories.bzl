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
        sha256 = "732aa2aeef9ba629cd7fa1cb30da07e6b696ed78706b08d84d5d8601982f38b1",
        strip_prefix = "rules_nodejs-6.3.3",
        url = "https://github.com/bazel-contrib/rules_nodejs/releases/download/v6.3.3/rules_nodejs-v6.3.3.tar.gz",
    )

    http_archive(
        name = "aspect_bazel_lib",
        sha256 = "57a777c5d4d0b79ad675995ee20fc1d6d2514a1ef3000d98f5c70cf0c09458a3",
        strip_prefix = "bazel-lib-2.13.0",
        url = "https://github.com/bazel-contrib/bazel-lib/releases/download/v2.13.0/bazel-lib-v2.13.0.tar.gz",
    )
