"npm_link_package_store rule"

load("@bazel_skylib//lib:paths.bzl", "paths")
load(":utils.bzl", "utils")
load(":npm_linked_package_info.bzl", "NpmLinkedPackageInfo")
load(":npm_package_store_info.bzl", "NpmPackageStoreInfo")
load("//js:providers.bzl", "JsInfo", "js_info")

_DOC = """Links an npm package that is backed by an npm_package_store into a node_modules tree as a direct dependency.

This is used in conjunction with the npm_package_store rule that outputs an npm package into the
node_modules/.aspect_rules_js virtual store in a pnpm style symlinked node_modules structure.

The term "package" is defined at
<https://nodejs.org/docs/latest-v16.x/api/packages.html>

See https://pnpm.io/symlinked-node-modules-structure for more information on
the symlinked node_modules structure.
Npm may also support a symlinked node_modules structure called
"Isolated mode" in the future:
https://github.com/npm/rfcs/blob/main/accepted/0042-isolated-mode.md.
"""

_ATTRS = {
    "src": attr.label(
        doc = """The npm_package_store target to link as a direct dependency.""",
        providers = [NpmPackageStoreInfo],
        mandatory = True,
    ),
    "package": attr.string(
        doc = """The package name to link to.

If unset, the package name of the src npm_package_store is used.
If set, takes precendance over the package name in the src npm_package_store.
""",
    ),
    "use_declare_symlink": attr.bool(
        mandatory = True,
        doc = """Whether unresolved symlinks are enabled in the current build configuration.

        These are enabled with the --experimental_allow_unresolved_symlinks flag.

        Typical usage of this rule is via a macro which automatically sets this
        attribute based on a `config_setting` rule.
        """,
    ),
}

def _impl(ctx):
    store_info = ctx.attr.src[NpmPackageStoreInfo]

    virtual_store_directory = store_info.virtual_store_directory
    if not virtual_store_directory:
        fail("src must be a npm_link_package that provides a virtual_store_directory")

    package = ctx.attr.package if ctx.attr.package else store_info.package

    # symlink the package's path in the virtual store to the root of the node_modules
    # "node_modules/{package}" so it is available as a direct dependency
    root_symlink_path = paths.join("node_modules", package)

    files = utils.make_symlink(ctx, root_symlink_path, virtual_store_directory)

    transitive_files = files + store_info.transitive_files

    npm_linked_package_info = NpmLinkedPackageInfo(
        label = ctx.label,
        link_package = ctx.label.package,
        package = store_info.package,
        version = store_info.version,
        store_info = store_info,
        files = files,
        transitive_files = transitive_files,
    )

    providers = [
        DefaultInfo(
            files = depset(files),
        ),
        js_info(
            npm_linked_packages = [npm_linked_package_info],
            transitive_npm_linked_packages = [npm_linked_package_info],
        ),
    ]
    if OutputGroupInfo in ctx.attr.src:
        providers.append(ctx.attr.src[OutputGroupInfo])

    return providers

npm_link_package_store = rule(
    doc = _DOC,
    implementation = _impl,
    attrs = _ATTRS,
    provides = [DefaultInfo, JsInfo],
)
