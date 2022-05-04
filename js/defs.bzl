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
    _link_js_package_lib = "link_js_package_lib",
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
    """Alias of js_binary which can be used with `bazel test`

    Args:
      **kwargs: see js_binary attributes
    """
    _js_test(
        enable_runfiles = select({
            "@aspect_rules_js//js/private:enable_runfiles": True,
            "//conditions:default": False,
        }),
        **kwargs
    )

js_package = _js_package
JsPackageInfo = _JsPackageInfo

def link_js_package(name, **kwargs):
    """"Wrapper around link_js_package rule.

    Args:
        name: name of the resulting link_js_package target
        **kwargs: see attributes of link_js_package rule
    """
    _link_js_package(
        name = name,
        **kwargs
    )

    # If not indirect, create a {name}__dir
    # filegroup target that provides a single file which is the root
    # node_modules directory for use in $(execpath) and $(rootpath)
    if not kwargs.get("indirect", False):
        native.filegroup(
            name = "%s__dir" % name,
            srcs = [":%s" % name],
            output_group = "linked_js_package_dir",
            tags = kwargs.get("tags", None),
            visibility = kwargs.get("visibility", []),
        )

# export the starlark libraries as a public API
js_binary_lib = _js_binary_lib
js_package_lib = _js_package_lib
link_js_package_lib = _link_js_package_lib
