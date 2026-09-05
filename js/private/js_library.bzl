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

load("@bazel_lib//lib:copy_to_bin.bzl", "COPY_FILE_TO_BIN_TOOLCHAINS")
load("//js/private/coverage:extensions.bzl", "COVERAGE_EXTENSIONS")
load(":js_helpers.bzl", "copy_js_data_files", "copy_js_file_to_bin_action", "gather_runfiles")
load(":js_info.bzl", "JsInfo", "js_info")
load(":js_runfiles_groups.bzl", "js_runfiles_groups")
load(":proto.bzl", "js_proto_aspect")

_DOC = """A library of JavaScript sources. Provides JsInfo, the primary provider used in rules_js
and derivative rule sets.

Declaration files are handled separately from sources since they are generally not needed at
runtime and build rules, such as ts_project, are optimal in their build graph if they only depend
on types from `deps` since these they don't need the JavaScript source files from deps to
typecheck.

Linked npm dependences are also handled separately from sources since not all rules require them and it
is optimal for these rules to not depend on them in the build graph.

NB: `js_library` copies all source files to the output tree before providing them in JsInfo. See
https://github.com/aspect-build/rules_js/tree/dbb5af0d2a9a2bb50e4cf4a96dbc582b27567155/docs#javascript
for more context on why we do this."""

_LINKED_NPM_DEPS_DOCSTRING = """If this list contains linked npm packages, npm package store targets or other targets that provide
`JsInfo`, `NpmPackageStoreInfo` providers are gathered from `JsInfo`. This is done directly from
the `npm_package_store_infos` field of these. For linked npm package targets, the underlying
`npm_package_store` target(s) that back the links are used. Gathered `NpmPackageStoreInfo`
providers are propagated to the direct dependencies of downstream linked targets.

NB: Linked npm package targets that are "dev" dependencies do not forward their underlying
`npm_package_store` target(s) through `npm_package_store_infos` and will therefore not be
propagated to the direct dependencies of downstream linked targets. npm packages
that come in from `npm_translate_lock` are considered "dev" dependencies if they are have
`dev: true` set in the pnpm lock file. This should be all packages that are only listed as
"devDependencies" in all `package.json` files within the pnpm workspace. This behavior is
intentional to mimic how `devDependencies` work in published npm packages.
"""

_ATTRS = {
    "srcs": attr.label_list(
        doc = """Source files that are included in this library.

This includes all your checked-in code and any generated source files.

The transitive npm dependencies, transitive sources & runfiles of targets in the `srcs` attribute are added to the
runfiles of this target. They should appear in the '*.runfiles' area of any executable which is output by or has a
runtime dependency on this target.

Source files that are JSON files, declaration files or directory artifacts will be automatically provided as
"types" available to downstream rules for type checking. To explicitly provide source files as "types"
available to downstream rules for type checking that do not match these criteria, move those files to the `types`
attribute instead.
""",
        allow_files = True,
    ),
    "types": attr.label_list(
        doc = """Same as `srcs` except all files are also provided as "types" available to downstream rules for type checking.

For example, a js_library with only `.js` files that are intended to be imported as `.js` files by downstream type checking
rules such as `ts_project` would list those files in `types`:

```
js_library(
    name = "js_lib",
    types = ["index.js"],
)
```
""",
        allow_files = True,
    ),
    "deps": attr.label_list(
        doc = """Dependencies of this target.

This may include other js_library targets or other targets that provide JsInfo

The transitive npm dependencies, transitive sources & runfiles of targets in the `deps` attribute are added to the
runfiles of this target. They should appear in the '*.runfiles' area of any executable which is output by or has a
runtime dependency on this target.

{linked_npm_deps}
""".format(linked_npm_deps = _LINKED_NPM_DEPS_DOCSTRING),
        providers = [JsInfo],
        aspects = [js_proto_aspect],
    ),
    "data": attr.label_list(
        doc = """Runtime dependencies to include in binaries/tests that depend on this target.

The transitive npm dependencies, transitive sources, default outputs and runfiles of targets in the `data` attribute
are added to the runfiles of this target. They should appear in the '*.runfiles' area of any executable which has
a runtime dependency on this target.

{linked_npm_deps}
""".format(
            linked_npm_deps = _LINKED_NPM_DEPS_DOCSTRING,
        ),
        allow_files = True,
    ),
    "no_copy_to_bin": attr.label_list(
        allow_files = True,
        doc = """List of files to not copy to the Bazel output tree when `copy_data_to_bin` is True.

        This is useful for exceptional cases where a `copy_to_bin` is not possible or not suitable for an input
        file such as a file in an external repository. In most cases, this option is not needed.
        See `copy_data_to_bin` docstring for more info.
        """,
    ),
    "copy_data_to_bin": attr.bool(
        doc = """When True, `data` files are copied to the Bazel output tree before being passed as inputs to runfiles.""",
        default = True,
    ),
} | js_runfiles_groups.RULE_ATTRS

