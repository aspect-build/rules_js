"npm_link_package rule"

load(":npm_link_package_store.bzl", "npm_link_package_store")
load(":npm_package_store.bzl", "npm_package_store")
load(":utils.bzl", "utils")

def npm_link_package(
        name,
        src,
        deps = {},
        auto_manual = True,
        visibility = ["//visibility:public"],
        **kwargs):
    """"Create a package store entry with the provided source and link to node_modules.

    This is a convenience macro that creates both an `npm_package_store` and a a single `npm_link_package_store`
    to link the package into `node_modules/<package>`.

    A `{name}/dir` filegroup is also generated that refers to a directory artifact can be used to access
    the package directory for creating entry points or accessing files in the package.

    Args:
        name: The name of the link target to create if `link` is True.
            For first-party deps linked across a workspace, the name must match in all packages
            being linked as it is used to derive the package store link target name.
        src: the target to link; may only to be specified when linking in the root package
        deps: list of npm_package_store; may only to be specified when linking in the root package
        auto_manual: whether or not to automatically add a manual tag to the generated targets
            Links tagged "manual" dy default is desirable so that they are not built by `bazel build ...` if they
            are unused downstream. For 3rd party deps, this is particularly important so that 3rd party deps are
            not fetched at all unless they are used.
        visibility: the visibility of the link target
        **kwargs: see attributes of npm_package_store rule

    Returns:
        Label of the npm_link_package_store
    """
    store_target_name = "{package_store_root}/{name}".format(
        name = name,
        package_store_root = utils.package_store_root,
    )

    tags = kwargs.pop("tags", [])
    if auto_manual and "manual" not in tags:
        tags.append("manual")

    # link the package store when linking at the root
    npm_package_store(
        name = store_target_name,
        src = src,
        deps = deps,
        visibility = ["//visibility:public"],
        tags = tags,
        **kwargs
    )

    link_target = ":{}".format(name)

    # create the npm package store for this package
    npm_link_package_store(
        name = name,
        src = ":{store_target_name}".format(store_target_name = store_target_name),
        tags = tags,
        visibility = visibility,
    )

    # filegroup target that provides a single file which is
    # package directory for use in $(execpath) and $(rootpath)
    native.filegroup(
        name = "{}/dir".format(name),
        srcs = [link_target],
        output_group = utils.package_directory_output_group,
        tags = tags,
        visibility = visibility,
    )

    return link_target
