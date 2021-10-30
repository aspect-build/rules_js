"wrapper macro for nodejs_test rule"

load("//js/private:nodejs_binary.bzl", lib = "nodejs_binary_lib")

_nodejs_test = rule(
    implementation = lib.nodejs_binary_impl,
    attrs = lib.attrs,
    test = True,
    toolchains = lib.toolchains,
)

def nodejs_test(**kwargs):
    """Alias of nodejs_binary which can be used with `bazel test`

    Args:
      **kwargs: see nodejs_binary attributes
    """
    _nodejs_test(
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
