"""Rules for running JavaScript programs"""

load(
    "//js/private:js_binary.bzl",
    _js_binary = "js_binary",
    _js_binary_lib = "js_binary_lib",
    _js_test = "js_test",
)
load(
    "//js/private:npm_package.bzl",
    _JsPackageInfo = "JsPackageInfo",
    _npm_package = "npm_package",
    _npm_package_lib = "npm_package_lib",
)
load(
    "//js/private:link_npm_package.bzl",
    _link_npm_package = "link_npm_package",
    _link_npm_package_dep = "link_npm_package_dep",
)
load(
    "//js/private:pnpm_utils.bzl",
    _pnpm_utils = "pnpm_utils",
)

def js_binary(**kwargs):
    _js_binary(
        enable_runfiles = select({
            "@aspect_rules_js//js/private:enable_runfiles": True,
            "//conditions:default": False,
        }),
        **kwargs
    )

def js_test(**kwargs):
    _js_test(
        enable_runfiles = select({
            "@aspect_rules_js//js/private:enable_runfiles": True,
            "//conditions:default": False,
        }),
        **kwargs
    )

npm_package = _npm_package
JsPackageInfo = _JsPackageInfo

link_npm_package = _link_npm_package
link_npm_package_dep = _link_npm_package_dep

# export the starlark libraries as a public API
js_binary_lib = _js_binary_lib
npm_package_lib = _npm_package_lib

# export constants since users might not always have syntax sugar
constants = struct(
    # Prefix for link_npm_package_direct links
    direct_link_prefix = _pnpm_utils.direct_link_prefix,
    # Prefix for link_npm_package_store links
    store_link_prefix = _pnpm_utils.store_link_prefix,
    # Suffix for package directory filegroup and alias targets
    dir_suffix = _pnpm_utils.dir_suffix,
)

# export utils since users might not always have syntax sugar
utils = struct(
    # Prefix for link_npm_package_direct links
    bazel_name = _pnpm_utils.bazel_name,
)
