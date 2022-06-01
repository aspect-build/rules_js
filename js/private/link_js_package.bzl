"link_js_package rule"

load("@aspect_bazel_lib//lib:copy_directory.bzl", "copy_directory_action")
load("@bazel_skylib//lib:paths.bzl", "paths")
load("@rules_nodejs//nodejs:providers.bzl", "DeclarationInfo", "declaration_info")
load(":pnpm_utils.bzl", "pnpm_utils")
load(":js_package.bzl", "JsPackageInfo")

_LinkJsPackageInfo = provider(
    doc = "Internal use only",
    fields = {
        "label": "the label of the target the created this provider",
        "link_package": "package that this node package is linked at",
        "package": "name of this node package",
        "version": "version of this node package",
        "dep_refs": "list of dependency ref targets",
        "virtual_store_directory": "the TreeArtifact of this node package's virtual store location",
    },
)

_DOC_STORE = """Defines a node package that is linked into a node_modules tree.

The node package is linked with a pnpm style symlinked node_modules output tree.

The term "package" is defined at
<https://nodejs.org/docs/latest-v16.x/api/packages.html>

See https://pnpm.io/symlinked-node-modules-structure for more information on
the symlinked node_modules structure.
Npm may also support a symlinked node_modules structure called
"Isolated mode" in the future:
https://github.com/npm/rfcs/blob/main/accepted/0042-isolated-mode.md.
"""

_DOC_DIRECT = """Defines a node package that is linked into a node_modules tree as a direct dependency.

This is used in co-ordination with the link_js_package_store rule that links into the
node_modules/.apsect_rules_js virtual store with a pnpm style symlinked node_modules output tree.

The term "package" is defined at
<https://nodejs.org/docs/latest-v16.x/api/packages.html>

See https://pnpm.io/symlinked-node-modules-structure for more information on
the symlinked node_modules structure.
Npm may also support a symlinked node_modules structure called
"Isolated mode" in the future:
https://github.com/npm/rfcs/blob/main/accepted/0042-isolated-mode.md.
"""

_ATTRS_STORE = {
    "src": attr.label(
        doc = """A js_package target or or any other target that provides a JsPackageInfo.
        """,
        providers = [JsPackageInfo],
        mandatory = True,
    ),
    "deps": attr.label_list(
        doc = """Other node packages this one depends on.

        This should include *all* modules the program may need at runtime.

        > In typical usage, a node.js program sometimes requires modules which were
        > never declared as dependencies.
        > This pattern is typically used when the program has conditional behavior
        > that is enabled when the module is found (like a plugin) but the program
        > also runs without the dependency.
        > 
        > This is possible because node.js doesn't enforce the dependencies are sound.
        > All files under `node_modules` are available to any program.
        > In contrast, Bazel makes it possible to make builds hermetic, which means that
        > all dependencies of a program must be declared when running in Bazel's sandbox.
        """,
        providers = [_LinkJsPackageInfo],
    ),
    "package": attr.string(
        doc = """The package name to link to.

If unset, the package name in the JsPackageInfo src must be set.
If set, takes precendance over the package name in the JsPackageInfo src.
""",
    ),
    "version": attr.string(
        doc = """The package version being linked.

If unset, the package version in the JsPackageInfo src must be set.
If set, takes precendance over the package version in the JsPackageInfo src.
""",
    ),
    "_windows_constraint": attr.label(default = "@platforms//os:windows"),
}

_ATTRS_DIRECT = {
    "src": attr.label(
        doc = """The link_js_package target to link as a direct dependency.""",
        providers = [_LinkJsPackageInfo],
        mandatory = True,
    ),
}

