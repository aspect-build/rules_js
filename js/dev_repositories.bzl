"""Our "development" dependencies

Users should *not* need to install these. If users see a load()
statement from these, that's a bug in our distribution.
"""

# buildifier: disable=bzl-visibility
load("//js/private:maybe.bzl", http_archive = "maybe_http_archive")

def rules_js_dev_dependencies():
    "Fetch repositories used for developing the rules"
    http_archive(
        name = "bazel_skylib",
        sha256 = "66ffd9315665bfaafc96b52278f57c7e2dd09f5ede279ea6d39b2be471e7e3aa",
        urls = ["https://github.com/bazelbuild/bazel-skylib/releases/download/1.4.2/bazel-skylib-1.4.2.tar.gz"],
    )

    http_archive(
        name = "io_bazel_stardoc",
        sha256 = "3fd8fec4ddec3c670bd810904e2e33170bedfe12f90adf943508184be458c8bb",
        urls = ["https://github.com/bazelbuild/stardoc/releases/download/0.5.3/stardoc-0.5.3.tar.gz"],
    )

    http_archive(
        name = "buildifier_prebuilt",
        sha256 = "72b5bb0853aac597cce6482ee6c62513318e7f2c0050bc7c319d75d03d8a3875",
        strip_prefix = "buildifier-prebuilt-6.3.3",
        urls = ["https://github.com/keith/buildifier-prebuilt/archive/6.3.3.tar.gz"],
    )

    http_archive(
        name = "aspect_rules_lint",
        sha256 = "6e32df708b40ea8c6d4482eeaf8fd6afaa8798d0028654ba25b667b5aee5707c",
        strip_prefix = "rules_lint-0.7.0",
        url = "https://github.com/aspect-build/rules_lint/releases/download/v0.7.0/rules_lint-v0.7.0.tar.gz",
    )
