"link_js_package_internal rule"

load("@bazel_skylib//lib:dicts.bzl", "dicts")
load(":link_js_package.bzl", _link_js_package_lib = "link_js_package_lib")
load(":js_package.bzl", "JsPackageInfo")

_INTERNAL_ATTRS = dicts.add(_link_js_package_lib.attrs, {
    "src": attr.label(
        doc = """A js_package target or or any other target that provides a JsPackageInfo.

        Can be left unspecified to allow for link_js_package "reference" targets. `link_js_package`
        targets without a `src` are used internally by `npm_import` to create "reference"
        `link_js_package` targets in order to break circular dependencies between 3rd party npm
        dependencies. This pattern is not recommended outside of `npm_import` as it adds
        complication. Outside our `npm_import` you should structure you `link_js_package` targets in
        a DAG (without cycles).
        """,
        providers = [JsPackageInfo],
    ),
    "package": attr.string(
        doc = """The package name being linked.""",
        mandatory = True,
    ),
    "version": attr.string(
        doc = """The package version being linked.""",
        mandatory = True,
    ),
})

_link_js_package_internal = rule(
    implementation = _link_js_package_lib.implementation,
    attrs = _INTERNAL_ATTRS,
    provides = _link_js_package_lib.provides,
)

def link_js_package_internal(name, **kwargs):
    """"For internal use"""
    _link_js_package_internal(
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
