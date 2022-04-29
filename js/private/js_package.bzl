"js_package rule"

load("@aspect_bazel_lib//lib:copy_to_directory.bzl", "copy_to_directory_lib")
load("@aspect_bazel_lib//lib:copy_directory.bzl", "copy_directory_action")
load("@bazel_skylib//lib:dicts.bzl", "dicts")
load("@rules_nodejs//nodejs:providers.bzl", "DeclarationInfo")

JsPackageInfo = provider(
    doc = "A provider that carries the output directory (a TreeArtifact) of a js_package which contains the packages sources along with the package name and version",
    fields = {
        "label": "the label of the target the created this provider",
        "package": "name of this node package",
        "version": "version of this node package",
        "directory": "the output directory (a TreeArtifact) that contains the package sources",
    },
)

_DOC = """A rule that packages sources into a TreeArtifact or forwards a tree artifact and provides a JsPackageInfo.

This target can be used as the src attribute to link_js_package.

A DeclarationInfo is also provided so that the target can be used as an input to rules that expect one such as ts_project."""

_ATTRS = dicts.add({
    "src": attr.label(
        doc = "A source directory or output directory to use for this package. For specifying a list of files, use `srcs` instead.",
        allow_single_file = True,
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
    "_windows_constraint": attr.label(default = "@platforms//os:windows"),
}, copy_to_directory_lib.attrs)

def _impl(ctx):
    is_windows = ctx.target_platform_has_constraint(ctx.attr._windows_constraint[platform_common.ConstraintValueInfo])

    if ctx.attr.src and ctx.attr.srcs:
        fail("Exactly one of src or srcs must be specified")
    if not ctx.attr.src and not ctx.attr.srcs:
        fail("Exactly one of src or srcs must be specified")

    if not ctx.attr.package:
        fail("package attr must not be empty")
    if not ctx.attr.version:
        fail("version attr must not be empty")

    if ctx.attr.src:
        if ctx.file.src.is_source:
            # copy the source directory to a TreeArtifact
            directory = ctx.actions.declare_directory(ctx.attr.name)
            copy_directory_action(ctx, ctx.file.src, directory, is_windows = is_windows)
        elif ctx.file.src.is_directory:
            # pass-through since src is already a TreeArtifact
            directory = ctx.file.src
        else:
            fail("Expected src to be a source directory or an output directory")
        providers = [
            DefaultInfo(files = depset([directory]), runfiles = ctx.runfiles([directory])),
        ]
    else:
        providers = copy_to_directory_lib.impl(ctx)
        if len(providers) != 1:
            fail("Expecting only a DefaultInfo providers from copy_to_directory_lib.implementation")

        default_info_files = providers[0].files.to_list()
        if len(default_info_files) != 1:
            fail("Expecting only a single output file from copy_to_directory_lib.implementation")

        directory = default_info_files[0]
        if not directory.is_directory:
            fail("Expecting an output directory from copy_to_directory_lib.implementation")

    # TODO: add a verification action that checks that the package and version match the contained package.json;
    #       if no package.json is found in the directory then optional generate one

    providers.extend([
        DeclarationInfo(
            declarations = [directory],
        ),
        JsPackageInfo(
            label = ctx.label,
            package = ctx.attr.package,
            version = ctx.attr.version,
            directory = directory,
        ),
    ])
    return providers

js_package_lib = struct(
    attrs = _ATTRS,
    implementation = _impl,
    provides = [DefaultInfo, DeclarationInfo, JsPackageInfo],
)

js_package = rule(
    doc = _DOC,
    implementation = js_package_lib.implementation,
    attrs = js_package_lib.attrs,
    provides = js_package_lib.provides,
)
