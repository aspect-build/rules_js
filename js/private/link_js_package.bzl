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

_DOC = """Defines a node package that is linked into a node_modules tree.

The term "package" is defined at
<https://nodejs.org/docs/latest-v16.x/api/packages.html>

The node package is linked with a pnpm style symlinked node_modules output tree.

See https://pnpm.io/symlinked-node-modules-structure for more information on
the symlinked node_modules structure.
Npm may also support a symlinked node_modules structure called
"Isolated mode" in the future:
https://github.com/npm/rfcs/blob/main/accepted/0042-isolated-mode.md.
"""

_ATTRS = {
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
    "indirect": attr.bool(
        doc = "If True, this is an indirect link_js_package which will not linked at the top-level of node_modules",
    ),
    "_windows_constraint": attr.label(default = "@platforms//os:windows"),
}

def _impl(ctx):
    is_windows = ctx.target_platform_has_constraint(ctx.attr._windows_constraint[platform_common.ConstraintValueInfo])

    if ctx.attr.src:
        package = ctx.attr.src[JsPackageInfo].package
        version = ctx.attr.src[JsPackageInfo].version
        if hasattr(ctx.attr, "package") and ctx.attr.package and ctx.attr.package != package:
            fail("package must match JsPackageInfo of src if both are specified")
        if hasattr(ctx.attr, "version") and ctx.attr.version and ctx.attr.version != version:
            fail("version must match JsPackageInfo of src if both are specified")
    else:
        if not ctx.attr.package:
            fail("package attr must be set if src is not set")
        if not ctx.attr.version:
            fail("version attr must not be empty if src is not set")
        package = ctx.attr.package
        version = ctx.attr.version

    virtual_store_name = pnpm_utils.virtual_store_name(package, version)

    virtual_store_directory = None
    direct_files = []
    direct_dep_refs = []

    if ctx.attr.src:
        # output the package as a TreeArtifact to its virtual store location
        # "node_modules/{virtual_store_root}/{virtual_store_name}/node_modules/{package}"
        virtual_store_directory_path = paths.join("node_modules", pnpm_utils.virtual_store_root, virtual_store_name, "node_modules", package)

        src_directory = ctx.attr.src[JsPackageInfo].directory
        if src_directory.short_path == paths.join(ctx.label.package, virtual_store_directory_path):
            # the input is already the desired output; this is the pattern for
            # packages with lifecycle hooks
            virtual_store_directory = src_directory
        else:
            virtual_store_directory = ctx.actions.declare_directory(virtual_store_directory_path)
            copy_directory_action(ctx, src_directory, virtual_store_directory, is_windows = is_windows)
        direct_files.append(virtual_store_directory)

        if not ctx.attr.indirect:
            # symlink the package's path in the virtual store to the root of the node_modules
            # if it is a direct dependency
            root_symlink = ctx.actions.declare_file(
                # "node_modules/{package}"
                paths.join("node_modules", package),
            )
            ctx.actions.symlink(
                output = root_symlink,
                target_file = virtual_store_directory,
            )
            direct_files.append(root_symlink)

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
                # this is a ref link_js_package, a downstream terminal link_js_package # for this npm
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
                actual_dep = deps_map[pnpm_utils.pnpm_name(dep_ref_package, dep_ref_version)]
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
    if not ctx.attr.indirect and virtual_store_directory:
        # Provide a "linked_js_package_dir" output group for use in $(execpath) and $(rootpath)
        # if this is a direct dependency
        result.append(OutputGroupInfo(
            linked_js_package_dir = depset([virtual_store_directory]),
        ))

    return result

link_js_package_lib = struct(
    attrs = _ATTRS,
    implementation = _impl,
    provides = [DefaultInfo, DeclarationInfo, _LinkJsPackageInfo],
)

link_js_package = rule(
    doc = _DOC,
    implementation = link_js_package_lib.implementation,
    attrs = link_js_package_lib.attrs,
    provides = link_js_package_lib.provides,
)
