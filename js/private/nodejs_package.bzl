"nodejs_package rule"

load("@aspect_bazel_lib//lib:copy_directory.bzl", "copy_directory_action")
load("@rules_nodejs//nodejs:providers.bzl", "DeclarationInfo", "declaration_info")
load(":npm_utils.bzl", "npm_utils")

_NodejsPackageInfo = provider(
    fields = {
        "link_package": "package that this nodejs package is linked at",
        "name": "name of this nodejs package",
        "version": "version of this nodejs package",
        "virtual_store_directory": "the TreeArtifact of this nodejs package's virtual store location"
    },
)

VIRTUAL_STORE_ROOT = ".aspect_rules_js"

_DOC = """Defines a nodejs package that is linked into a node_modules tree.

The term "package" is defined at
<https://nodejs.org/docs/latest-v16.x/api/packages.html>

The nodejs package is linked with a pnpm style symlinked node_modules output tree.

See https://pnpm.io/symlinked-node-modules-structure for more information on
the symlinked node_modules structure.
Npm may also support a symlinked node_modules structure called
"Isolated mode" in the future:
https://github.com/npm/rfcs/blob/main/accepted/0042-isolated-mode.md.
"""

_ATTRS = {
    "src": attr.label(
        allow_single_file = True,
        doc = """A source directory or TreeArtifact containing the package files.

Can be left unspecified to allow for circular deps between nodejs_packages.        
""",
    ),
    "deps": attr.label_list(
        doc = """Other nodejs packages this one depends on.

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
        providers = [_NodejsPackageInfo],
    ),
    "package_name": attr.string(
        # TODO: validate that name matches in an action if src is set
        doc = "Must match the `name` field in the `package.json` file for this package.",
        mandatory = True,
    ),
    "package_version": attr.string(
        # TODO: validate that version matches in an action if src is set
        doc = "Must match the `version` field in the `package.json` file for this package.",
        default = "0.0.0",
    ),
    "indirect": attr.bool(
        doc = "If True, this is an indirect nodejs_package which will not linked as a top-level node_module",
    ),
    "is_windows": attr.bool(mandatory = True),
}

def _impl(ctx):
    if ctx.file.src and not ctx.file.src.is_source and not ctx.file.src.is_directory:
        fail("src must a source directory or TreeArtifact if set")
    if not ctx.attr.package_name:
        fail("package_name attr must not be empty")
    if not ctx.attr.package_version:
        fail("package_version attr must not be empty")

    virtual_store_name = npm_utils.virtual_store_name(ctx.attr.package_name, ctx.attr.package_version)

    virtual_store_out = None
    node_modules_directory = None
    direct_files = []

    if ctx.file.src:
        # output the package as a TreeArtifact to its virtual store location
        virtual_store_out = ctx.actions.declare_directory(
            "node_modules/{virtual_store_root}/{virtual_store_name}/node_modules/{package_name}".format(
                package_name = ctx.attr.package_name,
                virtual_store_name = virtual_store_name,
                virtual_store_root = VIRTUAL_STORE_ROOT,
            )
        )
        copy_directory_action(ctx, ctx.file.src, virtual_store_out, ctx.attr.is_windows)
        direct_files.append(virtual_store_out)

        if not ctx.attr.indirect:
            # symlink the package's path in the virtual store to the root of the node_modules
            # if it is a direct dependency
            root_symlink = ctx.actions.declare_file(
                "node_modules/{package_name}".format(package_name = ctx.attr.package_name)
            )
            ctx.actions.symlink(
                output = root_symlink,
                target_file = virtual_store_out,
            )
            direct_files.append(root_symlink)
            node_modules_directory = root_symlink

        for dep in ctx.attr.deps:
            # symlink the package's direct deps to its virtual store location
            dep_link_package = dep[_NodejsPackageInfo].link_package
            if dep_link_package != ctx.label.package:
                if not ctx.label.package.startwith(dep_link_package + "/"):
                    msg = """nodejs_package in %s package cannot depend on nodejs_package in %s package.
deps of nodejs_package must be in the same package or in a parent package.""" % (ctx.label.package, dep_link_package)
                    fail(msg)
            dep_name = dep[_NodejsPackageInfo].name
            dep_version = dep[_NodejsPackageInfo].version
            dep_virtual_store_directory = dep[_NodejsPackageInfo].virtual_store_directory
            dep_symlink_path = "node_modules/{virtual_store_root}/{virtual_store_name}/node_modules/{dep_name}".format(
                dep_name = dep_name,
                virtual_store_name = virtual_store_name,
                virtual_store_root = VIRTUAL_STORE_ROOT,
            )
            if dep_virtual_store_directory:
                dep_symlink = ctx.actions.declare_file(dep_symlink_path)
                ctx.actions.symlink(
                    output = dep_symlink,
                    target_file = dep_virtual_store_directory,
                )
            else:
                print("""
====================================================================================================
WARNING: dangling symlinks are experimental and require --experimental_allow_unresolved_symlinks

In the latest version of Bazel (5.1.1 at time of authoring), this flag is not propogated to the
"host" and "exec" configurations which breaks if you use this a target as a "tool" that is built
under the "host" and "exec" configs. Dangling symlinks are also not supported with remote execution.
See https://github.com/bazelbuild/bazel/issues/10298#issuecomment-558031652 for more information.
====================================================================================================
""")
                dep_symlink = ctx.actions.declare_symlink(dep_symlink_path)
                execpath = "/".join([p for p in [ctx.bin_dir.path, ctx.label.workspace_root, ctx.label.package] if p])
                ctx.actions.symlink(
                    output = dep_symlink,
                    target_path = "{execpath}/node_modules/{virtual_store_root}/{virtual_store_name}/node_modules/{dep_name}".format(
                        execpath = execpath,
                        dep_name = dep_name,
                        virtual_store_name = npm_utils.virtual_store_name(dep_name, dep_version),
                        virtual_store_root = VIRTUAL_STORE_ROOT,
                    )
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
        _NodejsPackageInfo(
            link_package = ctx.label.package,
            name = ctx.attr.package_name,
            version = ctx.attr.package_version,
            virtual_store_directory = virtual_store_out,
        ),
    ]
    if node_modules_directory:
        # Provide a "node_modules_directory" output group for use in $(execpath) and $(rootpath)
        result.append(OutputGroupInfo(
            node_modules_directory = depset([node_modules_directory]),
        ))

    return result

nodejs_package_lib = struct(
    attrs = _ATTRS,
    impl = _impl,
    provides = [DefaultInfo, DeclarationInfo, _NodejsPackageInfo],
)

# For stardoc to generate documentation for the rule rather than a wrapper macro
nodejs_package = rule(
    doc = _DOC,
    implementation = nodejs_package_lib.impl,
    attrs = nodejs_package_lib.attrs,
    provides = nodejs_package_lib.provides,
)