def _impl_store(ctx):
    is_windows = ctx.target_platform_has_constraint(ctx.attr._windows_constraint[platform_common.ConstraintValueInfo])

    package = ctx.attr.package if ctx.attr.package else ctx.attr.src[JsPackageInfo].package
    version = ctx.attr.version if ctx.attr.version else ctx.attr.src[JsPackageInfo].version

    if not package:
        fail("No package name specified to link to. Package name must either be specified explicitly via `package` attribute or come from the `src` `JsPackageInfo`, typically a `js_package` target")
    if not version:
        fail("No package version specified to link to. Package version must either be specified explicitly via `version` attribute or come from the `src` `JsPackageInfo`, typically a `js_package` target")

    virtual_store_name = pnpm_utils.virtual_store_name(package, version)

    virtual_store_directory = None
    direct_files = []
    direct_dep_refs = []

    if ctx.attr.src:
        # output the package as a TreeArtifact to its virtual store location
        # "node_modules/{virtual_store_root}/{virtual_store_name}/node_modules/{package}"
        virtual_store_directory_path = paths.join("node_modules", pnpm_utils.virtual_store_root, virtual_store_name, "node_modules", package)

        if ctx.label.workspace_name:
            expected_short_path = paths.join("..", ctx.label.workspace_name, ctx.label.package, virtual_store_directory_path)
        else:
            expected_short_path = paths.join(ctx.label.package, virtual_store_directory_path)
        src_directory = ctx.attr.src[JsPackageInfo].directory
        if src_directory.short_path == expected_short_path:
            # the input is already the desired output; this is the pattern for
            # packages with lifecycle hooks
            virtual_store_directory = src_directory
        else:
            virtual_store_directory = ctx.actions.declare_directory(virtual_store_directory_path)
            copy_directory_action(ctx, src_directory, virtual_store_directory, is_windows = is_windows)
        direct_files.append(virtual_store_directory)

        for dep in ctx.attr.deps:
            # symlink the package's direct deps to its virtual store location
            dep_link_package = dep[_LinkJsPackageInfo].link_package
            if dep_link_package != ctx.label.package:
                if not ctx.label.package.startswith(dep_link_package + "/"):
                    msg = """link_js_package in %s package cannot depend on link_js_package in %s package.
deps of link_js_package must be in the same package or in a parent package.""" % (ctx.label.package, dep_link_package)
                    fail(msg)
            dep_package = dep[_LinkJsPackageInfo].package
            dep_version = dep[_LinkJsPackageInfo].version
            dep_virtual_store_directory = dep[_LinkJsPackageInfo].virtual_store_directory
            if dep_virtual_store_directory:
                # "node_modules/{virtual_store_root}/{virtual_store_name}/node_modules/{package}"
                dep_symlink_path = paths.join("node_modules", pnpm_utils.virtual_store_root, virtual_store_name, "node_modules", dep_package)
                dep_symlink = ctx.actions.declare_file(dep_symlink_path)
                ctx.actions.symlink(
                    output = dep_symlink,
                    target_file = dep_virtual_store_directory,
                )
                direct_files.append(dep_symlink)
            else:
                # this is a ref link_js_package, a downstream terminal link_js_package
                # for this npm depedency will create the dep symlinks for this dep;
                # this pattern is used to break circular dependencies between 3rd
                # party npm deps; it is not recommended for 1st party deps
                direct_dep_refs.append(dep)
    else:
        # if ctx.attr.src is _not_ set and ctx.attr.deps is, this is a terminal
        # package with deps being the transitive closure of deps;
        # this pattern is used to break circular dependencies between 3rd
        # party npm deps; it is not recommended for 1st party deps
        deps_map = {}
        for dep in ctx.attr.deps:
            # create a map of deps that have virtual store directories
            if dep[_LinkJsPackageInfo].virtual_store_directory:
                dep_package = dep[_LinkJsPackageInfo].package
                dep_version = dep[_LinkJsPackageInfo].version
                deps_map[pnpm_utils.pnpm_name(dep_package, dep_version)] = dep
            else:
                # this is a ref link_js_package, a downstream terminal link_js_package for this npm
                # depedency will create the dep symlinks for this dep; this pattern is used to break
                # for lifecycle hooks on 3rd party deps; it is not recommended for 1st party deps
                direct_dep_refs.append(dep)
        for dep in ctx.attr.deps:
            dep_package = dep[_LinkJsPackageInfo].package
            dep_version = dep[_LinkJsPackageInfo].version
            dep_virtual_store_name = pnpm_utils.virtual_store_name(dep_package, dep_version)
            dep_refs = dep[_LinkJsPackageInfo].dep_refs
            if dep_package == package and dep_version == version:
                # provide the node_modules directory for this package if found in the transitive_closure
                virtual_store_directory = dep[_LinkJsPackageInfo].virtual_store_directory
                if virtual_store_directory:
                    direct_files.append(virtual_store_directory)
            for dep_ref in dep_refs:
                dep_ref_package = dep_ref[_LinkJsPackageInfo].package
                dep_ref_version = dep_ref[_LinkJsPackageInfo].version
                if dep_ref_package == package and dep_ref_version == version:
                    pass
                else:
                    def_ref_pnpm_name = pnpm_utils.pnpm_name(dep_ref_package, dep_ref_version)
                    if not def_ref_pnpm_name in deps_map:
                        fail("Expecting {} to be in deps".format(def_ref_pnpm_name))
                    actual_dep = deps_map[def_ref_pnpm_name]
                    dep_ref_virtual_store_directory = actual_dep[_LinkJsPackageInfo].virtual_store_directory
                    if dep_ref_virtual_store_directory:
                        # "node_modules/{virtual_store_root}/{virtual_store_name}/node_modules/{package}"
                        dep_symlink_path = paths.join("node_modules", pnpm_utils.virtual_store_root, dep_virtual_store_name, "node_modules", dep_ref_package)
                        dep_symlink = ctx.actions.declare_file(dep_symlink_path)
                        ctx.actions.symlink(
                            output = dep_symlink,
                            target_file = dep_ref_virtual_store_directory,
                        )
                        direct_files.append(dep_symlink)

    direct_files = depset(direct = direct_files)
    files_depsets = [direct_files]
    runfiles = ctx.runfiles(transitive_files = direct_files)
    for dep in ctx.attr.deps:
        files_depsets.append(dep[DefaultInfo].files)
        runfiles = runfiles.merge(dep[DefaultInfo].data_runfiles)

    result = [
        DefaultInfo(files = depset(transitive = files_depsets), runfiles = runfiles),
        # Always assume that packages provide typings, so we don't need to use an action to
        # inspect the package.json#typings field or search for .d.ts files in the package.
        declaration_info(
            declarations = direct_files,
            deps = ctx.attr.deps,
        ),
        _LinkJsPackageInfo(
            label = ctx.label,
            link_package = ctx.label.package,
            package = package,
            version = version,
            dep_refs = direct_dep_refs,
            virtual_store_directory = virtual_store_directory,
        ),
    ]
    if virtual_store_directory:
        # Provide an output group that provides a single file which is the
        # package directory for use in $(execpath) and $(rootpath).
        # Output group name must match pnpm_utils.package_directory_output_group
        result.append(OutputGroupInfo(package_directory = depset([virtual_store_directory])))

    return result

