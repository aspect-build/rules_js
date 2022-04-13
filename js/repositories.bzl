"""Declare runtime dependencies

These are needed for local dev, and users must install them as well.
See https://docs.bazel.build/versions/main/skylark/deploying.html#dependencies
"""

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("@bazel_tools//tools/build_defs/repo:utils.bzl", "maybe")

versions = struct(
    aspect_bazel_lib = "0.9.5",
    rules_nodejs = "5.4.0",
    # Users can easily override the typescript version just by declaring their own http_archive
    # named "npm_typescript" prior to calling rules_js_dependencies.
    typescript = "4.6.3",
)

# WARNING: any changes in this function may be BREAKING CHANGES for users
# because we'll fetch a dependency which may be different from one that
# they were previously fetching later in their WORKSPACE setup, and now
# ours took precedence. Such breakages are challenging for users, so any
# changes in this function should be marked as BREAKING in the commit message
# and released only in semver majors.
def rules_js_dependencies():
    # The minimal version of bazel_skylib we require
    maybe(
        http_archive,
        name = "bazel_skylib",
        sha256 = "c6966ec828da198c5d9adbaa94c05e3a1c7f21bd012a0b29ba8ddbccb2c93b0d",
        urls = [
            "https://github.com/bazelbuild/bazel-skylib/releases/download/1.1.1/bazel-skylib-1.1.1.tar.gz",
            "https://mirror.bazel.build/github.com/bazelbuild/bazel-skylib/releases/download/1.1.1/bazel-skylib-1.1.1.tar.gz",
        ],
    )

    # TEMP TEMP >>> rules_nodejs overide
    maybe(
        http_archive,
        name = "rules_nodejs",
        sha256 = "48146434180db3f5be9be0890d58cf3250cc81acc652a04816aea0c0d06cfbd9",
        strip_prefix = "rules_nodejs-cd48e24da0f44b9f49cb4b0254a8747b987970fe",
        url = "https://github.com/gregmagolan/rules_nodejs/archive/cd48e24da0f44b9f49cb4b0254a8747b987970fe.tar.gz",
    )
    # TEMP TEMP <<< rules_nodejs overide

    maybe(
        http_archive,
        name = "rules_nodejs",
        sha256 = "1f9fca05f4643d15323c2dee12bd5581351873d45457f679f84d0fe0da6839b7",
        urls = ["https://github.com/bazelbuild/rules_nodejs/releases/download/{0}/rules_nodejs-core-{0}.tar.gz".format(versions.rules_nodejs)],
    )

    maybe(
        http_archive,
        name = "aspect_bazel_lib",
        sha256 = "b5bdbfe570f5463607b7eff24f239c2f7ec9b2edc8db45a225e9575c4366b410",
        strip_prefix = "bazel-lib-{}".format(versions.aspect_bazel_lib),
        url = "https://github.com/aspect-build/bazel-lib/archive/refs/tags/v{}.tar.gz".format(versions.aspect_bazel_lib),
    )

    maybe(
        http_archive,
        name = "npm_typescript",
        build_file = "@aspect_rules_js//ts:BUILD.typescript",
        sha256 = "70d5d30a8ee92004e529c41fc05d5c7993f7a4ddea33b4c0909896936230964d",
        urls = ["https://registry.npmjs.org/typescript/-/typescript-{}.tgz".format(versions.typescript)],
    )
