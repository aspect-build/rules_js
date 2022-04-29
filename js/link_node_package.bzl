"wrapper macro for link_node_package rule"

load("//js/private:link_node_package.bzl", lib = "link_node_package_lib")

_link_node_package = rule(
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

def link_node_package(name, **kwargs):
    """"Wrapper around link_node_package rule.

    Args:
        name: name of the resulting link_node_package target
        **kwargs: see attributes of link_node_package rule
    """
    _link_node_package(
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
            output_group = "linked_node_package_dir",
            tags = kwargs.get("tags", None),
            visibility = kwargs.get("visibility", []),
        )
