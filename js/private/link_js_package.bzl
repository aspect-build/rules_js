"link_js_package rule"

load("@aspect_bazel_lib//lib:copy_directory.bzl", "copy_directory_action")
load("@bazel_skylib//lib:paths.bzl", "paths")
load("@rules_nodejs//nodejs:providers.bzl", "DeclarationInfo", "declaration_info")
load(":pnpm_utils.bzl", "pnpm_utils")

_LinkJsPackageInfo = provider(
    doc = "Internal use only",
    fields = {
        "label": "the label of the target the created this provider",
        "link_package": "package that this node package is linked at",
        "package": "name of this node package",
        "version": "version of this node package",
        "dep_refs": "list of dependency ref targets",
        "virtual_store_directory": "the TreeArtifact of this node package's virtual store location",
        "linked_js_package_dir": "the symlink of this package at the root of the node_modules if this is a direct npm dependency",
    },
)

_ATTRS = {
    "src": attr.label(
        allow_single_file = True,
        doc = """A source directory or TreeArtifact containing the package files.

Can be left unspecified to allow for circular deps between `link_js_package`s.        
""",
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
        # TODO: validate that name matches in an action if src is set
        doc = "Must match the `name` field in the `package.json` file for this package.",
        mandatory = True,
    ),
    "version": attr.string(
        # TODO: validate that version matches in an action if src is set
        doc = "Must match the `version` field in the `package.json` file for this package.",
        default = "0.0.0",
    ),
    "indirect": attr.bool(
        doc = "If True, this is an indirect link_js_package which will not linked at the top-level of node_modules",
    ),
    "root_dir": attr.string(
        doc = "For internal use only",
        default = "node_modules",
    ),
    "_windows_constraint": attr.label(default = "@platforms//os:windows"),
}

def _impl(ctx):
    is_windows = ctx.target_platform_has_constraint(ctx.attr._windows_constraint[platform_common.ConstraintValueInfo])

    if ctx.file.src and not ctx.file.src.is_source and not ctx.file.src.is_directory:
        fail("src must a source directory or TreeArtifact if set")
    if not ctx.attr.package:
        fail("package attr must not be empty")
    if not ctx.attr.version:
        fail("version attr must not be empty")

    virtual_store_name = pnpm_utils.virtual_store_name(ctx.attr.package, ctx.attr.version)

    virtual_store_out = None
    linked_js_package_dir = None
    direct_files = []
    direct_dep_refs = []

    if ctx.file.src:
        # "{root_dir}/{virtual_store_root}/{virtual_store_name}/node_modules/{package}"
        virtual_store_out_path = paths.join(ctx.attr.root_dir, pnpm_utils.virtual_store_root, virtual_store_name, "node_modules", ctx.attr.package)
        if ctx.file.src.short_path == paths.join(ctx.label.package, virtual_store_out_path):
            # the input is already the desired output; this is the pattern for
            # packages with lifecycle hooks
            virtual_store_out = ctx.file.src
        else:
            # output the package as a TreeArtifact to its virtual store location
            virtual_store_out = ctx.actions.declare_directory(virtual_store_out_path)
            copy_directory_action(ctx, ctx.file.src, virtual_store_out, is_windows = is_windows)
            direct_files.append(virtual_store_out)

        if not ctx.attr.indirect:
            linked_js_package_dir = virtual_store_out

            # symlink the package's path in the virtual store to the root of the node_modules
            # if it is a direct dependency
            root_symlink = ctx.actions.declare_file(
                # "{root_dir}/{package}"
                paths.join(ctx.attr.root_dir, ctx.attr.package),
            )
            ctx.actions.symlink(
                output = root_symlink,
                target_file = virtual_store_out,
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
                # "{root_dir}/{virtual_store_root}/{virtual_store_name}/node_modules/{package}"
                dep_symlink_path = paths.join(ctx.attr.root_dir, pnpm_utils.virtual_store_root, virtual_store_name, "node_modules", dep_package)
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
            if dep_package == ctx.attr.package and dep_version == ctx.attr.version:
                # provide the node_modules directory for this package found in the transitive_closure
                linked_js_package_dir = dep[_LinkJsPackageInfo].linked_js_package_dir
            for dep_ref in dep_refs:
                dep_ref_package = dep_ref[_LinkJsPackageInfo].package
                dep_ref_version = dep_ref[_LinkJsPackageInfo].version
                actual_dep = deps_map[pnpm_utils.pnpm_name(dep_ref_package, dep_ref_version)]
                dep_ref_virtual_store_directory = actual_dep[_LinkJsPackageInfo].virtual_store_directory
                if dep_ref_virtual_store_directory:
                    # "{root_dir}/{virtual_store_root}/{virtual_store_name}/node_modules/{package}"
                    dep_symlink_path = paths.join(ctx.attr.root_dir, pnpm_utils.virtual_store_root, dep_virtual_store_name, "node_modules", dep_ref_package)
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
            package = ctx.attr.package,
            version = ctx.attr.version,
            dep_refs = direct_dep_refs,
            linked_js_package_dir = linked_js_package_dir,
            virtual_store_directory = virtual_store_out,
        ),
    ]
    if linked_js_package_dir:
        # Provide a "linked_js_package_dir" output group for use in $(execpath) and $(rootpath)
        result.append(OutputGroupInfo(
            linked_js_package_dir = depset([linked_js_package_dir]),
        ))

    return result

link_js_package_lib = struct(
    attrs = _ATTRS,
    impl = _impl,
    provides = [DefaultInfo, DeclarationInfo, _LinkJsPackageInfo],
)

# For stardoc to generate documentation for the rule rather than a wrapper macro
link_js_package = rule(
    implementation = link_js_package_lib.impl,
    attrs = link_js_package_lib.attrs,
    provides = link_js_package_lib.provides,
)
