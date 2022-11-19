"""
Rules for linking npm dependencies and packaging and linking first-party deps.

Load these with,

```starlark
load("@aspect_rules_js//npm:defs.bzl", "npm_package")
```
"""

load("@aspect_bazel_lib//lib:copy_to_directory.bzl", "copy_to_directory_action", "copy_to_directory_lib")
load("@aspect_bazel_lib//lib:jq.bzl", "jq")
load("@bazel_skylib//lib:dicts.bzl", "dicts")
load("//js:libs.bzl", "js_lib_helpers")
load("//js:providers.bzl", "JsInfo")
load(":npm_package_info.bzl", "NpmPackageInfo")

_DOC = """A rule that packages sources into a directory (a tree artifact) and provides an `NpmPackageInfo`.

This target can be used as the `src` attribute to `npm_link_package`.

`npm_package` makes use of `copy_to_directory`
(https://github.com/aspect-build/bazel-lib/blob/main/docs/copy_to_directory.md) under the hood,
adopting its API and its copy action using composition. However, unlike `copy_to_directory`,
npm_package includes `transitive_sources` and `transitive_declarations` files from `JsInfo` providers in srcs
by default. The behavior of including sources and declarations from `JsInfo` can be configured
using the `include_sources`, `include_transitive_sources`, `include_declarations`, `include_transitive_declarations`
attributes.

`npm_package` also includes default runfiles from `srcs` by default which `copy_to_directory` does not. This behavior
can be configured with the `include_runfiles` attribute.

The default `include_srcs_packages`, `[".", "./**"]`, prevents files from outside of the target's
package and subpackages from being included.

The default `exclude_srcs_patterns`, of `["node_modules/**", "**/node_modules/**"]`, prevents
`node_modules` files from being included.

To stamp the current git tag as the "version" in the package.json file, see
[stamped_package_json](#stamped_package_json)
"""

# Pull in all copy_to_directory attributes except for exclude_prefixes
copy_to_directory_lib_attrs = dict(copy_to_directory_lib.attrs)
copy_to_directory_lib_attrs.pop("exclude_prefixes")

