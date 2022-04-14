"wrapper macro for nodejs_binary rule"

load("//js/private:nodejs_binary.bzl", _lib = "nodejs_binary_lib")
load("@bazel_skylib//lib:dicts.bzl", "dicts")

_nodejs_binary = rule(
    implementation = _lib.nodejs_binary_impl,
    attrs = _lib.attrs,
    executable = True,
    toolchains = _lib.toolchains,
)

# export the starlark library as a public API
lib = _lib

def nodejs_binary(**kwargs):
    _nodejs_binary(
        is_windows = select({
            "@bazel_tools//src/conditions:host_windows": True,
            "//conditions:default": False,
        }),
        enable_runfiles = select({
            "@aspect_rules_js//js/private:enable_runfiles": True,
            "//conditions:default": False,
        }),
        **kwargs
    )
