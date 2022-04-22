"wrapper macro for node_package rule"

load("//js/private:node_package.bzl", lib = "node_package_lib")

_node_package = rule(
    doc = """Defines a node package that is linked into a node_modules tree.

The term "package" is defined at
<https://nodejs.org/docs/latest-v16.x/api/packages.html>

The node package is linked with a pnpm style symlinked node_modules output tree.

See https://pnpm.io/symlinked-node-modules-structure for more information on
the symlinked node_modules structure.
Npm may also support a symlinked node_modules structure called
"Isolated mode" in the future:
https://github.com/npm/rfcs/blob/main/accepted/0042-isolated-mode.md.
""",
    implementation = lib.impl,
    provides = lib.provides,
    attrs = lib.attrs,
)

def node_package(name, **kwargs):
    """"Wrapper around node_package rule.

    Args:
        name: name of the resulting node_package target
        **kwargs: see attributes of node_package rule
    """
    _node_package(
        name = name,
        is_windows = select({
            "@bazel_tools//src/conditions:host_windows": True,
            "//conditions:default": False,
        }),
        **kwargs
    )

    # If not indirect, create a {name}__dir
    # filegroup target that provides a single file which is the root
    # node_modules directory for use in $(execpath) and $(rootpath)
    if not kwargs.get("indirect", False):
        native.filegroup(
            name = "%s__dir" % name,
            srcs = [":%s" % name],
            output_group = "node_modules_directory",
        )
