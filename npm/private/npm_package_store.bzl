"npm_package_store rule"

load("@aspect_bazel_lib//lib:copy_directory.bzl", "copy_directory_bin_action")

# buildifier: disable=bzl-visibility
load("//js/private:js_info.bzl", "JsInfo", "js_info")
load(":npm_package_info.bzl", "NpmPackageInfo")
load(":npm_package_store_info.bzl", "NpmPackageStoreInfo")
load(":utils.bzl", "utils")

_DOC = """Defines a npm package that is linked into a node_modules tree.

The npm package is linked with a pnpm style symlinked node_modules output tree.

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
        doc = """A target providing a `NpmPackageInfo` or `JsInfo` containing the package sources.
        """,
        mandatory = True,
    ),
    "deps": attr.label_keyed_string_dict(
        doc = """Other node packages store link targets one depends on mapped to the name to link them under in this packages deps.

        This should include *all* modules the program may need at runtime.

        You can find all the package store link targets in your repository with

        ```
        bazel query ... | grep :.aspect_rules_js | grep -v /dir | grep -v /pkg | grep -v /ref
        ```

        Package store link targets names for 3rd party packages that come from `npm_translate_lock`
        start with `.aspect_rules_js/` then the name passed to the `npm_link_all_packages` macro
        (typically `node_modules`) followed by `/<package>/<version>` where `package` is the
        package name (including @scope segment if any) and `version` is the specific version of
        the package that comes from the pnpm-lock.yaml file.

        For example,

        ```
        //:.aspect_rules_js/node_modules/cliui/7.0.4
        ```

        The version may include peer dep(s),

        ```
        //:.aspect_rules_js/node_modules/debug/4.3.4_supports-color@8.1.1
        ```

        It could be also be a url based version,

        ```
        //:.aspect_rules_js/node_modules/debug/github.com/ngokevin/debug/9742c5f383a6f8046241920156236ade8ec30d53
        ```

        Package store link targets names for 3rd party package that come directly from an
        `npm_import` start with `.aspect_rules_js/` then the name passed to the `npm_import`'s `npm_link_imported_package`
        macro (typically `node_modules`) followed by `/<package>/<version>` where `package`
        matches the `package` attribute in the npm_import of the package and `version` matches the
        `version` attribute.

        For example,

        ```
        //:.aspect_rules_js/node_modules/cliui/7.0.4
        ```

        Package store link targets names for 1st party packages automatically linked by `npm_link_all_packages`
        using workspaces will follow the same pattern as 3rd party packages with the version typically defaulting
        to "0.0.0".

        For example,

        ```
        //:.aspect_rules_js/node_modules/@mycorp/mypkg/0.0.0
        ```

        Package store link targets names for 1st party packages manually linked with `npm_link_package`
        start with `.aspect_rules_js/` followed by the name passed to the `npm_link_package`.

        For example,

        ```
        //:.aspect_rules_js/node_modules/@mycorp/mypkg
        ```

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
        providers = [NpmPackageStoreInfo, JsInfo],
    ),
    "exclude_package_contents": attr.string_list(
        doc = """List of exclude patterns to exclude files from the package store.

        The exclude patterns are relative to the package store directory.
        """,
        default = [],
    ),
    "package": attr.string(
        doc = """The package name to link to.

If unset, the package name in the `NpmPackageInfo` src must be set.
If set, takes precendance over the package name in the `NpmPackageInfo` src.
""",
    ),
    "version": attr.string(
        doc = """The package version being linked.

If unset, the package version in the `NpmPackageInfo` src must be set.
If set, takes precendance over the package version in the `NpmPackageInfo` src.
""",
    ),
    "dev": attr.bool(
        doc = """Whether this npm package is a dev dependency""",
    ),
    "hardlink": attr.string(
        values = ["auto", "off", "on"],
        default = "auto",
        doc = """Controls when to use hardlinks to files instead of making copies.

        Creating hardlinks is much faster than making copies of files with the caveat that
        hardlinks share file permissions with their source.

        Since Bazel removes write permissions on files in the output tree after an action completes,
        hardlinks to source files is not recommended since write permissions will be inadvertently
        removed from sources files.

        - "auto": hardlinks are used for generated files already in the output tree
        - "off": all files are copied
        - "on": hardlinks are used for all files (not recommended)

        NB: Hardlinking source files in external repositories as was done under the hood
        prior to https://github.com/aspect-build/rules_js/pull/1533 may lead to flaky build
        failures as reported in https://github.com/aspect-build/rules_js/issues/1412.
        """,
    ),
    "verbose": attr.bool(
        doc = """If true, prints out verbose logs to stdout""",
    ),
}