_ATTRS = dicts.add(copy_to_directory_lib_attrs, {
    "package": attr.string(
        doc = """The package name. If set, should match the `name` field in the `package.json` file for this package.

If set, the package name set here will be used for linking if a npm_link_package does not specify a package name. A 
npm_link_package that specifies a package name will override the value here when linking.

If unset, a npm_link_package that references this npm_package must define the package name must be for linking.
""",
    ),
    "version": attr.string(
        doc = """The package version. If set, should match the `version` field in the `package.json` file for this package.

If set, a npm_link_package may omit the package version and the package version set here will be used for linking. A 
npm_link_package that specifies a package version will override the value here when linking.

If unset, a npm_link_package that references this npm_package must define the package version must be for linking.
""",
        default = "0.0.0",
    ),
    "include_srcs_packages": attr.string_list(
        default = [".", "./**"],
        doc = """List of Bazel packages (with glob support) to include in output directory.

        Glob patterns `**`, `*` and `?` are supported. See `glob_match` documentation for
        more details on how to use glob patterns:
        https://github.com/aspect-build/bazel-lib/blob/main/docs/glob_match.md.

        Files and directories in srcs are only copied to the output directory if
        the Bazel package of the file or directory matches one of the patterns specified.

        Forward slashes (`/`) should be used as path separators.

        A "." value expands to the target's package path (`ctx.label.package`).
        A "./**" value expands to the target's package path followed by a slash and a
        globstar (`"{{}}/**".format(ctx.label.package)`).

        Defaults to [".", "./**"] which includes sources target's package and subpackages.

        Files and directories that have matching Bazel packages are subject to subsequent filters and
        transformations to determine if they are copied and what their path in the output
        directory will be.

        See `copy_to_directory_action` documentation for list of order of filters and transformations:
        https://github.com/aspect-build/bazel-lib/blob/main/docs/copy_to_directory.md#copy_to_directory.
        """,
    ),
    "exclude_srcs_patterns": attr.string_list(
        default = [
            "node_modules/**",
            "**/node_modules/**",
        ],
        doc = """List of paths (with glob support) to exclude from output directory.

        Glob patterns `**`, `*` and `?` are supported. See `glob_match` documentation for
        more details on how to use glob patterns:
        https://github.com/aspect-build/bazel-lib/blob/main/docs/glob_match.md.

        Files and directories in srcs are not copied to the output directory if their output
        directory path, after applying `root_paths`, matches one of the patterns specified.

        Patterns do not look into files within source directory or generated directory (TreeArtifact)
        targets since matches are performed in Starlark. To use `include_srcs_patterns` on files
        within directories you can use the `make_directory_paths` helper to specify individual files inside
        directories in `srcs`. This restriction may be fixed in a future release by performing matching
        inside the copy action instead of in Starlark.

        Forward slashes (`/`) should be used as path separators.

        Defaults to ["node_modules/**", "**/node_modules/**"] which excludes all node_modules folders
        from the output directory.

        Files and directories that do not have matching output directory paths are subject to subsequent
        filters and transformations to determine if they are copied and what their path in the output
        directory will be.

        See `copy_to_directory_action` documentation for list of order of filters and transformations:
        https://github.com/aspect-build/bazel-lib/blob/main/docs/copy_to_directory.md#copy_to_directory.
        """,
    ),
    "data": attr.label_list(
        doc = """Runtime / linktime npm dependencies of this npm package.

        `NpmPackageStoreInfo` providers are gathered from `JsInfo` of the targets specified. Targets can be linked npm
        packages, npm package store targets or other targets that provide `JsInfo`. This is done directly from the
        `npm_package_store_deps` field of these. For linked npm package targets, the underlying npm_package_store
        target(s) that back the links is used.

        Gathered `NpmPackageStoreInfo` providers are used downstream as direct dependencies of this npm package when
        linking with `npm_link_package`.
        """,
    ),
    "include_sources": attr.bool(
        doc = """When True, `sources` from `JsInfo` providers in data targets are included in the list of available files to copy.""",
        default = True,
    ),
    "include_transitive_sources": attr.bool(
        doc = """When True, `transitive_sources` from `JsInfo` providers in data targets are included in the list of available files to copy.""",
        default = True,
    ),
    "include_declarations": attr.bool(
        doc = """When True, `declarations` from `JsInfo` providers in data targets are included in the list of available files to copy.""",
        default = True,
    ),
    "include_transitive_declarations": attr.bool(
        doc = """When True, `transitive_declarations` from `JsInfo` providers in data targets are included in the list of available files to copy.""",
        default = True,
    ),
    "include_runfiles": attr.bool(
        doc = """When True, default runfiles from `srcs` targets are included in the list of available files to copy.

This may be needed in a few cases:

- to work-around issues with rules that don't provide everything needed in sources, transitive_sources, declarations & transitive_declarations
- to depend on the runfiles targets that don't use JsInfo

NB: The default value will be flipped to False in the next major release as runfiles are not needed in the general case
and adding them to the list of files available to copy can add noticeable overhead to the analysis phase in a large
repository with many npm_package targets.
""",
        # TODO(2.0): flip default to False
        default = True,
    ),
    "_windows_constraint": attr.label(default = "@platforms//os:windows"),
})

