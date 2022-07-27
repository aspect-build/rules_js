"""`js_library` is similar to [`filegroup`](https://docs.bazel.build/versions/main/be/general.html#filegroup); there are no Bazel actions to run.

It only groups JS files together, and propagates their dependencies, along with a DeclarationInfo so that it can be a dep of ts_project.

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
"""

load("@aspect_bazel_lib//lib:copy_to_bin.bzl", "copy_files_to_bin_actions")
load("@bazel_skylib//lib:dicts.bzl", "dicts")
load("@rules_nodejs//nodejs:providers.bzl", "DeclarationInfo", "declaration_info")
load("//npm:defs.bzl", "NPM_LINKED_PACKAGE_STORE_DEPS_ATTRS")

_DOC = """Copies all sources to the output tree and expose some files with DeclarationInfo.

Can be used as a dep for rules that expect a DeclarationInfo such as ts_project."""

_ATTRS = dicts.add(NPM_LINKED_PACKAGE_STORE_DEPS_ATTRS, {
    "srcs": attr.label_list(
        doc = """The list of source files that are processed to create the target.

        This includes all your checked-in code and any generated source files.
        
        Other js_library targets and npm dependencies belong in `deps`.
        """,
        allow_files = True,
    ),
    "deps": attr.label_list(
        doc = """Direct dependencies of this library. This may include
        other js_library targets as well as npm dependencies.""",
    ),
    "_windows_constraint": attr.label(default = "@platforms//os:windows"),
})

def _js_library_impl(ctx):
    is_windows = ctx.target_platform_has_constraint(ctx.attr._windows_constraint[platform_common.ConstraintValueInfo])

    for file in ctx.files.srcs:
        if file.is_source and ctx.label.package != file.owner.package:
            msg = """

Expected to find source file {file_basename} in {this_package}, but instead it is in {file_package}.

All source files in srcs in a js_library must be in the same package as the js_library target.

Either move {file_basename} to {this_package}, or create a js_library
target in {file_basename}'s package and add that target to the deps of {this_target}:

    buildozer 'new_load @aspect_rules_js//js:defs.bzl js_library' {file_package}:__pkg__
    buildozer 'new js_library {new_target_name}' {file_package}:__pkg__
    buildozer 'add srcs {file_basename}' {file_package}:{new_target_name}
    buildozer 'add visibility {this_package}:__pkg__' {file_package}:{new_target_name}
    buildozer 'remove srcs {file_package}:{file_basename}' {this_target}
    buildozer 'add deps {file_package}:{new_target_name}' {this_target}

""".format(
                file_basename = file.basename,
                file_package = "%s//%s" % (file.owner.workspace_name, file.owner.package),
                new_target_name = file.basename.replace(".", "_"),
                this_package = "%s//%s" % (ctx.label.workspace_name, ctx.label.package),
                this_target = ctx.label,
            )
            fail(msg)

    output_srcs = copy_files_to_bin_actions(ctx, ctx.files.srcs, is_windows = is_windows)
    output_deps = copy_files_to_bin_actions(ctx, ctx.files.deps, is_windows = is_windows)

    output_files_depsets = [depset(output_srcs), depset(output_deps)]

    # Gather direct typings in srcs to add to the provided DeclarationInfo
    direct_typings = []
    for src in output_srcs:
        if src.is_directory:
            # assume a directory contains typings since we can't know that it doesn't
            direct_typings.append(src)
        elif (
            src.path.endswith(".d.ts") or
            src.path.endswith(".d.ts.map") or
            # package.json may be required to resolve "typings" key
            src.path.endswith("/package.json")
        ):
            direct_typings.append(src)

    runfiles = ctx.runfiles(
        transitive_files = depset(transitive = output_files_depsets),
    ).merge_all(
        [d[DefaultInfo].default_runfiles for d in ctx.attr.deps],
    )

    return [
        DefaultInfo(
            files = depset(transitive = output_files_depsets),
            runfiles = runfiles,
        ),
        declaration_info(
            declarations = depset(direct_typings),
            deps = ctx.attr.deps,
        ),
        OutputGroupInfo(types = direct_typings),
    ]

js_library_lib = struct(
    attrs = _ATTRS,
    implementation = _js_library_impl,
    provides = [DefaultInfo, DeclarationInfo],
)

js_library = rule(
    doc = _DOC,
    implementation = js_library_lib.implementation,
    attrs = js_library_lib.attrs,
    provides = js_library_lib.provides,
)
