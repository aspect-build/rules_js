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

NpmPackageInfo = provider(
    doc = "A provider that carries the output directory (a TreeArtifact) of an npm package which contains the packages sources along with the package name and version",
    fields = {
        "label": "the label of the target the created this provider",
        "package": "name of this node package",
        "version": "version of this node package",
        "directory": "the output directory (a TreeArtifact) that contains the package sources",
    },
)

_DOC = """A rule that packages sources into a TreeArtifact or forwards a tree artifact and provides a NpmPackageInfo.

This target can be used as the src attribute to npm_link_package.

A DeclarationInfo is also provided so that the target can be used as an input to rules that expect one such as ts_project."""

_ATTRS = dicts.add({
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
    "_windows_constraint": attr.label(default = "@platforms//os:windows"),
}, copy_to_directory_lib.attrs)

def _impl(ctx):
    is_windows = ctx.target_platform_has_constraint(ctx.attr._windows_constraint[platform_common.ConstraintValueInfo])

    dst = ctx.actions.declare_directory(ctx.attr.out if ctx.attr.out else ctx.attr.name)

    additional_files_depsets = []

    # include direct declaration files from DeclarationInfo of srcs; not transitive
    for src in ctx.attr.srcs:
        if DeclarationInfo in src:
            additional_files_depsets.append(src[DeclarationInfo].declarations)

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