def _impl_direct(ctx):
    virtual_store_directory = ctx.attr.src[_LinkJsPackageInfo].virtual_store_directory
    if not virtual_store_directory:
        fail("src must be a link_js_package that provides a virtual_store_directory")

    # symlink the package's path in the virtual store to the root of the node_modules
    # as a direct dependency
    root_symlink = ctx.actions.declare_file(
        # "node_modules/{package}"
        paths.join("node_modules", ctx.attr.src[_LinkJsPackageInfo].package),
    )
    ctx.actions.symlink(
        output = root_symlink,
        target_file = virtual_store_directory,
    )

    result = [
        DefaultInfo(
            files = depset([root_symlink], transitive = [ctx.attr.src[DefaultInfo].files]),
            runfiles = ctx.runfiles([root_symlink]).merge(ctx.attr.src[DefaultInfo].data_runfiles),
        ),
        ctx.attr.src[_LinkJsPackageInfo],
        declaration_info(
            declarations = depset([root_symlink], transitive = [ctx.attr.src[DeclarationInfo].transitive_declarations]),
        ),
    ]
    if OutputGroupInfo in ctx.attr.src:
        result.append(ctx.attr.src[OutputGroupInfo])

    return result

link_js_package_store_lib = struct(
    attrs = _ATTRS_STORE,
    implementation = _impl_store,
    provides = [DefaultInfo, DeclarationInfo, _LinkJsPackageInfo],
)

