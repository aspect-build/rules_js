"""Declare runtime dependencies

These are needed for local dev, and users must install them as well.
See https://docs.bazel.build/versions/main/skylark/deploying.html#dependencies
"""

load("//js/private:maybe.bzl", http_archive = "maybe_http_archive")

def rules_js_dependencies():
    "Dependencies for users of aspect_rules_js"

    http_archive(
        name = "bazel_skylib",
        sha256 = "74d544d96f4a5bb630d465ca8bbcfe231e3594e5aae57e1edbf17a6eb3ca2506",
        urls = ["https://github.com/bazelbuild/bazel-skylib/releases/download/1.3.0/bazel-skylib-1.3.0.tar.gz"],
    )

    http_archive(
        name = "rules_nodejs",
        sha256 = "08337d4fffc78f7fe648a93be12ea2fc4e8eb9795a4e6aa48595b66b34555626",
        urls = ["https://github.com/bazelbuild/rules_nodejs/releases/download/5.8.0/rules_nodejs-core-5.8.0.tar.gz"],
    )

    http_archive(
        name = "aspect_bazel_lib",
        sha256 = "ef83252dea2ed8254c27e65124b756fc9476be2b73a7799b7a2a0935937fc573",
        strip_prefix = "bazel-lib-1.24.2",
        url = "https://github.com/aspect-build/bazel-lib/releases/download/v1.24.2/bazel-lib-v1.24.2.tar.gz",
    )