def _gather_sources_and_types(ctx, targets, files):
    """Gathers sources and types from a list of targets

    Args:
        ctx: the rule context

        targets: List of targets to gather sources and types from their JsInfo providers.

            These typically come from the `srcs` and/or `data` attributes of a rule

        files: List of files to gather as sources and types.

            These typically come from the `srcs` and/or `data` attributes of a rule

    Returns:
        Sources & declaration files depsets in the sequence (sources, types)
    """
    sources = []
    types = []
    owned_sources = []
    owned_types = []
    foreign_sources = {}
    foreign_types = {}
    jsinfo_owners = {target.label: None for target in targets if JsInfo in target}

    for file in files:
        was_source = file.is_source
        if was_source:
            file = copy_js_file_to_bin_action(ctx, file)

        as_source = False
        as_type = False
        if file.is_directory:
            # assume a directory contains types since we can't know that it doesn't
            as_type = True
            as_source = True
            types.append(file)
            sources.append(file)
        elif (
            file.path.endswith(".d.ts") or
            file.path.endswith(".d.ts.map") or
            file.path.endswith(".d.mts") or
            file.path.endswith(".d.mts.map") or
            file.path.endswith(".d.cts") or
            file.path.endswith(".d.cts.map")
        ):
            as_type = True
            types.append(file)
        elif file.path.endswith(".json"):
            # Any .json can produce types: https://www.typescriptlang.org/tsconfig/#resolveJsonModule
            # package.json may be required to resolve types with the "typings" key
            as_type = True
            as_source = True
            types.append(file)
            sources.append(file)
        else:
            as_source = True
            sources.append(file)

        # Newly copied files, and files this target generated, belong to ctx.label.
        # Forwarded JsInfo outputs keep the dependency's companion ownership.
        if was_source or file.owner == ctx.label:
            if as_source:
                owned_sources.append(file)
            if as_type:
                owned_types.append(file)
        elif file.owner not in jsinfo_owners:
            if as_source:
                _append_owner_files(foreign_sources, file.owner, file)
            if as_type:
                _append_owner_files(foreign_types, file.owner, file)

    # sources as depset
    sources = depset(sources, transitive = [
        target[JsInfo].sources
        for target in targets
        if JsInfo in target
    ])

    # types as depset
    types = depset(types, transitive = [
        target[JsInfo].types
        for target in targets
        if JsInfo in target
    ])

    return (sources, types, owned_sources, owned_types, foreign_sources, foreign_types)

def _append_owner_files(owned, owner, file):
    files = owned.get(owner)
    if files == None:
        files = []
        owned[owner] = files
    files.append(file)

def _fallback_files_entries(owner_files):
    entries = []
    for owner, files in owner_files.items():
        if files:
            entries.append(js_runfiles_groups.fallback_entry(owner, depset(files)))
    return entries

