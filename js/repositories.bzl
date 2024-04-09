"""Declare runtime dependencies

These are needed for local dev, and users must install them as well.
See https://docs.bazel.build/versions/main/skylark/deploying.html#dependencies
"""

load("//js/private:maybe.bzl", http_archive = "maybe_http_archive")

# buildifier: disable=function-docstring
def rules_js_dependencies():
    http_archive(
        name = "bazel_skylib",
        sha256 = "b8a1527901774180afc798aeb28c4634bdccf19c4d98e7bdd1ce79d1fe9aaad7",
        urls = ["https://github.com/bazelbuild/bazel-skylib/releases/download/1.4.1/bazel-skylib-1.4.1.tar.gz"],
    )

    http_archive(
        name = "rules_nodejs",
        sha256 = "dddd60acc3f2f30359bef502c9d788f67e33814b0ddd99aa27c5a15eb7a41b8c",
        strip_prefix = "rules_nodejs-6.1.0",
        url = "https://github.com/bazelbuild/rules_nodejs/releases/download/v6.1.0/rules_nodejs-v6.1.0.tar.gz",
    )

    http_archive(
        name = "aspect_bazel_lib",
        sha256 = "357dad9d212327c35d9244190ef010aad315e73ffa1bed1a29e20c372f9ca346",
        strip_prefix = "bazel-lib-2.7.0",
        url = "https://github.com/aspect-build/bazel-lib/releases/download/v2.7.0/bazel-lib-v2.7.0.tar.gz",
    )
