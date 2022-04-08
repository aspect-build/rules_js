"wrapper macro for nodejs_package rule"

load("//js/private:nodejs_package.bzl", lib = "nodejs_package_lib")

_nodejs_package = rule(
    implementation = lib.impl,
    provides = lib.provides,
    attrs = lib.attrs,
)

def nodejs_package(name, **kwargs):
    _nodejs_package(
        name = name,
        is_windows = select({
            "@bazel_tools//src/conditions:host_windows": True,
            "//conditions:default": False,
        }),
        **kwargs
    )

    # Create a {name}_dir target which exposes the node_modules_directory output group
    # for use in $(execpath) and $(rootpath)
    src = kwargs.get("src", None)
    transitive = kwargs.get("transitive", False)
    if src and not transitive:
        native.filegroup(
            name = "%s__dir" % name,
            srcs = [":%s" % name],
            output_group = "node_modules_directory"
        )
