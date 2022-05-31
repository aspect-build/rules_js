"""Rules for running JavaScript programs"""

load(
    "//js/private:js_binary.bzl",
    _js_binary = "js_binary",
    _js_binary_lib = "js_binary_lib",
    _js_test = "js_test",
)
load(
    "//js/private:js_package.bzl",
    _JsPackageInfo = "JsPackageInfo",
    _js_package = "js_package",
    _js_package_lib = "js_package_lib",
)
load(
    "//js/private:link_js_package.bzl",
    _link_js_package = "link_js_package",
    _link_js_package_dep = "link_js_package_dep",
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

js_package = _js_package
JsPackageInfo = _JsPackageInfo

link_js_package = _link_js_package
link_js_package_dep = _link_js_package_dep

# export the starlark libraries as a public API
js_binary_lib = _js_binary_lib
js_package_lib = _js_package_lib
