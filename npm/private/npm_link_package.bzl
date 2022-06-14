"npm_link_package rule"

load("@aspect_bazel_lib//lib:copy_directory.bzl", "copy_directory_action")
load("@bazel_skylib//lib:paths.bzl", "paths")
load("@rules_nodejs//nodejs:providers.bzl", "DeclarationInfo", "declaration_info")
load(":utils.bzl", "utils")
load(":npm_package.bzl", "NpmPackageInfo")

_StoreInfo = provider(
    doc = "Internal use only",
    fields = {
        "label": "the label of the npm_link_package_store target the created this provider",
        "root_package": "package that this node package store is linked at",
        "package": "name of this node package",
        "version": "version of this node package",
        "ref_deps": "list of dependency ref targets",
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

This is used in co-ordination with the npm_link_package_store rule that links into the
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
        doc = """A npm_package target or or any other target that provides a NpmPackageInfo.
        """,
        providers = [NpmPackageInfo],
        mandatory = True,
    ),
    "deps": attr.label_keyed_string_dict(
        doc = """Other node packages store link targets one depends on mapped to the name to link them under in this packages deps.

        This should include *all* modules the program may need at runtime.

        You can find all the package store link targets in your repository with

        ```
        bazel query ... | grep //:.aspect_rules_js | grep -v /dir | grep -v /pkg | grep -v /ref
        ```

        1st party deps will typically be versioned 0.0.0 (unless set to another version explicitly in
        npm_link_package). For example,

        ```
        //:.aspect_rules_js/node_modules/@mycorp/mylib/0.0.0
        ```

        3rd party package store link targets will include the version. For example,

        ```
        //:.aspect_rules_js/node_modules/cliui/7.0.4
        ```

        If imported via npm_translate_lock, the version may include peer dep(s),

        ```
        //:.aspect_rules_js/node_modules/debug/4.3.4_supports-color@8.1.1
        ```

        It could be also be a `github.com` url based version,

        ```
        //:.aspect_rules_js/node_modules/debug/github.com/ngokevin/debug/9742c5f383a6f8046241920156236ade8ec30d53
        ```

        In general, package store link targets names for 3rd party packages that come from
        `npm_translate_lock` start with `.aspect_rules_js/` then name passed to the `npm_link_all_packages` macro
        (typically 'node_modules') followed by `/<package>/<version>` where `package` is the
        package name (including @scope segment if any) and `version` is the specific version of
        the package that comes from the pnpm-lock.yaml file.

        Package store link targets names for 3rd party package that come directly from an
        `npm_import` start with `.aspect_rules_js/` then the name passed to the `npm_import`'s `npm_link_imported_package`
        macro (typically 'node_modules') followed by `/<package>/<version>` where `package`
        matches the `package` attribute in the npm_import of the package and `version` matches the
        `version` attribute.

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
        providers = [_StoreInfo],
    ),
    "package": attr.string(
        doc = """The package name to link to.

If unset, the package name in the NpmPackageInfo src must be set.
If set, takes precendance over the package name in the NpmPackageInfo src.
""",
    ),
    "version": attr.string(
        doc = """The package version being linked.

If unset, the package version in the NpmPackageInfo src must be set.
If set, takes precendance over the package version in the NpmPackageInfo src.
""",
    ),
    "_windows_constraint": attr.label(default = "@platforms//os:windows"),
}

_ATTRS_DIRECT = {
    "src": attr.label(
        doc = """The npm_link_package target to link as a direct dependency.""",
        providers = [_StoreInfo],
        mandatory = True,
    ),
    "package": attr.string(
        doc = """The package name to link to.

If unset, the package name of the src npm_link_package_store is used.
If set, takes precendance over the package name in the src npm_link_package_store.
""",
    ),
}

def _impl_store(ctx):
    is_windows = ctx.target_platform_has_constraint(ctx.attr._windows_constraint[platform_common.ConstraintValueInfo])

    package = ctx.attr.package if ctx.attr.package else ctx.attr.src[NpmPackageInfo].package
    version = ctx.attr.version if ctx.attr.version else ctx.attr.src[NpmPackageInfo].version

    if not package:
        fail("No package name specified to link to. Package name must either be specified explicitly via `package` attribute or come from the `src` `NpmPackageInfo`, typically a `npm_package` target")
    if not version:
        fail("No package version specified to link to. Package version must either be specified explicitly via `version` attribute or come from the `src` `NpmPackageInfo`, typically a `npm_package` target")

    virtual_store_name = utils.virtual_store_name(package, version)

    virtual_store_directory = None
    direct_files = []
    direct_ref_deps = {}

    if ctx.attr.src:
        # output the package as a TreeArtifact to its virtual store location
        # "node_modules/{virtual_store_root}/{virtual_store_name}/node_modules/{package}"
        virtual_store_directory_path = paths.join("node_modules", utils.virtual_store_root, virtual_store_name, "node_modules", package)

        if ctx.label.workspace_name:
            expected_short_path = paths.join("..", ctx.label.workspace_name, ctx.label.package, virtual_store_directory_path)
        else:
            expected_short_path = paths.join(ctx.label.package, virtual_store_directory_path)
        src_directory = ctx.attr.src[NpmPackageInfo].directory
        if src_directory.short_path == expected_short_path:
            # the input is already the desired output; this is the pattern for
            # packages with lifecycle hooks
            virtual_store_directory = src_directory
        else:
            virtual_store_directory = ctx.actions.declare_directory(virtual_store_directory_path)
            copy_directory_action(ctx, src_directory, virtual_store_directory, is_windows = is_windows)
        direct_files.append(virtual_store_directory)

        for dep, _dep_aliases in ctx.attr.deps.items():
            # symlink the package's direct deps to its virtual store location
            if dep[_StoreInfo].root_package != ctx.label.package:
                msg = """npm_link_package_store in %s package cannot depend on npm_link_package_store in %s package.
deps of npm_link_package_store must be in the same package.""" % (ctx.label.package, dep[_StoreInfo].root_package)
                fail(msg)
            dep_package = dep[_StoreInfo].package
            dep_version = dep[_StoreInfo].version
            dep_aliases = _dep_aliases.split(",") if _dep_aliases else [dep_package]
            dep_virtual_store_directory = dep[_StoreInfo].virtual_store_directory
            if dep_virtual_store_directory:
                for dep_alias in dep_aliases:
                    # "node_modules/{virtual_store_root}/{virtual_store_name}/node_modules/{package}"
                    dep_symlink_path = paths.join("node_modules", utils.virtual_store_root, virtual_store_name, "node_modules", dep_alias)
                    dep_symlink = ctx.actions.declare_file(dep_symlink_path)
                    ctx.actions.symlink(
                        output = dep_symlink,
                        target_file = dep_virtual_store_directory,
                    )
                    direct_files.append(dep_symlink)
            else:
                # this is a ref npm_link_package, a downstream terminal npm_link_package
                # for this npm depedency will create the dep symlinks for this dep;
                # this pattern is used to break circular dependencies between 3rd
                # party npm deps; it is not recommended for 1st party deps
                direct_ref_deps[dep] = dep_aliases
    else:
        # if ctx.attr.src is _not_ set and ctx.attr.deps is, this is a terminal
        # package with deps being the transitive closure of deps;
        # this pattern is used to break circular dependencies between 3rd
        # party npm deps; it is not recommended for 1st party deps
        deps_map = {}
        for dep, _dep_aliases in ctx.attr.deps.items():
            dep_package = dep[_StoreInfo].package
            dep_aliases = _dep_aliases.split(",") if _dep_aliases else [dep_package]

            # create a map of deps that have virtual store directories
            if dep[_StoreInfo].virtual_store_directory:
                deps_map[utils.virtual_store_name(dep[_StoreInfo].package, dep[_StoreInfo].version)] = dep
            else:
                # this is a ref npm_link_package, a downstream terminal npm_link_package for this npm
                # depedency will create the dep symlinks for this dep; this pattern is used to break
                # for lifecycle hooks on 3rd party deps; it is not recommended for 1st party deps
                direct_ref_deps[dep] = dep_aliases
        for dep in ctx.attr.deps:
            dep_virtual_store_name = utils.virtual_store_name(dep[_StoreInfo].package, dep[_StoreInfo].version)
            dep_ref_deps = dep[_StoreInfo].ref_deps
            if virtual_store_name == dep_virtual_store_name:
                # provide the node_modules directory for this package if found in the transitive_closure
                virtual_store_directory = dep[_StoreInfo].virtual_store_directory
                if virtual_store_directory:
                    direct_files.append(virtual_store_directory)
            for dep_ref_dep, dep_ref_dep_aliases in dep_ref_deps.items():
                dep_ref_dep_virtual_store_name = utils.virtual_store_name(dep_ref_dep[_StoreInfo].package, dep_ref_dep[_StoreInfo].version)
                if dep_ref_dep_virtual_store_name == virtual_store_name:
                    # ignore reference back to self in dyadic circular deps
                    pass
                else:
                    if not dep_ref_dep_virtual_store_name in deps_map:
                        fail("Expecting {} to be in deps".format(dep_ref_dep_virtual_store_name))
                    actual_dep = deps_map[dep_ref_dep_virtual_store_name]
                    dep_ref_def_virtual_store_directory = actual_dep[_StoreInfo].virtual_store_directory
                    if dep_ref_def_virtual_store_directory:
                        for dep_ref_dep_alias in dep_ref_dep_aliases:
                            # "node_modules/{virtual_store_root}/{virtual_store_name}/node_modules/{package}"
                            dep_ref_dep_symlink_path = paths.join("node_modules", utils.virtual_store_root, dep_virtual_store_name, "node_modules", dep_ref_dep_alias)
                            dep_ref_dep_symlink = ctx.actions.declare_file(dep_ref_dep_symlink_path)
                            ctx.actions.symlink(
                                output = dep_ref_dep_symlink,
                                target_file = dep_ref_def_virtual_store_directory,
                            )
                            direct_files.append(dep_ref_dep_symlink)

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
            deps = ctx.attr.deps.keys(),
        ),
        _StoreInfo(
            label = ctx.label,
            root_package = ctx.label.package,
            package = package,
            version = version,
            ref_deps = direct_ref_deps,
            virtual_store_directory = virtual_store_directory,
        ),
    ]
    if virtual_store_directory:
        # Provide an output group that provides a single file which is the
        # package directory for use in $(execpath) and $(rootpath).
        # Output group name must match utils.package_directory_output_group
        result.append(OutputGroupInfo(package_directory = depset([virtual_store_directory])))

    return result

def _impl_direct(ctx):
    virtual_store_directory = ctx.attr.src[_StoreInfo].virtual_store_directory
    if not virtual_store_directory:
        fail("src must be a npm_link_package that provides a virtual_store_directory")

    package = ctx.attr.package if ctx.attr.package else ctx.attr.src[_StoreInfo].package

    # symlink the package's path in the virtual store to the root of the node_modules
    # as a direct dependency
    root_symlink = ctx.actions.declare_file(
        # "node_modules/{package}"
        paths.join("node_modules", package),
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
        declaration_info(
            declarations = depset([root_symlink], transitive = [ctx.attr.src[DeclarationInfo].transitive_declarations]),
        ),
    ]
    if OutputGroupInfo in ctx.attr.src:
        result.append(ctx.attr.src[OutputGroupInfo])

    return result

npm_link_package_store_lib = struct(
    attrs = _ATTRS_STORE,
    implementation = _impl_store,
    provides = [DefaultInfo, DeclarationInfo, _StoreInfo],
)

npm_link_package_store = rule(
    doc = _DOC_STORE,
    implementation = npm_link_package_store_lib.implementation,
    attrs = npm_link_package_store_lib.attrs,
    provides = npm_link_package_store_lib.provides,
)

npm_link_package_direct_lib = struct(
    attrs = _ATTRS_DIRECT,
    implementation = _impl_direct,
    provides = [DefaultInfo, DeclarationInfo],
)

npm_link_package_direct = rule(
    doc = _DOC_DIRECT,
    implementation = npm_link_package_direct_lib.implementation,
    attrs = npm_link_package_direct_lib.attrs,
    provides = npm_link_package_direct_lib.provides,
)

def npm_link_package(
        name,
        version = "0.0.0",
        root_package = "",
        direct = True,
        src = None,
        deps = {},
        fail_if_no_link = True,
        auto_manual = True,
        visibility = ["//visibility:public"],
        **kwargs):
    """"Links an npm package to the virtual store if in the root package and directly to node_modules if direct is True.

    When called at the root_package, a virtual store target is generated named "link__{bazelified_name}__store".

    When linking direct, a "{name}" target is generated which consists of the direct node_modules link and transitively
    its virtual store link and the virtual store links of the transitive closure of deps.

    When linking direct, "{name}/dir" filegroup is also generated that refers to a directory artifact can be used to access
    the package directory for creating entry points or accessing files in the package.

    Args:
        name: The name of the direct link target to create (if linked directly).
            For first-party deps linked across a workspace, the name must match in all packages
            being linked as it is used to derive the virtual store link target name.
        version: version used to identify the package in the virtual store
        root_package: the root package where the node_modules virtual store is linked to
        direct: whether or not to link a direct dependency in this package
            For 3rd party deps fetched with an npm_import, direct may not be specified if
            link_packages is set on the npm_import.
        src: the npm_package target to link; may only to be specified when linking in the root package
        deps: list of npm_link_package_store; may only to be specified when linking in the root package
        fail_if_no_link: whether or not to fail if this is called in a package that is not the root package and with direct false
        auto_manual: whether or not to automatically add a manual tag to the generated targets
            Links tagged "manual" dy default is desirable so that they are not built by `bazel build ...` if they
            are unused downstream. For 3rd party deps, this is particularly important so that 3rd party deps are
            not fetched at all unless they are used.
        visibility: the visibility of the generated targets
        **kwargs: see attributes of npm_link_package_store rule

    Returns:
        Label of the npm_link_package_direct if created, else None
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

    store_target_name = "{virtual_store_root}/{name}/{version}".format(
        name = name,
        version = version,
        virtual_store_root = utils.virtual_store_root,
    )

    tags = kwargs.pop("tags", [])
    if auto_manual and "manual" not in tags:
        tags.append("manual")

    if is_root:
        # link the virtual store when linking at the root
        npm_link_package_store(
            name = store_target_name,
            src = src,
            deps = deps,
            visibility = visibility,
            tags = tags,
            **kwargs
        )

    direct_target = None
    if direct:
        # link as a direct dependency in node_modules of this package
        npm_link_package_direct(
            name = name,
            src = "//{root_package}:{store_target_name}".format(
                root_package = root_package,
                store_target_name = store_target_name,
            ),
            tags = tags,
            visibility = visibility,
        )
        direct_target = ":{}".format(name)

        # filegroup target that provides a single file which is
        # package directory for use in $(execpath) and $(rootpath)
        native.filegroup(
            name = "{}/dir".format(name),
            srcs = [direct_target],
            output_group = utils.package_directory_output_group,
            tags = tags,
            visibility = visibility,
        )

    return direct_target
