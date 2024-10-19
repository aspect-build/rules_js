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
        sha256 = "0514c6530feb7abf94c9e3aeb4e33c89a21e2e9c9d9ed44cc217393bbf05ca9c",
        strip_prefix = "rules_nodejs-6.3.1",
        url = "https://github.com/bazel-contrib/rules_nodejs/releases/download/v6.3.1/rules_nodejs-v6.3.1.tar.gz",
    )

    http_archive(
        name = "aspect_bazel_lib",
        sha256 = "a272d79bb0ac6b6965aa199b1f84333413452e87f043b53eca7f347a23a478e8",
        strip_prefix = "bazel-lib-2.9.3",
        url = "https://github.com/bazel-contrib/bazel-lib/releases/download/v2.9.3/bazel-lib-v2.9.3.tar.gz",
    )
