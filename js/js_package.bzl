"wrapper macro for js_package rule"

load("//js/private:js_package.bzl", lib = "js_package_lib")

_js_package = rule(
    implementation = lib.impl,
    provides = lib.provides,
    attrs = lib.attrs,
)

def js_package(name, **kwargs):
    _js_package(
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
    indirect = kwargs.get("indirect", False)
    if src and not indirect:
        native.filegroup(
            name = "%s__dir" % name,
            srcs = [":%s" % name],
            output_group = "node_modules_directory"
        )