link_js_package_store = rule(
    doc = _DOC_STORE,
    implementation = link_js_package_store_lib.implementation,
    attrs = link_js_package_store_lib.attrs,
    provides = link_js_package_store_lib.provides,
)

link_js_package_direct_lib = struct(
    attrs = _ATTRS_DIRECT,
    implementation = _impl_direct,
    provides = [DefaultInfo, DeclarationInfo, _LinkJsPackageInfo],
)

link_js_package_direct = rule(
    doc = _DOC_DIRECT,
    implementation = link_js_package_direct_lib.implementation,
    attrs = link_js_package_direct_lib.attrs,
    provides = link_js_package_direct_lib.provides,
)

def link_js_package_dep(
        name,
        version = None,
        root_package = ""):
    """Returns the label to the link_js_package store for a package.

    This can be used to generate virtual store target names for the deps list
    of a link_js_package.

    Example root BUILD.file where the virtual store is linked by default,

    ```
    load("@npm//:defs.bzl", "link_js_packages")
    load("@aspect_rules_js//:defs.bzl", "link_js_package")

    # Links all packages from the `translate_pnpm_lock(name = "npm", pnpm_lock = "//:pnpm-lock.yaml")`
    # repository rule.
    link_js_packages()

    # Link a first party `@lib/foo` defined by the `js_package` `//lib/foo:foo` target.
    link_js_package(
        name = "link_lib_foo",
        src = "//lib/foo",
    )

    # Link a first party `@lib/bar` defined by the `js_package` `//lib/bar:bar` target
    # that depends on `@lib/foo` and on `acorn` specified in `package.json` and fetched
    # with `translate_pnpm_lock`
    link_js_package(
        name = "link_lib_bar",
        src = "//lib/bar",
        deps = [
            link_js_package_dep("link_lib_foo"),
            link_js_package_dep("acorn", version = "8.4.0"),
        ],
    )
    ```

    Args:
        name: The name of the link target.
            For first-party packages, this must match the `name` passed to link_js_package
            for the package in the root package when not linking at the root package.

            For 3rd party deps fetched with an npm_import or via a translate_pnpm_lock repository rule,
            the name must match the `package` attribute of the corresponding `npm_import`. This is typically
            the npm package name.
        version: The version of the package
            This should be left unset for first-party packages linked manually with link_js_package.

            For 3rd party deps fetched with an npm_import or via a translate_pnpm_lock repository rule,
            the package version is required to qualify the dependency. It must the `version` attribute
            of the corresponding `npm_import`.
        root_package: The bazel package of the virtual store.
            Defaults to the current package

    Returns:
        The label of the direct link for the given package at the given link package,
    """
    return Label("//{root_package}:{store_namespace}{bazel_name}".format(
        bazel_name = pnpm_utils.bazel_name(name, version),
        root_package = root_package,
        store_namespace = pnpm_utils.store_link_prefix,
    ))

