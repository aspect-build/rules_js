"""`js_library` helper functions.
"""

load(":js_binary_helpers.bzl", "gather_files_from_js_providers")
load(":js_info.bzl", "JsInfo")

# This attribute is exposed in //js:libs.bzl so that downstream build rules can use it
JS_LIBRARY_DATA_ATTR = attr.label_list(
    doc = """Runtime dependencies to include in binaries/tests that depend on this target.

    The transitive npm dependencies, transitive sources, default outputs and runfiles of targets in the `data` attribute
    are added to the runfiles of this target. They should appear in the '*.runfiles' area of any executable which has
    a runtime dependency on this target.

    If this list contains linked npm packages, npm package store targets or other targets that provide `JsInfo`,
    `NpmPackageStoreInfo` providers are gathered from `JsInfo`. This is done directly from the
    `npm_package_store_deps` field of these. For linked npm package targets, the underlying npm_package_store
    target(s) that back the links is used.

    Gathered `NpmPackageStoreInfo` providers are used downstream as direct dependencies when linking a downstream
    `npm_package` target with `npm_link_package`.
    """,
    allow_files = True,
)

def gather_transitive_sources(sources, targets):
    """Gathers transitive sources from a list of direct sources and targets

    Args:
        sources: list or depset of direct sources which should be included in `transitive_sources`
        targets: list of targets to gather `transitive_sources` from `JsInfo`

    Returns:
        A depset of transitive sources
    """
    if type(sources) == "list":
        sources = depset(sources)
    transitive = [
        target[JsInfo].transitive_sources
        for target in targets
        if JsInfo in target and hasattr(target[JsInfo], "transitive_sources")
    ]
    return depset([], transitive = [sources] + transitive)

def gather_transitive_declarations(declarations, targets):
    """Gathers transitive sources from a list of direct sources and targets

    Args:
        declarations: list or depset of direct sources which should be included in `transitive_declarations`
        targets: List of targets to gather `transitive_declarations` from `JsInfo`

    Returns:
        A depset of transitive sources
    """
    if type(declarations) == "list":
        declarations = depset(declarations)
    transitive = [
        target[JsInfo].transitive_declarations
        for target in targets
        if JsInfo in target and hasattr(target[JsInfo], "transitive_declarations")
    ]
    return depset([], transitive = [declarations] + transitive)

def gather_npm_linked_packages(srcs, deps):
    """Gathers npm linked packages from a list of srcs and deps targets

    Args:
        srcs: source targets; these typically come from the `srcs` and/or `data` attributes of a rule
        deps: dep targets; these typically come from the `deps` attribute of a rule

    Returns:
        A `struct(direct, direct_files, transitive, transitive_files)` of direct and transitive npm linked packages & underlying files gathered
    """

    # npm_linked_packages
    npm_linked_packages = [
        target[JsInfo].npm_linked_packages
        for target in srcs
        if JsInfo in target and hasattr(target[JsInfo], "npm_linked_packages")
    ]

    # npm_linked_package_files
    npm_linked_package_files = [
        target[JsInfo].npm_linked_package_files
        for target in srcs
        if JsInfo in target and hasattr(target[JsInfo], "npm_linked_package_files")
    ]

    # transitive_npm_linked_packages
    transitive_npm_linked_packages = depset([], transitive = npm_linked_packages + [
        target[JsInfo].transitive_npm_linked_packages
        for target in srcs + deps
        if JsInfo in target and hasattr(target[JsInfo], "transitive_npm_linked_packages")
    ])

    # transitive_npm_linked_package_files
    transitive_npm_linked_package_files = depset([], transitive = npm_linked_package_files + [
        target[JsInfo].transitive_npm_linked_package_files
        for target in srcs + deps
        if JsInfo in target and hasattr(target[JsInfo], "transitive_npm_linked_package_files")
    ])

    return struct(
        direct = depset([], transitive = npm_linked_packages),
        direct_files = depset([], transitive = npm_linked_package_files),
        transitive = transitive_npm_linked_packages,
        transitive_files = transitive_npm_linked_package_files,
    )

def gather_npm_package_store_deps(targets):
    """Gathers NpmPackageStoreInfo providers from the list of targets

    Args:
        targets: the list of targets to gather from

    Returns:
        A depset of npm package stores gathered
    """

    # npm_package_store_deps
    npm_package_store_deps = [
        target[JsInfo].npm_package_store_deps
        for target in targets
        if JsInfo in target
    ]

    return depset([], transitive = npm_package_store_deps)

def gather_runfiles(ctx, sources, data, deps):
    """Creates a runfiles object containing files in `sources`, default outputs from `data` and transitive runfiles from `data` & `deps`.

    As a defense in depth against `data` & `deps` targets not supplying all required runfiles, also
    gathers the transitive sources & transitive npm linked packages from the `JsInfo` &
    `NpmPackageStoreInfo` providers of `data` & `deps` targets.

    See https://bazel.build/extending/rules#runfiles for more info on providing runfiles in build rules.

    Args:
        ctx: the rule context

        sources: list or depset of files which should be included in runfiles

        data: list of data targets; default outputs and transitive runfiles are gather from these targets

            See https://bazel.build/reference/be/common-definitions#typical.data and
            https://bazel.build/concepts/dependencies#data-dependencies for more info and guidance
            on common usage of the `data` attribute in build rules.

        deps: list of dependency targets; only transitive runfiles are gather from these targets

    Returns:
        A [runfiles](https://bazel.build/rules/lib/runfiles) object created with [ctx.runfiles](https://bazel.build/rules/lib/ctx#runfiles).
    """

    # Includes sources
    if type(sources) == "list":
        sources = depset(sources)
    transitive_files_depsets = [sources]

    # Gather the default outputs of data targets
    transitive_files_depsets.extend([
        target[DefaultInfo].files
        for target in data
    ])

    # Gather the transitive sources & transitive npm linked packages from the JsInfo &
    # NpmPackageStoreInfo providers of data & deps targets.
    transitive_files_depsets.append(gather_files_from_js_providers(
        targets = data + deps,
        include_transitive_sources = True,
        include_declarations = False,
        include_npm_linked_packages = True,
    ))

    # Merge the above with the transitive runfiles of data & deps.
    return ctx.runfiles(
        transitive_files = depset(transitive = transitive_files_depsets),
    ).merge_all([
        target[DefaultInfo].default_runfiles
        for target in data + deps
    ])
