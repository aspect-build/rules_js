"""js_library groups together JS sources and arranges them and their transitive and npm dependencies into a provided
`JsInfo`. There are no Bazel actions to run.

For example, this `BUILD` file groups a pair of `.js/.d.ts` files along with the `package.json`.
The latter is needed because it contains a `typings` key that allows downstream
users of this library to resolve the `one.d.ts` file.
The `main` key is another commonly used field in `package.json` which would require including it in the library.

```starlark
load("@aspect_rules_js//js:defs.bzl", "js_library")

js_library(
    name = "one",
    srcs = [
        "one.d.ts",
        "one.js",
        "package.json",
    ],
)
```

| This is similar to [`py_library`](https://docs.bazel.build/versions/main/be/python.html#py_library) which depends on
| Python sources and provides a `PyInfo`.
"""

load("@aspect_bazel_lib//lib:copy_to_bin.bzl", "copy_file_to_bin_action")
load(":js_info.bzl", "JsInfo", "js_info")
load(":js_library_helpers.bzl", "JS_LIBRARY_DATA_ATTR", "gather_npm_linked_packages", "gather_npm_package_store_deps", "gather_runfiles", "gather_transitive_declarations", "gather_transitive_sources")

_DOC = """A library of JavaScript sources. Provides JsInfo, the primary provider used in rules_js
and derivative rule sets.

Declaration files are handled separately from sources since they are generally not needed at
runtime and build rules, such as ts_project, are optimal in their build graph if they only depend
on declarations from `deps` since these they don't need the JavaScript source files from deps to
typecheck.

Linked npm dependences are also handled separately from sources since not all rules require them and it
is optimal for these rules to not depend on them in the build graph.

NB: `js_library` copies all source files to the output tree before providing them in JsInfo. See
https://github.com/aspect-build/rules_js/tree/dbb5af0d2a9a2bb50e4cf4a96dbc582b27567155/docs#javascript
for more context on why we do this."""

_ATTRS = {
    "srcs": attr.label_list(
        doc = """Source files that are included in this library.

        This includes all your checked-in code and any generated source files.

        The transitive npm dependencies, transitive sources & runfiles of targets in the `srcs` attribute are added to the
        runfiles of this taregt. They should appear in the '*.runfiles' area of any executable which is output by or has a
        runtime dependency on this target.
        """,
        allow_files = True,
    ),
    "deps": attr.label_list(
        doc = """Dependencies of this target.

        This may include other js_library targets or other targets that provide JsInfo

        The transitive npm dependencies, transitive sources & runfiles of targets in the `deps` attribute are added to the
        runfiles of this taregt. They should appear in the '*.runfiles' area of any executable which is output by or has a
        runtime dependency on this target.
        """,
        providers = [JsInfo],
    ),
    "data": JS_LIBRARY_DATA_ATTR,
    "_windows_constraint": attr.label(default = "@platforms//os:windows"),
}

