"wrapper macro for nodejs_package rule"

load("//js/private:nodejs_package.bzl", lib = "nodejs_package_lib")

_nodejs_package = rule(
    implementation = lib.nodejs_package_impl,
    provides = lib.provides,
    attrs = lib.attrs,
)

def nodejs_package(name, remap_paths = None, **kwargs):
    if remap_paths == None:
        remap_paths = {"/" + native.package_name(): ""}
    _nodejs_package(
        name = name,
        remap_paths = remap_paths,
        is_windows = select({
            "@bazel_tools//src/conditions:host_windows": True,
            "//conditions:default": False,
        }),
        **kwargs
    )
