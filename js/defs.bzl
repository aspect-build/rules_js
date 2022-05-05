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
    _link_js_package_direct = "link_js_package_direct",
    _link_js_package_store = "link_js_package_store",
)
load("//js/private:pnpm_utils.bzl", _pnpm_utils = "pnpm_utils")

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

def link_js_package(name, **kwargs):
    """"Public API macro around link_js_package_store and link_js_package_direct rules.

    Links a package to the virtual store and directly to node_modules.

    Args:
        name: name of the link_js_package_direct target
        **kwargs: see attributes of link_js_package_store rule
    """

    # link the virtual store
    _link_js_package_store(
        name = "{}{}".format(name, _pnpm_utils.store_postfix),
        **kwargs
    )

    # Link as a direct dependency in node_modules
    _link_js_package_direct(
        name = name,
        src = ":{}{}".format(name, _pnpm_utils.store_postfix),
        tags = kwargs.get("tags", None),
        visibility = kwargs.get("visibility", []),
    )

    # filegroup target that provides a single file which is
    # package directory for use in $(execpath) and $(rootpath)
    native.filegroup(
        name = "{}{}".format(name, _pnpm_utils.dir_postfix),
        srcs = [":{}".format(name)],
        output_group = _pnpm_utils.package_directory_output_group,
        tags = kwargs.get("tags", None),
        visibility = kwargs.get("visibility", []),
    )

# export the starlark libraries as a public API
js_binary_lib = _js_binary_lib
js_package_lib = _js_package_lib
