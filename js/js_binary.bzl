"wrapper macro for js_binary rule"

load("//js/private:js_binary.bzl", _lib = "js_binary_lib")

_js_binary = rule(
    implementation = _lib.js_binary_impl,
    attrs = _lib.attrs,
    executable = True,
    toolchains = _lib.toolchains,
)

# export the starlark library as a public API
lib = _lib

def js_binary(**kwargs):
    _js_binary(
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
