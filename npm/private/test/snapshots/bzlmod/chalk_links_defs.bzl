"@generated by @aspect_rules_js//npm/private:npm_import.bzl for npm package chalk@5.0.1"

# buildifier: disable=bzl-visibility
load("@aspect_rules_js//npm/private:npm_package_store_internal.bzl", _npm_package_store = "npm_package_store_internal")

# buildifier: disable=bzl-visibility
load("@aspect_rules_js//npm/private:npm_link_package_store.bzl", _npm_link_package_store = "npm_link_package_store")

# Generated npm_package_store targets for npm package chalk@5.0.1
# buildifier: disable=function-docstring
def npm_imported_package_store(name):
    root_package = ""
    is_root = native.package_name() == root_package
    if not is_root:
        msg = "No store links in bazel package '%s' for npm package npm package chalk@5.0.1. This is neither the root package nor a link package of this package." % native.package_name()
        fail(msg)
    if not name.endswith("/chalk"):
        msg = "name must end with one of '/chalk' when linking the store in package 'chalk'; recommended value is 'node_modules/chalk'"
        fail(msg)
    link_root_name = name[:-len("/chalk")]

    deps = {
        ":.aspect_rules_js/{}/chalk@5.0.1/pkg".format(link_root_name): "chalk",
    }
    ref_deps = {}

    store_target_name = ".aspect_rules_js/{}/chalk@5.0.1".format(link_root_name)

    # reference target used to avoid circular deps
    _npm_package_store(
        name = "{}/ref".format(store_target_name),
        package = "chalk",
        version = "5.0.1",
        dev = False,
        tags = ["manual"],
        use_declare_symlink = select({
            Label("@aspect_rules_js//js:allow_unresolved_symlinks"): True,
            "//conditions:default": False,
        }),
    )

    # post-lifecycle target with reference deps for use in terminal target with transitive closure
    _npm_package_store(
        name = "{}/pkg".format(store_target_name),
        src = "{}/pkg_lc".format(store_target_name) if False else "@chalk_501//:pkg",
        package = "chalk",
        version = "5.0.1",
        dev = False,
        deps = ref_deps,
        tags = ["manual"],
        use_declare_symlink = select({
            Label("@aspect_rules_js//js:allow_unresolved_symlinks"): True,
            "//conditions:default": False,
        }),
    )

    # virtual store target with transitive closure of all npm package dependencies
    _npm_package_store(
        name = store_target_name,
        src = None if True else "@chalk_501//:pkg",
        package = "chalk",
        version = "5.0.1",
        dev = False,
        deps = deps,
        visibility = ["//visibility:public"],
        tags = ["manual"],
        use_declare_symlink = select({
            Label("@aspect_rules_js//js:allow_unresolved_symlinks"): True,
            "//conditions:default": False,
        }),
    )

    # filegroup target that provides a single file which is
    # package directory for use in $(execpath) and $(rootpath)
    native.filegroup(
        name = "{}/dir".format(store_target_name),
        srcs = [":{}".format(store_target_name)],
        output_group = "package_directory",
        visibility = ["//visibility:public"],
        tags = ["manual"],
    )

# Generated npm_package_store and npm_link_package_store targets for npm package chalk@5.0.1
# buildifier: disable=function-docstring
def npm_link_imported_package_store(name):
    link_packages = {
        "examples/npm_package/libs/lib_a": ["chalk"],
        "npm/private/test/npm_package": ["chalk"],
    }
    if native.package_name() in link_packages:
        link_aliases = link_packages[native.package_name()]
    else:
        link_aliases = ["chalk"]

    link_alias = None
    for _link_alias in link_aliases:
        if name.endswith("/{}".format(_link_alias)):
            # longest match wins
            if not link_alias or len(_link_alias) > len(link_alias):
                link_alias = _link_alias
    if not link_alias:
        msg = "name must end with one of '/{{ {link_aliases_comma_separated} }}' when called from package 'chalk'; recommended value(s) are 'node_modules/{{ {link_aliases_comma_separated} }}'".format(link_aliases_comma_separated = ", ".join(link_aliases))
        fail(msg)

    link_root_name = name[:-len("/{}".format(link_alias))]
    store_target_name = ".aspect_rules_js/{}/chalk@5.0.1".format(link_root_name)

    # terminal package store target to link
    _npm_link_package_store(
        name = name,
        package = link_alias,
        src = "//:{}".format(store_target_name),
        visibility = ["//visibility:public"],
        tags = ["manual"],
        use_declare_symlink = select({
            Label("@aspect_rules_js//js:allow_unresolved_symlinks"): True,
            "//conditions:default": False,
        }),
    )

    # filegroup target that provides a single file which is
    # package directory for use in $(execpath) and $(rootpath)
    native.filegroup(
        name = "{}/dir".format(name),
        srcs = [":{}".format(name)],
        output_group = "package_directory",
        visibility = ["//visibility:public"],
        tags = ["manual"],
    )

    return [":{}".format(name)] if True else []

# Generated npm_package_store and npm_link_package_store targets for npm package chalk@5.0.1
# buildifier: disable=function-docstring
def npm_link_imported_package(
        name = "node_modules",
        link = None,
        fail_if_no_link = True):
    root_package = ""
    link_packages = {
        "examples/npm_package/libs/lib_a": ["chalk"],
        "npm/private/test/npm_package": ["chalk"],
    }

    if link_packages and link != None:
        fail("link attribute cannot be specified when link_packages are set")

    is_link = (link == True) or (link == None and native.package_name() in link_packages)
    is_root = native.package_name() == root_package

    if fail_if_no_link and not is_root and not link:
        msg = "Nothing to link in bazel package '%s' for npm package npm package chalk@5.0.1. This is neither the root package nor a link package of this package." % native.package_name()
        fail(msg)

    link_targets = []
    scoped_targets = {}

    if is_link:
        link_aliases = []
        if native.package_name() in link_packages:
            link_aliases = link_packages[native.package_name()]
        if not link_aliases:
            link_aliases = ["chalk"]
        for link_alias in link_aliases:
            link_target_name = "{}/{}".format(name, link_alias)
            npm_link_imported_package_store(name = link_target_name)
            if True:
                link_targets.append(":{}".format(link_target_name))
                if len(link_alias.split("/", 1)) > 1:
                    link_scope = link_alias.split("/", 1)[0]
                    if link_scope not in scoped_targets:
                        scoped_targets[link_scope] = []
                    scoped_targets[link_scope].append(link_target_name)

    if is_root:
        npm_imported_package_store("{}/chalk".format(name))

    return (link_targets, scoped_targets)
