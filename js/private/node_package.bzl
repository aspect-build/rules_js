"node_package rule"

load("@aspect_bazel_lib//lib:copy_directory.bzl", "copy_directory_action")
load("@bazel_skylib//lib:paths.bzl", "paths")
load("@rules_nodejs//nodejs:providers.bzl", "DeclarationInfo", "declaration_info")
load(":pnpm_utils.bzl", "pnpm_utils")

_NodePackageInfo = provider(
    doc = "Internal use only",
    fields = {
        "label": "the label of the target the created this provider",
        "link_package": "package that this node package is linked at",
        "package": "name of this node package",
        "version": "version of this node package",
        "dep_refs": "list of dependency ref targets",
        "bins": "A dict of bin names to paths for this package",
        "virtual_store_directory": "the TreeArtifact of this node package's virtual store location",
        "node_modules_directory": "the symlink of this package at the root of the node_modules if this is a direct npm dependency",
    },
)

_ATTRS = {
    "src": attr.label(
        allow_single_file = True,
        doc = """A source directory or TreeArtifact containing the package files.

Can be left unspecified to allow for circular deps between `node_package`s.        
""",
    ),
    "bins": attr.string_dict(
        doc = """A dict of bin entry point names to entry point paths for this package.

        This should mirror what is in the `bin` field of the package.json of the package.
        See https://docs.npmjs.com/cli/v7/configuring-npm/package-json#bin.""",
    ),
    "always_output_bins": attr.bool(
        doc = """If True, always output bins entry points. If False, bin entry points
        are only outputted when src is set.""",
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
        providers = [_NodePackageInfo],
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
        doc = "If True, this is an indirect node_package which will not linked at the top-level of node_modules",
    ),
    "root_dir": attr.string(
        doc = "For internal use only",
        default = "node_modules",
    ),
    "is_windows": attr.bool(mandatory = True),
}

_BIN_SH_TEMPLATE = """#!/usr/bin/env bash
exec node "../{package}/{bin_path}" "$@"
"""

def _normalize_bin_path(bin_path):
    result = bin_path.replace("\\", "/")
    if result.startswith("./"):
        result = result[2:]
    return result

