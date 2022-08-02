"""`js_library` helper functions.
"""

load(":js_binary_helpers.bzl", "gather_files_from_js_providers")
load(":js_info.bzl", "JsInfo")

def gather_transitive_sources(sources, targets):
    """Gathers transitive sources from a list of direct sources and targets

    Args:
        sources: direct sources which should be included in 'transitive_sources'
        targets: list of targets to gather 'transitive_sources' from 'JsInfo'

    Returns:
        List of transitive sources
    """
    transitive_sources = sources + [
        item
        for target in targets
        if JsInfo in target and hasattr(target[JsInfo], "transitive_sources")
        for item in target[JsInfo].transitive_sources
    ]
    transitive_sources = [file for file in transitive_sources if file]
    return transitive_sources

def gather_transitive_declarations(declarations, targets):
    """Gathers transitive sources from a list of direct sources and targets

    Args:
        declarations: Direct sources which should be included in 'transitive_declarations'
        targets: List of targets to gather 'transitive_declarations' from 'JsInfo'

    Returns:
        List of transitive sources
    """
    transitive_declarations = declarations + [
        item
        for target in targets
        if JsInfo in target and hasattr(target[JsInfo], "transitive_declarations")
        for item in target[JsInfo].transitive_declarations
    ]
    transitive_declarations = [file for file in transitive_declarations if file]
    return transitive_declarations

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
        item
        for target in srcs
        if JsInfo in target and hasattr(target[JsInfo], "npm_linked_packages")
        for item in target[JsInfo].npm_linked_packages
    ]
    npm_linked_packages = [package for package in npm_linked_packages if package]

    # transitive_npm_linked_packages
    transitive_npm_linked_packages = npm_linked_packages + [
        item
        for target in srcs + deps
        if JsInfo in target and hasattr(target[JsInfo], "transitive_npm_linked_packages")
        for item in target[JsInfo].transitive_npm_linked_packages
    ]
    transitive_npm_linked_packages = [package for package in transitive_npm_linked_packages if package]

    return struct(
        direct = npm_linked_packages,
        transitive = transitive_npm_linked_packages,
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
        item
        for target in targets
        if JsInfo in target and hasattr(target[JsInfo], "npm_package_stores")
        for item in target[JsInfo].npm_package_stores
    ]
    npm_package_stores = [store for store in npm_package_stores if store]

    # transitive_npm_package_stores
    transitive_npm_package_stores = npm_package_stores + [
        item
        for target in targets
        if JsInfo in target and hasattr(target[JsInfo], "transitive_npm_package_stores")
        for item in target[JsInfo].transitive_npm_package_stores
    ]
    transitive_npm_package_stores = [store for store in transitive_npm_package_stores if store]

    # also pull npm_package_stores from npm_linked_packages and transitive_npm_linked_packages
    for target in targets:
        if JsInfo in target:
            if hasattr(target[JsInfo], "npm_linked_packages"):
                for package in target[JsInfo].npm_linked_packages:
                    if package.store_info and package.store_info not in npm_package_stores:
                        npm_package_stores.append(package.store_info)
            if hasattr(target[JsInfo], "transitive_npm_linked_packages"):
                for package in target[JsInfo].transitive_npm_linked_packages:
                    if package.store_info and package.store_info not in transitive_npm_package_stores:
                        transitive_npm_package_stores.append(package.store_info)

    return struct(
        direct = npm_package_stores,
        transitive = transitive_npm_package_stores,
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
