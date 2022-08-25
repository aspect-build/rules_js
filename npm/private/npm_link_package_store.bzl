"npm_link_package_store rule"

load("@bazel_skylib//lib:paths.bzl", "paths")
load(":utils.bzl", "utils")
load(":npm_linked_package_info.bzl", "NpmLinkedPackageInfo")
load(":npm_package_store_info.bzl", "NpmPackageStoreInfo")
load("//js:providers.bzl", "JsInfo", "js_info_complete")
load("@bazel_skylib//lib:sets.bzl", "sets")

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
    "use_declare_symlink": attr.bool(
        mandatory = True,
        doc = """Whether unresolved symlinks are enabled in the current build configuration.

        These are enabled with the --experimental_allow_unresolved_symlinks flag.

        Typical usage of this rule is via a macro which automatically sets this
        attribute based on a `config_setting` rule.
        """,
    ),
}

_BIN_TMPL = """#!/bin/sh
basedir=$(dirname "$(echo "$0" | sed -e 's,\\\\,/,g')")
exec node "$basedir/{bin_path}" "$@"
"""

def _impl(ctx):
    store_info = ctx.attr.src[NpmPackageStoreInfo]

    virtual_store_directory = store_info.virtual_store_directory
    if not virtual_store_directory:
        fail("src must be a npm_link_package that provides a virtual_store_directory")

    if virtual_store_directory.owner.workspace_name != ctx.label.workspace_name:
        msg = "expected virtual_store_directory to be in the same workspace as the link target '{}' but found '{}'".format(
            ctx.label.workspace_name,
            virtual_store_directory.owner.workspace_name,
        )
        fail(msg)

    package = ctx.attr.package if ctx.attr.package else store_info.package

    # symlink the package's path in the virtual store to the root of the node_modules
    # "node_modules/{package}" so it is available as a direct dependency
    root_symlink_path = paths.join("node_modules", package)

    files = utils.make_symlink(ctx, root_symlink_path, virtual_store_directory)

    for bin_name, bin_path in ctx.attr.bins.items():
        if ctx.label.package:
            path_to_root = "/".join([".."] * len(ctx.label.package.split("/")))
        else:
            path_to_root = "."
        bin_file = ctx.actions.declare_file(paths.join("node_modules", ".bin", bin_name))
        bin_path = paths.normalize(paths.join("../..", path_to_root, virtual_store_directory.short_path, bin_path))
        ctx.actions.write(
            bin_file,
            _BIN_TMPL.format(bin_path = bin_path),
            is_executable = True,
        )
        files.append(bin_file)

    transitive_files = files + store_info.transitive_files

    files_depset = depset(files)

    npm_linked_package_info = NpmLinkedPackageInfo(
        label = ctx.label,
        link_package = ctx.label.package,
        package = store_info.package,
        version = store_info.version,
        store_info = store_info,
        # pass lists through depsets to remove duplicates
        files = files_depset.to_list(),
        transitive_files = sets.to_list(sets.make(transitive_files)),
    )

    providers = [
        DefaultInfo(
            # Only provide direct files in DefaultInfo files
            files = files_depset,
            # Include all transitives in runfiles so that this target can be used in the data
            # of a generic binary target such as sh_binary
            runfiles = ctx.runfiles(transitive_files),
        ),
        js_info_complete(JsInfo(
            npm_linked_packages = [npm_linked_package_info],
            transitive_npm_linked_packages = [npm_linked_package_info],
        )),
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