def _impl(ctx):
    if ctx.file.src and not ctx.file.src.is_source and not ctx.file.src.is_directory:
        fail("src must a source directory or TreeArtifact if set")
    if not ctx.attr.package:
        fail("package attr must not be empty")
    if not ctx.attr.version:
        fail("version attr must not be empty")

    virtual_store_name = pnpm_utils.virtual_store_name(ctx.attr.package, ctx.attr.version)

    virtual_store_out = None
    node_modules_directory = None
    direct_files = []
    direct_dep_refs = []

    if ctx.file.src or ctx.attr.always_output_bins:
        # output bins for this package
        for (bin_name, bin_path) in ctx.attr.bins.items():
            # output a bin entry point this bin
            bin_out = ctx.actions.declare_file(
                # "{root_dir}/{virtual_store_root}/{virtual_store_name}/node_modules/.bin/{bin_name}"
                paths.join(ctx.attr.root_dir, pnpm_utils.virtual_store_root, virtual_store_name, "node_modules", ".bin", bin_name),
            )
            ctx.actions.write(
                bin_out,
                _BIN_SH_TEMPLATE.format(
                    package = ctx.attr.package,
                    bin_path = _normalize_bin_path(bin_path),
                ),
                is_executable = True,
            )
            direct_files.append(bin_out)

        # output bins for direct deps
        for dep in ctx.attr.deps:
            dep_package = dep[_NodePackageInfo].package
            for (bin_name, bin_path) in dep[_NodePackageInfo].bins.items():
                # output a bin entry point this bin
                bin_out = ctx.actions.declare_file(
                    # "{root_dir}/{virtual_store_root}/{virtual_store_name}/node_modules/.bin/{bin_name}"
                    paths.join(ctx.attr.root_dir, pnpm_utils.virtual_store_root, virtual_store_name, "node_modules", ".bin", bin_name),
                )
                ctx.actions.write(
                    bin_out,
                    _BIN_SH_TEMPLATE.format(
                        package = dep_package,
                        bin_path = _normalize_bin_path(bin_path),
                    ),
                    is_executable = True,
                )
                direct_files.append(bin_out)

    if ctx.file.src:
        # output the package as a TreeArtifact to its virtual store location
        virtual_store_out = ctx.actions.declare_directory(
            # "{root_dir}/{virtual_store_root}/{virtual_store_name}/node_modules/{package}"
            paths.join(ctx.attr.root_dir, pnpm_utils.virtual_store_root, virtual_store_name, "node_modules", ctx.attr.package),
        )
        copy_directory_action(ctx, ctx.file.src, virtual_store_out, ctx.attr.is_windows)
        direct_files.append(virtual_store_out)

        if not ctx.attr.indirect:
            node_modules_directory = virtual_store_out

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
            dep_link_package = dep[_NodePackageInfo].link_package
            if dep_link_package != ctx.label.package:
                if not ctx.label.package.startwith(dep_link_package + "/"):
                    msg = """node_package in %s package cannot depend on node_package in %s package.
deps of node_package must be in the same package or in a parent package.""" % (ctx.label.package, dep_link_package)
                    fail(msg)
            dep_package = dep[_NodePackageInfo].package
            dep_version = dep[_NodePackageInfo].version
            dep_virtual_store_directory = dep[_NodePackageInfo].virtual_store_directory
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
                # this is a ref node_package, a downstream terminal node_package
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
            if dep[_NodePackageInfo].virtual_store_directory:
                dep_package = dep[_NodePackageInfo].package
                dep_version = dep[_NodePackageInfo].version
                deps_map[pnpm_utils.pnpm_name(dep_package, dep_version)] = dep
            else:
                # this is a ref node_package, a downstream terminal node_package # for this npm
                # depedency will create the dep symlinks for this dep; this pattern is used to break
                # for lifecycle hooks on 3rd party deps; it is not recommended for 1st party deps
                direct_dep_refs.append(dep)
        for dep in ctx.attr.deps:
            dep_package = dep[_NodePackageInfo].package
            dep_version = dep[_NodePackageInfo].version
            dep_virtual_store_name = pnpm_utils.virtual_store_name(dep_package, dep_version)
            dep_refs = dep[_NodePackageInfo].dep_refs
            if dep_package == ctx.attr.package and dep_version == ctx.attr.version:
                # provide the node_modules directory for this package found in the transitive_closure
                node_modules_directory = dep[_NodePackageInfo].node_modules_directory
            for dep_ref in dep_refs:
                dep_ref_package = dep_ref[_NodePackageInfo].package
                dep_ref_version = dep_ref[_NodePackageInfo].version
                actual_dep = deps_map[pnpm_utils.pnpm_name(dep_ref_package, dep_ref_version)]
                dep_ref_virtual_store_directory = actual_dep[_NodePackageInfo].virtual_store_directory
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
        _NodePackageInfo(
            label = ctx.label,
            link_package = ctx.label.package,
            package = ctx.attr.package,
            version = ctx.attr.version,
            dep_refs = direct_dep_refs,
            bins = ctx.attr.bins,
            node_modules_directory = node_modules_directory,
            virtual_store_directory = virtual_store_out,
        ),
    ]
    if node_modules_directory:
        # Provide a "node_modules_directory" output group for use in $(execpath) and $(rootpath)
        result.append(OutputGroupInfo(
            node_modules_directory = depset([node_modules_directory]),
        ))

    return result

node_package_lib = struct(
    attrs = _ATTRS,
    impl = _impl,
    provides = [DefaultInfo, DeclarationInfo, _NodePackageInfo],
)

# For stardoc to generate documentation for the rule rather than a wrapper macro
node_package = rule(
    implementation = node_package_lib.impl,
    attrs = node_package_lib.attrs,
    provides = node_package_lib.provides,
)
