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

This is used in co-ordination with link_js_package that links into the virtual store in
with a pnpm style symlinked node_modules output tree.

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

If unset, the package name in the JsPackageInfo src must be set.
If set, takes precendance over the package name in the JsPackageInfo src.
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
                if not ctx.label.package.startwith(dep_link_package + "/"):
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