def link_js_package(
        name,
        root_package = "",
        direct = True,
        src = None,
        deps = [],
        fail_if_no_link = True,
        auto_manual = True,
        visibility = ["//visibility:public"],
        **kwargs):
    """"Links a package to the virtual store if in the root package and directly to node_modules if direct is True.

    When called at the root_package, a virtual store target is generated named "link__{bazelified_name}__store".

    When linking direct, a "{name}" alias is generated which consists of the direct node_modules link and transitively
    its virtual store link and the virtual store links of the transitive closure of deps.

    When linking direct, "{name}__dir" alias is also generated that refers to a directory artifact can be used to access
    the package directory for creating entry points or accessing files in the package.

    Args:
        name: The name of the package.
            This should generally by the same as
        root_package: the root package where the node_modules virtual store is linked to
        direct: whether or not to link a direct dependency in this package
            For 3rd party deps fetched with an npm_import, direct may not be specified if
            link_packages is set on the npm_import.
        src: the js_package target to link; may only to be specified when linking in the root package
        deps: list of link_js_package_store; may only to be specified when linking in the root package
        fail_if_no_link: whether or not to fail if this is called in a package that is not the root package and with direct false
        auto_manual: whether or not to automatically add a manual tag to the generated targets
            Links tagged "manual" dy default is desirable so that they are not built by `bazel build ...` if they
            are unused downstream. For 3rd party deps, this is particularly important so that 3rd party deps are
            not fetched at all unless they are used.
        visibility: the visibility of the generated targets
        **kwargs: see attributes of link_js_package_store rule
    """
    is_root = native.package_name() == root_package
    is_direct = direct

    if fail_if_no_link and not is_root and not is_direct:
        msg = "Nothing to link in bazel package '{bazel_package}' for {name}. This is neither the root package nor a direct link.".format(
            bazel_package = native.package_name(),
            name = name,
        )
        fail(msg)

    if deps and not is_root:
        msg = "deps may only be specified when linking in the root package '{}'".format(root_package)
        fail(msg)

    if src and not is_root:
        msg = "src may only be specified when linking in the root package '{}'".format(root_package)
        fail(msg)

    link_target_name = "{direct_namespace}{bazel_name}".format(
        bazel_name = pnpm_utils.bazel_name(name),
        direct_namespace = pnpm_utils.direct_link_prefix,
    )

    dir_target_name = "{direct_namespace}{bazel_name}{dir_suffix}".format(
        bazel_name = pnpm_utils.bazel_name(name),
        dir_suffix = pnpm_utils.dir_suffix,
        direct_namespace = pnpm_utils.direct_link_prefix,
    )

    store_target_name = "{store_namespace}{bazel_name}".format(
        bazel_name = pnpm_utils.bazel_name(name),
        store_namespace = pnpm_utils.store_link_prefix,
    )

    tags = kwargs.pop("tags", [])
    if auto_manual and "manual" not in tags:
        tags.append("manual")

    if is_root:
        # link the virtual store when linking at the root
        link_js_package_store(
            name = store_target_name,
            src = src,
            deps = deps,
            visibility = visibility,
            tags = tags,
            **kwargs
        )

    if direct:
        # link as a direct dependency in node_modules of this package
        link_js_package_direct(
            name = link_target_name,
            src = "//{root_package}:{store_target}".format(
                root_package = root_package,
                store_target = store_target_name,
            ),
            tags = tags,
            visibility = visibility,
        )

        # filegroup target that provides a single file which is
        # package directory for use in $(execpath) and $(rootpath)
        native.filegroup(
            name = dir_target_name,
            srcs = [":{}".format(link_target_name)],
            output_group = pnpm_utils.package_directory_output_group,
            tags = tags,
            visibility = visibility,
        )

        native.alias(
            name = name,
            actual = ":{}".format(link_target_name),
            tags = tags,
            visibility = visibility,
        )

        native.alias(
            name = "{}{}".format(name, pnpm_utils.dir_suffix),
            actual = ":{}".format(dir_target_name),
            tags = tags,
            visibility = visibility,
        )