def _gather_sources_and_declarations(ctx, targets, files, is_windows = False):
    """Gathers sources and declarations from a list of targets

    Args:
        ctx: the rule context

        targets: List of targets to gather sources and declarations from their JsInfo providers.

            These typically come from the `srcs` and/or `data` attributes of a rule

        files: List of files to gather as sources and declarations.

            These typically come from the `srcs` and/or `data` attributes of a rule

        is_windows: If true, an cmd.exe actions are created when copying files to the output tree so there is no bash dependency

    Returns:
        Sources & declaration files depsets in the sequence (sources, declarations)
    """
    sources = []
    declarations = []

    for file in files:
        if file.is_source:
            if ctx.label.package != file.owner.package:
                msg = """

Expected to find source file {file_basename} in {this_package}, but instead it is in {file_package}.

All source files in rules_js rules must be in the same package as the target.

See https://github.com/aspect-build/rules_js/tree/dbb5af0d2a9a2bb50e4cf4a96dbc582b27567155/docs#javascript
for more context on why this is required.

Either move {file_basename} to {this_package}, or add a 'js_library'
target in {file_basename}'s package and add that target to the deps of {this_target}:

    buildozer 'new_load @aspect_rules_js//js:defs.bzl js_library' {file_package}:__pkg__
    buildozer 'new js_library {new_target_name}' {file_package}:__pkg__
    buildozer 'add srcs {file_basename}' {file_package}:{new_target_name}
    buildozer 'add visibility {this_package}:__pkg__' {file_package}:{new_target_name}
    buildozer 'remove srcs {file_package}:{file_basename}' {this_target}
    buildozer 'add srcs {file_package}:{new_target_name}' {this_target}

""".format(
                    file_basename = file.basename,
                    file_package = "%s//%s" % (file.owner.workspace_name, file.owner.package),
                    new_target_name = file.basename.replace(".", "_"),
                    this_package = "%s//%s" % (ctx.label.workspace_name, ctx.label.package),
                    this_target = ctx.label,
                )
                fail(msg)
            file = copy_file_to_bin_action(ctx, file, is_windows = is_windows)

        if file.is_directory:
            # assume a directory contains declarations since we can't know that it doesn't
            declarations.append(file)
            sources.append(file)
        elif (
            file.path.endswith(".d.ts") or
            file.path.endswith(".d.ts.map") or
            file.path.endswith(".d.mts") or
            file.path.endswith(".d.mts.map") or
            file.path.endswith(".d.cts") or
            file.path.endswith(".d.cts.map")
        ):
            declarations.append(file)
        elif file.path.endswith("/package.json"):
            # package.json may be required to resolve declarations with the "typings" key
            declarations.append(file)
            sources.append(file)
        else:
            sources.append(file)

    # sources as depset
    sources = depset(sources, transitive = [
        target[JsInfo].sources
        for target in targets
        if JsInfo in target and hasattr(target[JsInfo], "sources")
    ])

    # declarations as depset
    declarations = depset(declarations, transitive = [
        target[JsInfo].declarations
        for target in targets
        if JsInfo in target and hasattr(target[JsInfo], "declarations")
    ])

    return (sources, declarations)

def _js_library_impl(ctx):
    is_windows = ctx.target_platform_has_constraint(ctx.attr._windows_constraint[platform_common.ConstraintValueInfo])

    sources, declarations = _gather_sources_and_declarations(
        ctx = ctx,
        targets = ctx.attr.srcs,
        files = ctx.files.srcs,
        is_windows = is_windows,
    )

    transitive_sources = gather_transitive_sources(
        sources = sources,
        targets = ctx.attr.srcs + ctx.attr.deps,
    )

    transitive_declarations = gather_transitive_declarations(
        declarations = declarations,
        targets = ctx.attr.srcs + ctx.attr.deps,
    )

    npm_linked_packages = gather_npm_linked_packages(
        srcs = ctx.attr.srcs,
        deps = ctx.attr.deps,
    )

    npm_package_store_deps = gather_npm_package_store_deps(
        targets = ctx.attr.data,
    )

    runfiles = gather_runfiles(
        ctx = ctx,
        sources = transitive_sources,
        data = ctx.attr.data,
        deps = ctx.attr.srcs + ctx.attr.deps,
    )

    return [
        js_info(
            declarations = declarations,
            npm_linked_package_files = npm_linked_packages.direct_files,
            npm_linked_packages = npm_linked_packages.direct,
            npm_package_store_deps = npm_package_store_deps,
            sources = sources,
            transitive_declarations = transitive_declarations,
            transitive_npm_linked_package_files = npm_linked_packages.transitive_files,
            transitive_npm_linked_packages = npm_linked_packages.transitive,
            transitive_sources = transitive_sources,
        ),
        DefaultInfo(
            files = sources,
            runfiles = runfiles,
        ),
        OutputGroupInfo(
            types = declarations,
        ),
    ]

js_library_lib = struct(
    attrs = _ATTRS,
    implementation = _js_library_impl,
    provides = [DefaultInfo, JsInfo, OutputGroupInfo],
)

js_library = rule(
    doc = _DOC,
    implementation = js_library_lib.implementation,
    attrs = js_library_lib.attrs,
    provides = js_library_lib.provides,
)