def _npm_package_store_impl(ctx):
    if ctx.attr.src:
        if NpmPackageInfo in ctx.attr.src:
            package = ctx.attr.package if ctx.attr.package else ctx.attr.src[NpmPackageInfo].package
            version = ctx.attr.version if ctx.attr.version else ctx.attr.src[NpmPackageInfo].version
        elif JsInfo in ctx.attr.src:
            if not ctx.attr.package:
                msg = "Expected package to be specified in '{}' when src '{}' provides a JsInfo".format(ctx.label, ctx.attr.src[JsInfo].target)
                fail(msg)
            package = ctx.attr.package
            version = ctx.attr.version if ctx.attr.version else "0.0.0"
        else:
            msg = "Expected src of '{}' to provide either NpmPackageInfo or JsInfo".format(ctx.label)
            fail(msg)
    else:
        # ctx.attr.src can be unspecified when the rule is a npm_package_store_internal; when it is _not_
        # set, this is a terminal 3p package with ctx.attr.deps being the transitive closure of
        # deps; this pattern is used to break circular dependencies between 3rd party npm deps; it
        # is not used for 1st party deps
        package = ctx.attr.package
        version = ctx.attr.version

    if not package:
        fail("No package name specified to link to. Package name must either be specified explicitly via 'package' attribute or come from the 'src' 'NpmPackageInfo', typically a 'npm_package' target")
    if not version:
        fail("No package version specified to link to. Package version must either be specified explicitly via 'version' attribute or come from the 'src' 'NpmPackageInfo', typically a 'npm_package' target")

    package_store_name = utils.package_store_name(package, version)
    package_store_directory = None

    # files required to create the package store entry
    files = []
    transitive_files_depsets = []

    # JsInfo of the package and all deps required to run
    js_infos = []

    # NpmPackageStoreInfo of the package and deps
    npm_package_store_infos = []

    # Direct references to all dependencies
    direct_ref_deps = {}

    # the path to the package store location for this package
    # "node_modules/{package_store_root}/{package_store_name}/node_modules/{package}"
    package_store_directory_path = "node_modules/{}/{}/node_modules/{}".format(utils.package_store_root, package_store_name, package)

    if ctx.attr.src and NpmPackageInfo in ctx.attr.src:
        npm_pkg_info = ctx.attr.src[NpmPackageInfo]

        # output the package as a TreeArtifact to its package store location
        if ctx.label.repo_name and ctx.label.package:
            expected_short_path = "../{}/{}/{}".format(ctx.label.repo_name, ctx.label.package, package_store_directory_path)
        elif ctx.label.repo_name:
            expected_short_path = "../{}/{}".format(ctx.label.repo_name, package_store_directory_path)
        elif ctx.label.package:
            expected_short_path = "{}/{}".format(ctx.label.package, package_store_directory_path)
        else:
            expected_short_path = package_store_directory_path

        src = npm_pkg_info.src
        if src.short_path == expected_short_path:
            # the input is already the desired output; this is the pattern for
            # packages with lifecycle hooks
            package_store_directory = src
        else:
            package_store_directory = ctx.actions.declare_directory(package_store_directory_path)
            if utils.is_tarball_extension(src.extension):
                # npm packages are always published with one top-level directory inside the tarball,
                # tho the name is not predictable we can use the --strip-components 1 argument with
                # tar to strip one directory level. Some packages have directory permissions missing
                # executable which make the directories not listable (pngjs@5.0.0 for example).
                bsdtar = ctx.toolchains["@aspect_bazel_lib//lib:tar_toolchain_type"]

                tar_exclude_package_contents = []
                if ctx.attr.exclude_package_contents:
                    for pattern in ctx.attr.exclude_package_contents:
                        if pattern == "":
                            continue
                        tar_exclude_package_contents.append("--exclude")
                        tar_exclude_package_contents.append(pattern)

                ctx.actions.run(
                    executable = bsdtar.tarinfo.binary,
                    inputs = depset(direct = [src], transitive = [bsdtar.default.files]),
                    outputs = [package_store_directory],
                    arguments = [
                        "--extract",
                    ] + tar_exclude_package_contents + [
                        "--no-same-owner",
                        "--no-same-permissions",
                        "--strip-components",
                        "1",
                        "--file",
                        src.path,
                        "--directory",
                        package_store_directory.path,
                    ],
                    mnemonic = "NpmPackageExtract",
                    progress_message = "Extracting npm package {}@{}".format(package, version),

                    # Always override the locale to give better hermeticity.
                    # See https://github.com/aspect-build/rules_js/issues/2039
                    env = getattr(bsdtar.tarinfo, "default_env", {}),
                )
            else:
                copy_directory_bin_action(
                    ctx,
                    src = src,
                    dst = package_store_directory,
                    copy_directory_bin = ctx.toolchains["@aspect_bazel_lib//lib:copy_directory_toolchain_type"].copy_directory_info.bin,
                    # Hardlinking source files in external repositories as was done under the hood
                    # prior to https://github.com/aspect-build/rules_js/pull/1533 may lead to flaky build
                    # failures as reported in https://github.com/aspect-build/rules_js/issues/1412.
                    hardlink = ctx.attr.hardlink,
                    verbose = ctx.attr.verbose,
                )

        linked_package_store_directories = []
        for dep, _dep_aliases in ctx.attr.deps.items():
            dep_info = dep[NpmPackageStoreInfo]
            dep_aliases = _dep_aliases.split(",") if _dep_aliases else [dep_info.package]
            dep_package_store_directory = dep_info.package_store_directory

            # symlink the package's direct deps to its package store location
            if dep_info.root_package != ctx.label.package:
                msg = """npm_package_store in %s package cannot depend on npm_package_store in %s package.
deps of npm_package_store must be in the same package.""" % (ctx.label.package, dep_info.root_package)
                fail(msg)

            if dep_package_store_directory:
                linked_package_store_directories.append(dep_package_store_directory)
                for dep_alias in dep_aliases:
                    # "node_modules/{package_store_root}/{package_store_name}/node_modules/{package}"
                    dep_symlink_path = "node_modules/{}/{}/node_modules/{}".format(utils.package_store_root, package_store_name, dep_alias)
                    files.append(utils.make_symlink(ctx, dep_symlink_path, dep_package_store_directory.path))
            else:
                # this is a ref npm_link_package, a downstream terminal npm_link_package
                # for this npm dependency will create the dep symlinks for this dep;
                # this pattern is used to break circular dependencies between 3rd
                # party npm deps; it is not used for 1st party deps
                direct_ref_deps[dep] = dep_aliases

        for dep_info in npm_pkg_info.npm_package_store_infos.to_list():
            dep_package_store_directory = dep_info.package_store_directory

            # only link npm package store deps from NpmPackageInfo if they have _not_ already been linked directly
            # from deps; fixes https://github.com/aspect-build/rules_js/issues/1110.
            if dep_package_store_directory not in linked_package_store_directories:
                # "node_modules/{package_store_root}/{package_store_name}/node_modules/{package}"
                dep_symlink_path = "node_modules/{}/{}/node_modules/{}".format(utils.package_store_root, package_store_name, dep_info.package)
                files.append(utils.make_symlink(ctx, dep_symlink_path, dep_package_store_directory.path))

                # Include the store info of all linked dependencies
                npm_package_store_infos.append(dep_info)
    elif ctx.attr.src and JsInfo in ctx.attr.src:
        jsinfo = ctx.attr.src[JsInfo]

        # Symlink to the directory of the target that created this JsInfo
        if ctx.label.repo_name and ctx.label.package:
            symlink_path = "external/{}/{}/{}".format(ctx.label.repo_name, ctx.label.package, package_store_directory_path)
        elif ctx.label.repo_name:
            symlink_path = "external/{}/{}".format(ctx.label.repo_name, package_store_directory_path)
        else:
            symlink_path = package_store_directory_path

        # The package JsInfo including all direct and transitive sources, store info etc.
        js_infos.append(jsinfo)

        if jsinfo.target.repo_name:
            target_path = "{}/external/{}/{}".format(ctx.bin_dir.path, jsinfo.target.repo_name, jsinfo.target.package)
        else:
            target_path = "{}/{}".format(ctx.bin_dir.path, jsinfo.target.package)
        package_store_directory = utils.make_symlink(ctx, symlink_path, target_path)
    elif not ctx.attr.src:
        # ctx.attr.src can be unspecified when the rule is a npm_package_store_internal; when it is _not_
        # set, this is a terminal 3p package with ctx.attr.deps being the transitive closure of
        # deps; this pattern is used to break circular dependencies between 3rd party npm deps; it
        # is not used for 1st party deps
        deps_map = {}
        for dep, _dep_aliases in ctx.attr.deps.items():
            dep_info = dep[NpmPackageStoreInfo]

            # create a map of deps that have package store directories
            if dep_info.package_store_directory:
                deps_map[utils.package_store_name(dep_info.package, dep_info.version)] = dep
            else:
                # this is a ref npm_link_package, a downstream terminal npm_link_package for this npm
                # depedency will create the dep symlinks for this dep; this pattern is used to break
                # for lifecycle hooks on 3rd party deps; it is not used for 1st party deps
                dep_aliases = _dep_aliases.split(",") if _dep_aliases else [dep_info.package]
                direct_ref_deps[dep] = dep_aliases

        for dep in ctx.attr.deps:
            dep_info = dep[NpmPackageStoreInfo]
            dep_package_store_name = utils.package_store_name(dep_info.package, dep_info.version)

            if package_store_name == dep_package_store_name:
                # provide the node_modules directory for this package if found in the transitive_closure
                package_store_directory = dep_info.package_store_directory

            for dep_ref_dep, dep_ref_dep_aliases in dep_info.ref_deps.items():
                dep_ref_dep_package_store_name = utils.package_store_name(dep_ref_dep[NpmPackageStoreInfo].package, dep_ref_dep[NpmPackageStoreInfo].version)
                if not dep_ref_dep_package_store_name in deps_map:
                    # This can happen in lifecycle npm package targets. We have no choice but to
                    # ignore reference back to self in dyadic circular deps in this case since a
                    # transitive dep on this npm package is impossible in an action that is
                    # outputting the package store tree artifact that circular dep would point to.
                    continue
                actual_dep = deps_map[dep_ref_dep_package_store_name]
                dep_ref_def_package_store_directory = actual_dep[NpmPackageStoreInfo].package_store_directory
                if dep_ref_def_package_store_directory:
                    for dep_ref_dep_alias in dep_ref_dep_aliases:
                        # "node_modules/{package_store_root}/{package_store_name}/node_modules/{package}"
                        dep_ref_dep_symlink_path = "node_modules/{}/{}/node_modules/{}".format(utils.package_store_root, dep_package_store_name, dep_ref_dep_alias)
                        files.append(utils.make_symlink(ctx, dep_ref_dep_symlink_path, dep_ref_def_package_store_directory.path))
    else:
        # We should _never_ get here
        fail("Internal error")

    if package_store_directory:
        files.append(package_store_directory)

    # Include the store and js info of all dependencies expected to be linked
    for target in ctx.attr.deps:
        js_infos.append(target[JsInfo])
        npm_package_store_infos.append(target[NpmPackageStoreInfo])

    if ctx.attr.src:
        sources_depset = depset(transitive = [jsinfo.transitive_sources for jsinfo in js_infos])
        types_depset = depset(transitive = [jsinfo.transitive_types for jsinfo in js_infos])
        for npm_package_store_info in npm_package_store_infos:
            transitive_files_depsets.append(npm_package_store_info.transitive_files)
    else:
        # ctx.attr.src can be unspecified when the rule is a npm_package_store_internal; when ctx.attr.src is
        # _not_ set, this is a terminal 3p package with ctx.attr.deps being the transitive closure
        # of deps; this pattern is used to break circular dependencies between 3rd party npm deps;
        # it is not used for 1st party deps; because npm_package_store_infos is the transitive
        # closure of all the entire package store deps, we can safely add just `files` from each of
        # these to `transitive_files_depset`; doing so reduces the size of `transitive_files_depset`
        # significantly and reduces analysis time and Bazel memory usage during analysis
        sources_depset = depset(transitive = [jsinfo.sources for jsinfo in js_infos])
        types_depset = depset(transitive = [jsinfo.types for jsinfo in js_infos])
        for npm_package_store_info in npm_package_store_infos:
            transitive_files_depsets.append(npm_package_store_info.files)

    npm_sources = depset(files, transitive = [jsinfo.npm_sources for jsinfo in js_infos])
    transitive_files_depset = depset(files, transitive = transitive_files_depsets)
    files_depset = depset(files)

    providers = [
        js_info(
            target = ctx.label,
            npm_sources = npm_sources,
            sources = sources_depset,
            transitive_sources = sources_depset,
            types = types_depset,
            transitive_types = types_depset,
        ),
        NpmPackageStoreInfo(
            root_package = ctx.label.package,
            package = package,
            version = version,
            ref_deps = direct_ref_deps,
            package_store_directory = package_store_directory,
            files = files_depset,
            transitive_files = transitive_files_depset,
            dev = ctx.attr.dev,
        ),
    ]

    if ctx.attr.src:
        providers.append(DefaultInfo(
            runfiles = ctx.attr.src[DefaultInfo].default_runfiles,
        ))

    if package_store_directory and package_store_directory.is_directory:
        # Provide an output group that provides a single file which is the
        # package directory for use in $(execpath) and $(rootpath).
        # Output group name must match utils.package_directory_output_group
        providers.append(OutputGroupInfo(package_directory = depset([package_store_directory])))

    return providers

