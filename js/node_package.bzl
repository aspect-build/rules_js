"wrapper macro for node_package rule"

load("//js/private:node_package.bzl", lib = "node_package_lib")

_node_package = rule(
    implementation = lib.node_package_impl,
    provides = lib.provides,
    attrs = lib.attrs,
)

def node_package(name, remap_paths = None, **kwargs):
    if remap_paths == None:
        remap_paths = {"/" + native.package_name(): ""}
    _node_package(
        name = name,
        remap_paths = remap_paths,
        is_windows = select({
            "@bazel_tools//src/conditions:host_windows": True,
            "//conditions:default": False,
        }),
        **kwargs
    )
