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
        sha256 = "83d2bb029c2a9a06a474c8748d1221a92a7ca02222dcf49a0b567825c4e3f1ce",
        strip_prefix = "rules_nodejs-6.3.0",
        url = "https://github.com/bazel-contrib/rules_nodejs/releases/download/v6.3.0/rules_nodejs-v6.3.0.tar.gz",
    )

    http_archive(
        name = "aspect_bazel_lib",
        sha256 = "f93d386d8d0b0149031175e81df42a488be4267c3ca2249ba5321c23c60bc1f0",
        strip_prefix = "bazel-lib-2.9.1",
        url = "https://github.com/aspect-build/bazel-lib/releases/download/v2.9.1/bazel-lib-v2.9.1.tar.gz",
    )
