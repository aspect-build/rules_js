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
    direct_ref_deps = []

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

        for dep in ctx.attr.deps:
            # symlink the package's direct deps to its virtual store location
            if dep[_StoreInfo].root_package != ctx.label.package:
                msg = """npm_link_package_store in %s package cannot depend on npm_link_package_store in %s package.
deps of npm_link_package_store must be in the same package.""" % (ctx.label.package, dep[_StoreInfo].root_package)
                fail(msg)
            dep_package = dep[_StoreInfo].package
            dep_version = dep[_StoreInfo].version
            dep_virtual_store_directory = dep[_StoreInfo].virtual_store_directory
            if dep_virtual_store_directory:
                # "node_modules/{virtual_store_root}/{virtual_store_name}/node_modules/{package}"
                dep_symlink_path = paths.join("node_modules", utils.virtual_store_root, virtual_store_name, "node_modules", dep_package)
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
                direct_ref_deps.append(dep)
    else:
        # if ctx.attr.src is _not_ set and ctx.attr.deps is, this is a terminal
        # package with deps being the transitive closure of deps;
        # this pattern is used to break circular dependencies between 3rd
        # party npm deps; it is not recommended for 1st party deps
        deps_map = {}
        for dep in ctx.attr.deps:
            # create a map of deps that have virtual store directories
            if dep[_StoreInfo].virtual_store_directory:
                dep_package = dep[_StoreInfo].package
                dep_version = dep[_StoreInfo].version
                deps_map[utils.pnpm_name(dep_package, dep_version)] = dep
            else:
                # this is a ref npm_link_package, a downstream terminal npm_link_package for this npm
                # depedency will create the dep symlinks for this dep; this pattern is used to break
                # for lifecycle hooks on 3rd party deps; it is not recommended for 1st party deps
                direct_ref_deps.append(dep)
        for dep in ctx.attr.deps:
            dep_package = dep[_StoreInfo].package
            dep_version = dep[_StoreInfo].version
            dep_virtual_store_name = utils.virtual_store_name(dep_package, dep_version)
            dep_ref_deps = dep[_StoreInfo].ref_deps
            if dep_package == package and dep_version == version:
                # provide the node_modules directory for this package if found in the transitive_closure
                virtual_store_directory = dep[_StoreInfo].virtual_store_directory
                if virtual_store_directory:
                    direct_files.append(virtual_store_directory)
            for dep_ref_dep in dep_ref_deps:
                dep_ref_dep_package = dep_ref_dep[_StoreInfo].package
                dep_ref_dep_version = dep_ref_dep[_StoreInfo].version
                if dep_ref_dep_package == package and dep_ref_dep_version == version:
                    pass
                else:
                    dep_ref_dep_pnpm_name = utils.pnpm_name(dep_ref_dep_package, dep_ref_dep_version)
                    if not dep_ref_dep_pnpm_name in deps_map:
                        fail("Expecting {} to be in deps".format(dep_ref_dep_pnpm_name))
                    actual_dep = deps_map[dep_ref_dep_pnpm_name]
                    dep_ref_def_virtual_store_directory = actual_dep[_StoreInfo].virtual_store_directory
                    if dep_ref_def_virtual_store_directory:
                        # "node_modules/{virtual_store_root}/{virtual_store_name}/node_modules/{package}"
                        dep_ref_dep_symlink_path = paths.join("node_modules", utils.virtual_store_root, dep_virtual_store_name, "node_modules", dep_ref_dep_package)
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
            deps = ctx.attr.deps,
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

    # symlink the package's path in the virtual store to the root of the node_modules
    # as a direct dependency
    root_symlink = ctx.actions.declare_file(
        # "node_modules/{package}"
        paths.join("node_modules", ctx.attr.src[_StoreInfo].package),
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

def _name_for_store(name):
    """Strip the standard node_modules/ naming convention prefix off of the name used for the store"""
    if name.startswith("node_modules/"):
        return name[len("node_modules/"):]
    else:
        return name

def npm_link_package_dep(
        name,
        version = None,
        root_package = ""):
    """Returns the label to the npm_link_package store for a package.

    This can be used to generate virtual store target names for the deps list
    of a npm_link_package.

    Example root BUILD.file where the virtual store is linked by default,

    ```
    load("@npm//:defs.bzl", "npm_link_all_packages")
    load("@aspect_rules_js//:defs.bzl", "npm_link_package")

    # Links all packages from the `npm_translate_lock(name = "npm", pnpm_lock = "//:pnpm-lock.yaml")`
    # repository rule.
    npm_link_all_packages(name = "node_modules")

    # Link a first party `@lib/foo` defined by the `npm_package` `//lib/foo:foo` target.
    npm_link_package(
        name = "node_modules/@lib/foo",
        src = "//lib/foo",
    )

    # Link a first party `@lib/bar` defined by the `npm_package` `//lib/bar:bar` target
    # that depends on `@lib/foo` and on `acorn` specified in `package.json` and fetched
    # with `npm_translate_lock`
    npm_link_package(
        name = "link_lib_bar",
        src = "//lib/bar",
        deps = [
            npm_link_package_dep("node_modules/@lib/foo"),
            npm_link_package_dep("acorn", version = "8.4.0"),
        ],
    )
    ```

    Args:
        name: The name of the link target.
            For first-party packages, this must match the `name` passed to npm_link_package
            for the package in the root package when not linking at the root package.

            For 3rd party deps fetched with an npm_import or via a npm_translate_lock repository rule,
            the name must match the `package` attribute of the corresponding `npm_import`. This is typically
            the npm package name.
        version: The version of the package
            This should be left unset for first-party packages linked manually with npm_link_package.

            For 3rd party deps fetched with an npm_import or via a npm_translate_lock repository rule,
            the package version is required to qualify the dependency. It must the `version` attribute
            of the corresponding `npm_import`.
        root_package: The bazel package of the virtual store.
            Defaults to the current package

    Returns:
        The label of the direct link for the given package at the given link package,
    """
    return Label("//{root_package}:{store_link_prefix}{bazel_name}".format(
        bazel_name = utils.bazel_name(_name_for_store(name), version),
        root_package = root_package,
        store_link_prefix = utils.store_link_prefix,
    ))

def npm_link_package(
        name,
        root_package = "",
        direct = True,
        src = None,
        deps = [],
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
        name: The name of the direct alias target to create if linked directly.
            For first-party deps linked across a workspace, the name must match in all packages
            being linked as it is used to derive the virtual store link target name.
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

    store_target_name = "{store_link_prefix}{bazel_name}".format(
        bazel_name = utils.bazel_name(_name_for_store(name)),
        store_link_prefix = utils.store_link_prefix,
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
            src = "//{root_package}:{store_target}".format(
                root_package = root_package,
                store_target = store_target_name,
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
