"""
Rules for linking npm dependencies and packaging and linking first-party deps.

Load these with,

```starlark
load("@aspect_rules_js//npm:defs.bzl", "npm_package")
```
"""

load("@aspect_bazel_lib//lib:copy_to_directory.bzl", "copy_to_directory_action", "copy_to_directory_lib")
load("@bazel_skylib//lib:dicts.bzl", "dicts")
load("@rules_nodejs//nodejs:providers.bzl", "DeclarationInfo", "declaration_info")
load(":npm_package_info.bzl", "NpmPackageInfo")
load(":npm_linked_package_store_deps_info.bzl", "NpmLinkedPackageStoreDepsInfo")
load(":npm_linked_package_store_info.bzl", "NpmLinkedPackageStoreInfo")

_DOC = """A rule that packages sources into a TreeArtifact or forwards a tree artifact and provides a NpmPackageInfo.

This target can be used as the src attribute to npm_link_package.

A DeclarationInfo is also provided so that the target can be used as an input to rules that expect one such as ts_project."""

def _npm_linked_package_deps_aspect_impl(target, ctx):
    deps = []
    if hasattr(ctx.rule.attr, "npm_linked_package_deps"):
        for target in ctx.rule.attr.npm_linked_package_deps:
            if NpmLinkedPackageStoreInfo in target:
                deps.append(target[NpmLinkedPackageStoreInfo])
            if NpmLinkedPackageStoreDepsInfo in target:
                deps.extend(target[NpmLinkedPackageStoreDepsInfo].deps)
    return NpmLinkedPackageStoreDepsInfo(deps = deps)

_npm_linked_package_deps_aspect = aspect(
    doc = "Accumulates NpmLinkedPackageStoreInfo providers and exports them with a NpmLinkedPackageStoreDepsInfo provider",
    implementation = _npm_linked_package_deps_aspect_impl,
    attr_aspects = ["npm_linked_package_deps"],
)

_ATTRS = dicts.add(copy_to_directory_lib.attrs, {
    "srcs": attr.label_list(
        allow_files = True,
        doc = """Files and/or directories or targets that provide DirectoryPathInfo to copy
        into the output directory.""",
        aspects = [_npm_linked_package_deps_aspect],
    ),
    "package": attr.string(
        doc = """The package name. If set, should match the `name` field in the `package.json` file for this package.

If set, the package name set here will be used for linking if a npm_link_package does not specify a package name. A 
npm_link_package target that specifies a package name will override the value here when linking.

If unset, a npm_link_package target that references this npm_package must define the package name must be for linking.
""",
    ),
    "version": attr.string(
        doc = """The package version. If set, should match the `version` field in the `package.json` file for this package.

If set, a npm_link_package may omit the package version and the package version set here will be used for linking. A 
npm_link_package target that specifies a package version will override the value here when linking.

If unset, a npm_link_package target that references this npm_package must define the package version must be for linking.
""",
        default = "0.0.0",
    ),
    "npm_linked_package_deps": attr.label_list(
        doc = """Direct npm dependencies to link with this npm package.

        These can be direct npm links targets from any directly linked npm package such as //:node_modules/foo
        or virtual store npm link targets such as //.aspect_rules_js/node_modules/foo/1.2.3.

        When a direct npm link target is passed, the underlying virtual store target is used. In other words,
        the direct link itself is not used but rather the virtual store that is backing it that is linked as a
        direct dependency of this npm package when this npm package is linked downstream.
        """,
        providers = [NpmLinkedPackageStoreInfo],
    ),
    "_windows_constraint": attr.label(default = "@platforms//os:windows"),
})

def _impl(ctx):
    is_windows = ctx.target_platform_has_constraint(ctx.attr._windows_constraint[platform_common.ConstraintValueInfo])

    dst = ctx.actions.declare_directory(ctx.attr.out if ctx.attr.out else ctx.attr.name)

    additional_files_depsets = []

    npm_linked_package_deps = ctx.attr.npm_linked_package_deps[:]

    for src in ctx.attr.srcs:
        # include direct declaration files from DeclarationInfo of srcs; not transitive
        if DeclarationInfo in src:
            additional_files_depsets.append(src[DeclarationInfo].declarations)

        # gather additional direct npm dependencies to link with this package from srcs
        if NpmLinkedPackageStoreDepsInfo in src:
            npm_linked_package_deps.extend(src[NpmLinkedPackageStoreDepsInfo].deps)

    copy_to_directory_action(
        ctx,
        srcs = ctx.attr.srcs,
        dst = dst,
        additional_files = depset(transitive = additional_files_depsets).to_list(),
        root_paths = ctx.attr.root_paths,
        include_external_repositories = ctx.attr.include_external_repositories,
        exclude_prefixes = ctx.attr.exclude_prefixes,
        replace_prefixes = ctx.attr.replace_prefixes,
        allow_overwrites = ctx.attr.allow_overwrites,
        is_windows = is_windows,
    )

    # TODO: add a verification action that checks that the package and version match the contained package.json;
    #       if no package.json is found in the directory then optional generate one

    return [
        DefaultInfo(
            files = depset([dst]),
            runfiles = ctx.runfiles([dst]),
        ),
        declaration_info(depset([dst])),
        NpmPackageInfo(
            label = ctx.label,
            package = ctx.attr.package,
            version = ctx.attr.version,
            directory = dst,
            npm_linked_package_deps = npm_linked_package_deps,
        ),
    ]

npm_package_lib = struct(
    attrs = _ATTRS,
    implementation = _impl,
    provides = [DefaultInfo, DeclarationInfo, NpmPackageInfo],
)

npm_package = rule(
    doc = _DOC,
    implementation = npm_package_lib.implementation,
    attrs = npm_package_lib.attrs,
    provides = npm_package_lib.provides,
)
