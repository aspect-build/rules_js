"npm_link_package_store rule"

load("@bazel_skylib//lib:paths.bzl", "paths")
load(":utils.bzl", "utils")
load(":npm_package_store_info.bzl", "NpmPackageStoreInfo")
load("//js:providers.bzl", "JsInfo", "js_info")

_DOC = """Links an npm package that is backed by an npm_package_store into a node_modules tree as a direct dependency.

This is used in conjunction with the npm_package_store rule that outputs an npm package into the
node_modules/.aspect_rules_js package store in a pnpm style symlinked node_modules structure.

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
    "bins": attr.string_dict(
        doc = """Dictionary of `node_modules/.bin` binary files to create mapped to their node entry points.

        This is typically derived from the "bin" attribute in the package.json
        file of the npm package being linked.

        For example:

        ```
        bins = {
            "foo": "./foo.js",
            "bar": "./bar.js",
        }
        ```

        In the future, this field may be automatically populated by npm_translate_lock
        from information in the pnpm lock file. That feature is currently blocked on
        https://github.com/pnpm/pnpm/issues/5131.
        """,
    ),
}

_BIN_TMPL = """#!/bin/sh
basedir=$(dirname "$(echo "$0" | sed -e 's,\\\\,/,g')")
exec node "$basedir/{bin_path}" "$@"
"""

def _npm_link_package_store_impl(ctx):
    store_info = ctx.attr.src[NpmPackageStoreInfo]

    package_store_directory = store_info.package_store_directory
    if not package_store_directory:
        fail("src must be a npm_link_package that provides a package_store_directory")

    if package_store_directory.owner.workspace_name != ctx.label.workspace_name:
        msg = "expected package_store_directory to be in the same workspace as the link target '{}' but found '{}'".format(
            ctx.label.workspace_name,
            package_store_directory.owner.workspace_name,
        )
        fail(msg)

    package = ctx.attr.package if ctx.attr.package else store_info.package

    # symlink the package's path in the package store to the root of the node_modules
    # "node_modules/{package}" so it is available as a direct dependency
    root_symlink_path = paths.join("node_modules", package)

    files = [utils.make_symlink(ctx, root_symlink_path, package_store_directory)]

    for bin_name, bin_path in ctx.attr.bins.items():
        bin_file = ctx.actions.declare_file(paths.join("node_modules", ".bin", bin_name))
        bin_path = paths.normalize(paths.join("..", package, bin_path))
        ctx.actions.write(
            bin_file,
            _BIN_TMPL.format(bin_path = bin_path),
            is_executable = True,
        )
        files.append(bin_file)

    files_depset = depset(files)

    transitive_files_depset = depset(files, transitive = [store_info.transitive_files])

    providers = [
        DefaultInfo(
            # Only provide direct files in DefaultInfo files
            files = files_depset,
            # Include all transitives in runfiles so that this target can be used in the data
            # of a generic binary target such as sh_binary
            runfiles = ctx.runfiles(transitive_files = transitive_files_depset),
        ),
        js_info(
            npm_linked_packages = transitive_files_depset,
            # only propagate non-dev npm dependencies to use as direct dependencies when linking downstream npm_package targets with npm_link_package
            npm_package_store_infos = depset([store_info]) if not store_info.dev else depset(),
        ),
    ]
    if OutputGroupInfo in ctx.attr.src:
        providers.append(ctx.attr.src[OutputGroupInfo])

    return providers

npm_link_package_store = rule(
    doc = _DOC,
    implementation = _npm_link_package_store_impl,
    attrs = _ATTRS,
    provides = [DefaultInfo, JsInfo],
)