def _js_library_impl(ctx):
    sources, types, owned_srcs_sources, owned_srcs_types, foreign_srcs_sources, foreign_srcs_types = _gather_sources_and_types(
        ctx = ctx,
        targets = ctx.attr.srcs,
        files = ctx.files.srcs,
    )

    additional_sources, additional_types, owned_types_sources, owned_types_types, foreign_types_sources, foreign_types_types = _gather_sources_and_types(
        ctx = ctx,
        targets = ctx.attr.types,
        files = ctx.files.types,
    )

    # Direct sources and types
    sources = depset(transitive = [sources, additional_sources])
    types = depset(transitive = [types, additional_sources, additional_types])
    owned_sources = owned_srcs_sources + owned_types_sources
    owned_types = owned_srcs_types + owned_types_sources + owned_types_types
    foreign_source_entries = _fallback_files_entries(foreign_srcs_sources) + _fallback_files_entries(foreign_types_sources)
    foreign_type_entries = _fallback_files_entries(foreign_srcs_types) + _fallback_files_entries(foreign_types_sources) + _fallback_files_entries(foreign_types_types)

    # Transitive sources and types
    transitive_sources = [sources]
    transitive_types = [types]

    # npm providers
    npm_sources = []
    npm_package_store_infos = []

    # Concat the srcs+types+deps once
    srcs_types_deps = ctx.attr.srcs + ctx.attr.types + ctx.attr.deps

    # Collect transitive sources, types and npm providers from srcs+types+deps
    for target in srcs_types_deps:
        if JsInfo in target:
            jsinfo = target[JsInfo]
            transitive_sources.append(jsinfo.transitive_sources)
            transitive_types.append(jsinfo.transitive_types)
            npm_sources.append(jsinfo.npm_sources)
            npm_package_store_infos.append(jsinfo.npm_package_store_infos)

    # Also add npm_package_store_infos from ctx.attr.data
    for target in ctx.attr.data:
        if JsInfo in target:
            npm_package_store_infos.append(target[JsInfo].npm_package_store_infos)

    transitive_sources = depset(transitive = transitive_sources)
    transitive_types = depset(transitive = transitive_types)
    npm_sources = depset(transitive = npm_sources)
    npm_package_store_infos = depset(transitive = npm_package_store_infos)

    copied_data_files = copy_js_data_files(
        ctx,
        ctx.files.data,
        ctx.attr.copy_data_to_bin,
        ctx.files.no_copy_to_bin,
    )
    runfiles = gather_runfiles(
        ctx = ctx,
        data = ctx.attr.data,
        deps = srcs_types_deps,
        data_files = copied_data_files,
        copy_data_files_to_bin = False,
        no_copy_to_bin = ctx.files.no_copy_to_bin,
    )

    providers = [
        coverage_common.instrumented_files_info(
            ctx,
            dependency_attributes = ["deps"],
            source_attributes = ["srcs"],
            extensions = COVERAGE_EXTENSIONS,
        ),
        js_info(
            target = ctx.label,
            sources = sources,
            types = types,
            transitive_sources = transitive_sources,
            transitive_types = transitive_types,
            npm_sources = npm_sources,
            npm_package_store_infos = npm_package_store_infos,
        ),
        DefaultInfo(
            files = sources,
            runfiles = runfiles,
        ),
        OutputGroupInfo(
            types = types,
            runfiles = runfiles.files,
        ),
    ]

    if js_runfiles_groups.is_enabled(ctx):
        providers.extend(_js_library_groups(
            ctx,
            sources = sources,
            owned_sources = owned_sources,
            owned_types = owned_types,
            foreign_source_entries = foreign_source_entries,
            foreign_type_entries = foreign_type_entries,
            srcs_types_deps = srcs_types_deps,
            copied_data_files = copied_data_files,
        ))

    return providers

def _js_library_groups(ctx, sources, owned_sources, owned_types, foreign_source_entries, foreign_type_entries, srcs_types_deps, copied_data_files):
    own_src = js_runfiles_groups.maybe_files_entry(ctx.label, owned_sources, "first_party", js_runfiles_groups.RANK_EXECUTABLE)
    own_types = js_runfiles_groups.maybe_files_entry(ctx.label, owned_types, "first_party", js_runfiles_groups.RANK_EXECUTABLE)
    src_direct = ([own_src] if own_src else []) + foreign_source_entries
    type_direct = ([own_types] if own_types else []) + foreign_type_entries

    sources_ch = js_runfiles_groups.channel_entries_from_targets(
        ctx.attr.srcs + ctx.attr.types,
        "sources",
        "sources",
        own = src_direct,
    )
    types_ch = js_runfiles_groups.channel_entries_from_targets(
        ctx.attr.srcs + ctx.attr.types,
        "types",
        "types",
        own = type_direct,
    )
    companion = js_runfiles_groups.JsRunfilesGroupsInfo(
        default_files = sources_ch,
        sources = sources_ch,
        types = types_ch,
        transitive_sources = js_runfiles_groups.channel_entries_from_targets(
            srcs_types_deps,
            "transitive_sources",
            "transitive_sources",
            own = src_direct,
        ),
        transitive_types = js_runfiles_groups.channel_entries_from_targets(
            srcs_types_deps,
            "transitive_types",
            "transitive_types",
            own = type_direct,
        ),
        npm_sources = js_runfiles_groups.channel_entries_from_targets(srcs_types_deps, "npm_sources", "npm_sources"),
    )

    own = []
    transitive = []
    data_owned = []
    for i, f in enumerate(copied_data_files):
        original = ctx.files.data[i]
        if original.is_source and ctx.attr.copy_data_to_bin and original not in ctx.files.no_copy_to_bin:
            data_owned.append(f)
    if data_owned:
        own.append(js_runfiles_groups.native_entry(ctx.label, depset(data_owned), "first_party", js_runfiles_groups.RANK_EXECUTABLE))

    empty_channels = struct(source_field = None, type_field = None, npm_field = None)
    for dep in ctx.attr.data:
        d, t = js_runfiles_groups.data_target_runtime(ctx, dep, empty_channels)
        own.extend(d)
        transitive.extend(t)
    for dep in srcs_types_deps:
        d, t = js_runfiles_groups.srcs_deps_runtime(ctx, dep)
        own.extend(d)
        transitive.extend(t)

    _ = sources  # DefaultInfo.files == sources; companion.default_files tracks it.
    return [
        companion,
        js_runfiles_groups.RunfilesGroupInfo(
            entries = js_runfiles_groups.collect(ctx, deps = [], data = [], own = own, transitive = transitive),
            executable_group = None,
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
    toolchains = COPY_FILE_TO_BIN_TOOLCHAINS,
)
