"""`js_library` helper functions.
"""

load(":js_binary_helpers.bzl", "gather_files_from_js_providers")
load(":js_info.bzl", "JsInfo")

# This attribute is exposed in //js:libs.bzl so that downstream build rules can use it
JS_LIBRARY_DATA_ATTR = attr.label_list(
    doc = """Runtime dependencies to include in binaries/tests that depend on this target.

    The transitive npm dependencies, transitive sources, default outputs and runfiles of targets in the `data` attribute
    are added to the runfiles of this taregt. Thery should appear in the '*.runfiles' area of any executable which has
    a runtime dependency on this target.

    If this list contains linked npm packages, npm package store targets or other targets that provide `JsInfo`,
    `NpmPackageStoreInfo` providers are gathered from `JsInfo`. This is done directly from `npm_package_stores` and
    `transitive_npm_package_stores` fields of these and for linked npm package targets, from the underlying
    npm_package_store target(s) that back the links via `npm_linked_packages` and `transitive_npm_linked_packages`.

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
        Depset of transitive sources
    """
    if type(sources) == "list":
        sources = depset(sources)
    transitive_deps = [
        target[JsInfo].transitive_sources
        for target in targets
        if JsInfo in target
    ]
    return depset([], transitive = [sources] + transitive_deps)

def gather_transitive_sources_legacy(sources, targets):
    """Gathers transitive sources from a list of direct sources and targets

    Args:
        sources: list or depset of direct sources which should be included in `transitive_sources`
        targets: list of targets to gather `transitive_sources` from `JsInfo`

    Returns:
        List of transitive sources
    """
    return gather_transitive_sources(sources, targets).to_list()

def gather_transitive_declarations(declarations, targets):
    """Gathers transitive sources from a list of direct sources and targets

    Args:
        declarations: list or depset of direct sources which should be included in `transitive_declarations`
        targets: List of targets to gather `transitive_declarations` from `JsInfo`

    Returns:
        Depset of transitive sources
    """
    if type(declarations) == "list":
        declarations = depset(declarations)
    transitive_deps = [
        target[JsInfo].transitive_declarations
        for target in targets
        if JsInfo in target
    ]
    return depset([], transitive = [declarations] + transitive_deps)

def gather_transitive_declarations_legacy(declarations, targets):
    """Gathers transitive sources from a list of direct sources and targets

    Args:
        declarations: list or depset of direct sources which should be included in `transitive_declarations`
        targets: List of targets to gather `transitive_declarations` from `JsInfo`

    Returns:
        List of transitive sources
    """
    return gather_transitive_declarations(declarations, targets).to_list()

def gather_npm_linked_packages(srcs, deps):
    """Gathers npm linked packages from a list of srcs and deps targets

    Args:
        srcs: source targets; these typically come from the `srcs` and/or `data` attributes of a rule
        deps: dep targets; these typically come from the `deps` attribute of a rule

    Returns:
        A `struct(direct, transitive)` of direct and transitive npm linked packages gathered
    """

    # npm_linked_packages
    npm_linked_packages = [
        target[JsInfo].npm_linked_packages
        for target in srcs
        if JsInfo in target
    ]

    # transitive_npm_linked_packages
    transitive_npm_linked_packages = depset([], transitive = npm_linked_packages + [
        target[JsInfo].transitive_npm_linked_packages
        for target in srcs + deps
        if JsInfo in target
    ])

    return struct(
        direct = depset([], transitive = npm_linked_packages),
        transitive = transitive_npm_linked_packages,
    )

def gather_npm_linked_packages_legacy(srcs, deps):
    """Gathers npm linked packages from a list of srcs and deps targets

    Args:
        srcs: source targets; these typically come from the `srcs` and/or `data` attributes of a rule
        deps: dep targets; these typically come from the `deps` attribute of a rule

    Returns:
        A `struct(direct, transitive)` of direct and transitive npm linked packages gathered
    """
    pkgs = gather_npm_linked_packages(srcs, deps)
    return struct(
        direct = pkgs.direct.to_list(),
        transitive = pkgs.transitive.to_list(),
    )

def gather_npm_package_stores(targets):
    """Gathers NpmPackageStoreInfo providers from the list of targets

    Args:
        targets: the list of targets to gather from

    Returns:
        A `struct(direct, transitive)` of direct and transitive npm package stores gathered
    """

    # npm_package_stores
    npm_package_stores = [
        target[JsInfo].npm_package_stores
        for target in targets
        if JsInfo in target
    ]

    # transitive_npm_package_stores
    transitive_npm_package_stores = npm_package_stores + [
        target[JsInfo].transitive_npm_package_stores
        for target in targets
        if JsInfo in target
    ]

    # also pull npm_package_stores from npm_linked_packages and transitive_npm_linked_packages
    for target in targets:
        if JsInfo in target:
            npm_package_stores.append(depset([package.store_info for package in target[JsInfo].npm_linked_packages.to_list()]))
            transitive_npm_package_stores.append(depset([package.store_info for package in target[JsInfo].transitive_npm_linked_packages.to_list()]))

    return struct(
        direct = depset([], transitive = npm_package_stores),
        transitive = depset([], transitive = transitive_npm_package_stores),
    )

def gather_npm_package_stores_legacy(targets):
    """Gathers NpmPackageStoreInfo providers from the list of targets

    Args:
        targets: the list of targets to gather from

    Returns:
        A `struct(direct, transitive)` of direct and transitive npm package stores gathered
    """
    pkgs = gather_npm_package_stores(targets)
    return struct(
        direct = pkgs.direct.to_list(),
        transitive = pkgs.transitive.to_list(),
    )

def gather_runfiles(ctx, sources, data, deps):
    """Gathers runfiles from the list of targets.

    Args:
        ctx: the rule context
        sources: sources which should be included in runfiles
        data: list of data targets; default outputs and transitive runfiles are gather from these targets
        deps: list of dependency targets; only transitive runfiles are gather from these targets

    Returns:
        Runfiles
    """
    runfiles = sources + gather_files_from_js_providers(
        targets = data + deps,
        include_transitive_sources = True,
        include_declarations = False,
        include_npm_linked_packages = True,
    )

    transitive_runfiles = depset(transitive = [
        target[DefaultInfo].files
        for target in data
    ])

    return ctx.runfiles(
        files = runfiles,
        transitive_files = transitive_runfiles,
    ).merge_all([
        target[DefaultInfo].default_runfiles
        for target in data + deps
    ])
