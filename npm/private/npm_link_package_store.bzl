"npm_link_package_store rule"

load("//js:providers.bzl", "JsInfo", "js_info")
load(":npm_package_store_info.bzl", "NpmPackageStoreInfo")
load(":utils.bzl", "utils")

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
        providers = [NpmPackageStoreInfo, JsInfo],
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
    store_js_info = ctx.attr.src[JsInfo]

    package_store_directory = store_info.package_store_directory
    if not package_store_directory:
        fail("src must be a npm_link_package that provides a package_store_directory")

    if package_store_directory.owner.repo_name != ctx.label.repo_name:
        msg = "expected package_store_directory to be in the same workspace as the link target '{}' but found '{}'".format(
            ctx.label.repo_name,
            package_store_directory.owner.repo_name,
        )
        fail(msg)

    package = ctx.attr.package if ctx.attr.package else store_info.package

    # symlink the package's path in the package store to the root of the node_modules
    # "node_modules/{package}" so it is available as a direct dependency
    root_symlink_path = "node_modules/{}".format(package)

    files = [utils.make_symlink(ctx, root_symlink_path, package_store_directory.path)]

    for bin_name, bin_path in ctx.attr.bins.items():
        bin_file = ctx.actions.declare_file("node_modules/.bin/{}".format(bin_name))
        bin_path = "../{}/{}".format(package, bin_path)
        ctx.actions.write(
            bin_file,
            _BIN_TMPL.format(bin_path = bin_path),
            is_executable = True,
        )
        files.append(bin_file)

    # All files required to run the package if consumed as `DefaultInfo`
    files_depset = depset(files, transitive = [
        store_info.files,
        store_js_info.npm_sources,
        store_js_info.sources,
    ])
    transitive_files_depset = depset(files, transitive = [
        store_info.transitive_files,
        store_js_info.npm_sources,
        store_js_info.transitive_sources,
    ])

    # Additional npm_sources required to to run the package, in addition to other
    # data included in JsInfo provider.
    npm_sources = depset(files, transitive = [
        store_info.transitive_files,
        store_js_info.npm_sources,
    ])

    providers = [
        # Provide default info to allow consuming the package via `data` of rules
        # not aware of JsInfo such as `sh_binary` etc.
        DefaultInfo(
            # Only provide direct files in DefaultInfo files
            files = files_depset,
            # Include all transitives in runfiles so that this target can be used in the data
            # of a generic binary target such as sh_binary
            runfiles = ctx.runfiles(transitive_files = transitive_files_depset).merge(ctx.attr.src[DefaultInfo].default_runfiles),
        ),
        js_info(
            target = ctx.label,
            sources = store_js_info.sources,
            transitive_sources = store_js_info.transitive_sources,
            types = store_js_info.types,
            transitive_types = store_js_info.transitive_types,
            npm_sources = npm_sources,
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
