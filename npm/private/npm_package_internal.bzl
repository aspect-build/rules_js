"npm_package_internal rule"

load("@bazel_skylib//lib:dicts.bzl", "dicts")
load(":npm_package.bzl", _npm_package_lib = "npm_package_lib")

_INTERNAL_ATTRS = dicts.add(_npm_package_lib.attrs, {
    "provide_source_directory": attr.bool(
        doc = """If true, source directories are provided and not copied to the output tree.

        For internal rules_js use only.""",
    ),
})

npm_package_internal = rule(
    implementation = _npm_package_lib.implementation,
    attrs = _INTERNAL_ATTRS,
    provides = _npm_package_lib.provides,
)
