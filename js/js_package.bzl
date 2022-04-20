"wrapper macro for js_package rule"

load("//js/private:js_package.bzl", lib = "js_package_lib")

_js_package = rule(
    implementation = lib.js_package_impl,
    provides = lib.provides,
    attrs = lib.attrs,
)

def js_package(name, remap_paths = None, **kwargs):
    if remap_paths == None:
        remap_paths = {"/" + native.package_name(): ""}
    _js_package(
        name = name,
        remap_paths = remap_paths,
        is_windows = select({
            "@bazel_tools//src/conditions:host_windows": True,
            "//conditions:default": False,
        }),
        **kwargs
    )
