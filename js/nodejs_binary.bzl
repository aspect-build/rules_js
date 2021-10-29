"nodejs_binary rule"

load("//js/private:nodejs_binary.bzl", lib = "nodejs_binary_lib")

_nodejs_binary = rule(
    implementation = lib.nodejs_binary_impl,
    attrs = lib.attrs,
    executable = True,
    toolchains = lib.toolchains,
)

def nodejs_binary(**kwargs):
    _nodejs_binary(
        is_windows = select({
            "@bazel_tools//src/conditions:host_windows": True,
            "//conditions:default": False,
        }),
        enable_runfiles = select({
            "@build_aspect_rules_js//js/private:enable_runfiles": True,
            "//conditions:default": False,
        }),
        **kwargs
    )
