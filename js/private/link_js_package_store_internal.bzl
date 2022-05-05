"link_js_package_store_internal rule"

load("@bazel_skylib//lib:dicts.bzl", "dicts")
load(":link_js_package.bzl", _link_js_package_store_lib = "link_js_package_store_lib")
load(":js_package.bzl", "JsPackageInfo")

_INTERNAL_ATTRS_STORE = dicts.add(_link_js_package_store_lib.attrs, {
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
        doc = """The package name to link to.
        
        Takes precendance over the package name in the JsPackageInfo src.""",
        mandatory = True,
    ),
    "version": attr.string(
        doc = """The package version to link to.
        
        Takes precendance over the package version in the JsPackageInfo src.""",
        mandatory = True,
    ),
})

link_js_package_store_internal = rule(
    implementation = _link_js_package_store_lib.implementation,
    attrs = _INTERNAL_ATTRS_STORE,
    provides = _link_js_package_store_lib.provides,
)