npm_package_store_lib = struct(
    attrs = _ATTRS,
    implementation = _npm_package_store_impl,
    provides = [DefaultInfo, NpmPackageStoreInfo],
    toolchains = [
        Label("@aspect_bazel_lib//lib:copy_directory_toolchain_type"),
        Label("@aspect_bazel_lib//lib:tar_toolchain_type"),
    ],
)

npm_package_store = rule(
    doc = _DOC,
    implementation = npm_package_store_lib.implementation,
    attrs = npm_package_store_lib.attrs,
    provides = npm_package_store_lib.provides,
    toolchains = npm_package_store_lib.toolchains,
)

# Invoked by generated package store targets for local packages
# buildifier: disable=function-docstring
# buildifier: disable=unnamed-macro
def npm_local_package_store_internal(link_root_name, package_store_name, package, version, src, deps, visibility, tags):
    store_target_name = "%s/%s/%s" % (utils.package_store_root, link_root_name, package_store_name)

    npm_package_store(
        name = store_target_name,
        src = src,
        package = package,
        version = version,
        deps = deps,
        visibility = visibility,
        tags = tags,
    )

    # Create aliases for the standard /ref and /pkg targets so local packages can be
    # references in the same way as remote packages.
    native.alias(
        name = "{}/ref".format(store_target_name),
        actual = store_target_name,
        visibility = visibility,
    )
    native.alias(
        name = "{}/pkg".format(store_target_name),
        actual = store_target_name,
        visibility = visibility,
    )
