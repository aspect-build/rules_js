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
load("@rules_nodejs//nodejs:providers.bzl", "DeclarationInfo", "declaration_info")

_DOC = """Copies all sources to the output tree and expose some files with DeclarationInfo.

Can be used as a dep for rules that expect a DeclarationInfo such as ts_project."""

_ATTRS = {
    "srcs": attr.label_list(allow_files = True),
    "deps": attr.label_list(allow_files = True),
    "_windows_constraint": attr.label(default = "@platforms//os:windows"),
}

def _js_library_impl(ctx):
    is_windows = ctx.target_platform_has_constraint(ctx.attr._windows_constraint[platform_common.ConstraintValueInfo])

    typings = []

    for file in ctx.files.srcs:
        if ctx.label.package != file.owner.package:
            msg = """

Expected to find file {file_basename} in {this_package}, but instead it is in {file_package}.

All srcs in a js_library must be in the same package as the js_library target.

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

    for src in output_srcs:
        if src.is_directory:
            # assume a directory contains typings since we can't know that it doesn't
            typings.append(src)
        elif (
            src.path.endswith(".d.ts") or
            src.path.endswith(".d.ts.map") or
            # package.json may be required to resolve "typings" key
            src.path.endswith("/package.json")
        ):
            typings.append(src)

    typings_depsets = [depset(typings)]
    files_depsets = [depset(output_srcs)]

    for dep in ctx.attr.deps:
        if DeclarationInfo in dep:
            typings_depsets.append(dep[DeclarationInfo].declarations)
        if DefaultInfo in dep:
            files_depsets.append(dep[DefaultInfo].files)

    runfiles = ctx.runfiles(
        files = output_srcs,
        # We do not include typings_depsets in the runfiles because that would cause type-check actions to occur
        # in every development workflow.
        transitive_files = depset(transitive = files_depsets),
    )
    deps_runfiles = [d[DefaultInfo].default_runfiles for d in ctx.attr.deps]
    decls = depset(transitive = typings_depsets)

    return [
        DefaultInfo(
            files = depset(transitive = files_depsets),
            runfiles = runfiles.merge_all(deps_runfiles),
        ),
        declaration_info(
            declarations = decls,
            deps = ctx.attr.deps,
        ),
        OutputGroupInfo(types = decls),
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
