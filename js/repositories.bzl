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
        integrity = "sha256-w7yMsYGMkgKhVZJizhmB9T668fGzdEvRXThptjTtnpo=",
        strip_prefix = "rules_nodejs-d28957af10035c3030ffcb26ced95bb411a50692",
        url = "https://github.com/bazelbuild/rules_nodejs/archive/d28957af10035c3030ffcb26ced95bb411a50692.tar.gz",
        # sha256 = "a50986c7d2f2dc43a5b9b81a6245fd89bdc4866f1d5e316d9cef2782dd859292",
        # strip_prefix = "rules_nodejs-6.0.5",
        # url = "https://github.com/bazelbuild/rules_nodejs/releases/download/v6.0.5/rules_nodejs-v6.0.5.tar.gz",
    )

    http_archive(
        name = "aspect_bazel_lib",
        sha256 = "ac6392cbe5e1cc7701bbd81caf94016bae6f248780e12af4485d4a7127b4cb2b",
        strip_prefix = "bazel-lib-2.6.1",
        url = "https://github.com/aspect-build/bazel-lib/releases/download/v2.6.1/bazel-lib-v2.6.1.tar.gz",
    )

    http_archive(
        name = "bazel_features",
        sha256 = "f3082bfcdca73dc77dcd68faace806135a2e08c230b02b1d9fbdbd7db9d9c450",
        strip_prefix = "bazel_features-0.1.0",
        url = "https://github.com/bazel-contrib/bazel_features/releases/download/v0.1.0/bazel_features-v0.1.0.tar.gz",
    )
