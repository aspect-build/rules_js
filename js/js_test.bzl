"wrapper macro for js_test rule"

load("//js/private:js_binary.bzl", lib = "js_binary_lib")

_js_test = rule(
    implementation = lib.js_binary_impl,
    attrs = lib.attrs,
    test = True,
    toolchains = lib.toolchains,
)

def js_test(**kwargs):
    """Alias of js_binary which can be used with `bazel test`

    Args:
      **kwargs: see js_binary attributes
    """
    _js_test(
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
