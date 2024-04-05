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

    # DNL: testing rules_nodejs from HEAD
    http_archive(
        name = "rules_nodejs",
        integrity = "sha256-7oUb51pi91gSXCT8tPEE7+qyW6VD8Wr7ti3lMBPg2O0=",
        strip_prefix = "rules_nodejs-113efd11503a0c622887e945c237089c54938b77",
        url = "https://github.com/bazelbuild/rules_nodejs/archive/113efd11503a0c622887e945c237089c54938b77.tar.gz",
    )

    http_archive(
        name = "aspect_bazel_lib",
        sha256 = "f9a0bb072aef719859aae5ad37722e97812ffffb263fd56a36cd8614a2e5d199",
        strip_prefix = "bazel-lib-1.42.2",
        url = "https://github.com/aspect-build/bazel-lib/releases/download/v1.42.2/bazel-lib-v1.42.2.tar.gz",
    )

    http_archive(
        name = "bazel_features",
        sha256 = "f3082bfcdca73dc77dcd68faace806135a2e08c230b02b1d9fbdbd7db9d9c450",
        strip_prefix = "bazel_features-0.1.0",
        url = "https://github.com/bazel-contrib/bazel_features/releases/download/v0.1.0/bazel_features-v0.1.0.tar.gz",
    )