def _impl(ctx):
    is_windows = ctx.target_platform_has_constraint(ctx.attr._windows_constraint[platform_common.ConstraintValueInfo])

    dst = ctx.actions.declare_directory(ctx.attr.out if ctx.attr.out else ctx.attr.name)

    additional_files_depsets = []

    if ctx.attr.include_transitive_sources:
        # include all transitive sources (this includes direct sources)
        additional_files_depsets.extend([
            target[JsInfo].transitive_sources
            for target in ctx.attr.srcs
            if JsInfo in target and hasattr(target[JsInfo], "transitive_sources")
        ])
    elif ctx.attr.include_sources:
        # include only direct sources
        additional_files_depsets.extend([
            target[JsInfo].sources
            for target in ctx.attr.srcs
            if JsInfo in target and hasattr(target[JsInfo], "sources")
        ])

    if ctx.attr.include_transitive_declarations:
        # include all transitive declarations (this includes direct declarations)
        additional_files_depsets.extend([
            target[JsInfo].transitive_declarations
            for target in ctx.attr.srcs
            if JsInfo in target and hasattr(target[JsInfo], "transitive_declarations")
        ])
    elif ctx.attr.include_declarations:
        # include only direct declarations
        additional_files_depsets.extend([
            target[JsInfo].declarations
            for target in ctx.attr.srcs
            if JsInfo in target and hasattr(target[JsInfo], "declarations")
        ])

    if ctx.attr.include_runfiles:
        # include default runfiles from srcs
        additional_files_depsets.extend([
            target[DefaultInfo].default_runfiles.files
            for target in ctx.attr.srcs
        ])

    # forward all npm_package_store_deps
    npm_package_store_deps = [
        target[JsInfo].npm_package_store_deps
        for target in ctx.attr.srcs
        if JsInfo in target and hasattr(target[JsInfo], "npm_package_store_deps")
    ]
    npm_package_store_deps.append(js_lib_helpers.gather_npm_package_store_deps(
        targets = ctx.attr.data,
    ))

    copy_to_directory_action(
        ctx,
        srcs = ctx.attr.srcs,
        dst = dst,
        additional_files = depset(transitive = additional_files_depsets),
        root_paths = ctx.attr.root_paths,
        include_external_repositories = ctx.attr.include_external_repositories,
        include_srcs_packages = ctx.attr.include_srcs_packages,
        exclude_srcs_packages = ctx.attr.exclude_srcs_packages,
        include_srcs_patterns = ctx.attr.include_srcs_patterns,
        exclude_srcs_patterns = ctx.attr.exclude_srcs_patterns,
        replace_prefixes = ctx.attr.replace_prefixes,
        allow_overwrites = ctx.attr.allow_overwrites,
        is_windows = is_windows,
    )

    # TODO: add a verification action that checks that the package and version match the contained package.json;
    #       if no package.json is found in the directory then optional generate one

    return [
        DefaultInfo(
            files = depset([dst]),
        ),
        NpmPackageInfo(
            package = ctx.attr.package,
            version = ctx.attr.version,
            directory = dst,
            npm_package_store_deps = depset([], transitive = npm_package_store_deps),
        ),
    ]

npm_package_lib = struct(
    attrs = _ATTRS,
    implementation = _impl,
    provides = [DefaultInfo, NpmPackageInfo],
)

npm_package = rule(
    doc = _DOC,
    implementation = npm_package_lib.implementation,
    attrs = npm_package_lib.attrs,
    provides = npm_package_lib.provides,
)

def stamped_package_json(name, stamp_var, **kwargs):
    """Convenience wrapper to set the "version" property in package.json with the git tag.

    In unstamped builds (typically those without `--stamp`) the version will be set to `0.0.0`.
    This ensures that actions which use the package.json file can get cache hits.

    For more information on stamping, read https://github.com/aspect-build/bazel-lib/blob/main/docs/stamping.md.

    Using this rule requires that you register the jq toolchain in your WORKSPACE:

    ```starlark
    load("@aspect_bazel_lib//lib:repositories.bzl", "register_jq_toolchains")

    register_jq_toolchains()
    ```

    Args:
        name: name of the resulting `jq` target, must be "package"
        stamp_var: a key from the bazel-out/stable-status.txt or bazel-out/volatile-status.txt files
        **kwargs: additional attributes passed to the jq rule, see https://github.com/aspect-build/bazel-lib/blob/main/docs/jq.md
    """
    if name != "package":
        fail("""stamped_package_json should always be named "package" so that the default output is named "package.json".
        This is required since Bazel doesn't allow a predeclared output to have the same name as an input file.""")

    jq(
        name = name,
        srcs = ["package.json"],
        filter = "|".join([
            # Don't directly reference $STAMP as it's only set when stamping
            # This 'as' syntax results in $stamp being null in unstamped builds.
            "$ARGS.named.STAMP as $stamp",
            # Provide a default using the "alternative operator" in case $stamp is null.
            ".version = ($stamp.{} // \"0.0.0\")".format(stamp_var),
        ]),
        **kwargs
    )
