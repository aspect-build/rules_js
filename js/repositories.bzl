"""Declare runtime dependencies

These are needed for local dev, and users must install them as well.
See https://docs.bazel.build/versions/main/skylark/deploying.html#dependencies
"""

load("//js/private:maybe.bzl", http_archive = "maybe_http_archive")

def rules_js_dependencies():
    "Dependencies for users of aspect_rules_js"

    http_archive(
        name = "bazel_skylib",
        sha256 = "b8a1527901774180afc798aeb28c4634bdccf19c4d98e7bdd1ce79d1fe9aaad7",
        urls = [
            "https://github.com/bazelbuild/bazel-skylib/releases/download/1.4.1/bazel-skylib-1.4.1.tar.gz",
        ],
    )

    http_archive(
        name = "rules_nodejs",
        sha256 = "764a3b3757bb8c3c6a02ba3344731a3d71e558220adcb0cf7e43c9bba2c37ba8",
        urls = ["https://github.com/bazelbuild/rules_nodejs/releases/download/5.8.2/rules_nodejs-core-5.8.2.tar.gz"],
    )

    http_archive(
        name = "aspect_bazel_lib",
        sha256 = "b4cd1114874ab15f794134eefbc254eb89d3e1de640bf4a11f2f402e886ad29e",
        strip_prefix = "bazel-lib-1.27.2",
        url = "https://github.com/aspect-build/bazel-lib/releases/download/v1.27.2/bazel-lib-v1.27.2.tar.gz",
    )
