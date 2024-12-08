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
        sha256 = "158619723f1d8bd535dd6b93521f4e03cf24a5e107126d05685fbd9540ccad10",
        strip_prefix = "rules_nodejs-6.3.2",
        url = "https://github.com/bazel-contrib/rules_nodejs/releases/download/v6.3.2/rules_nodejs-v6.3.2.tar.gz",
    )

    http_archive(
        name = "aspect_bazel_lib",
        sha256 = "349aabd3c2b96caeda6181eb0ae1f14f2a1d9f3cd3c8b05d57f709ceb12e9fb3",
        strip_prefix = "bazel-lib-2.9.4",
        url = "https://github.com/bazel-contrib/bazel-lib/releases/download/v2.9.4/bazel-lib-v2.9.4.tar.gz",
    )
