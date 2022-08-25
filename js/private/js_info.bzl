"JsInfo provider"

load("@bazel_skylib//lib:sets.bzl", "sets")

JsInfo = provider(
    doc = "Encapsulates information provided by rules in rules_js and derivative rule sets",
    fields = {
        "declarations": "A list of declaration files produced by the target",
        "npm_linked_packages": "A list of NpmLinkedPackageInfo providers that are dependencies of this target",
        "npm_package_stores": "A list of NpmPackageStoreInfo providers from npm dependencies of this target to use as direct dependencies when linking downstream npm_package targets with npm_link_package",
        "sources": "A list of source files produced by the target",
        "transitive_declarations": "A list of declaration files produced by the target and the target's transitive deps",
        "transitive_npm_linked_packages": "A list of NpmLinkedPackageInfo providers that are dependencies of this target and the target's transitive deps",
        "transitive_npm_package_stores": "A list of NpmPackageStoreInfo providers from npm dependencies of this target and the target's transitive dependencies to use as direct dependencies when linking downstream npm_package targets with npm_link_package",
        "transitive_sources": "A list of source files produced by the target and the target's transitive deps",
    },
)

def js_info_complete(js_info_partial):
    """Construct a complete JsInfo from a partial JsInfo

    Args:
        js_info_partial: A partial JsInfo with some but not necessarily all fields populated

    Returns:
        A JsInfo provider
    """
    return JsInfo(
        declarations = getattr(js_info_partial, "declarations", []),
        npm_linked_packages = getattr(js_info_partial, "npm_linked_packages", []),
        npm_package_stores = getattr(js_info_partial, "npm_package_stores", []),
        sources = getattr(js_info_partial, "sources", []),
        transitive_declarations = getattr(js_info_partial, "transitive_declarations", []),
        transitive_npm_linked_packages = getattr(js_info_partial, "transitive_npm_linked_packages", []),
        transitive_npm_package_stores = getattr(js_info_partial, "transitive_npm_package_stores", []),
        transitive_sources = getattr(js_info_partial, "transitive_sources", []),
    )

def js_info(
        declarations = [],
        npm_linked_packages = [],
        npm_package_stores = [],
        sources = [],
        transitive_declarations = [],
        transitive_npm_linked_packages = [],
        transitive_npm_package_stores = [],
        transitive_sources = []):
    """Construct a JsInfo

    Lists are passed through depsets to remove duplicates.

    Args:
        declarations: See JsInfo documentation
        npm_linked_packages: See JsInfo documentation
        npm_package_stores: See JsInfo documentation
        sources: See JsInfo documentation
        transitive_declarations: See JsInfo documentation
        transitive_npm_linked_packages: See JsInfo documentation
        transitive_npm_package_stores: See JsInfo documentation
        transitive_sources: See JsInfo documentation

    Returns:
        A JsInfo provider
    """
    return JsInfo(
        # pass lists through depsets to remove duplicates
        declarations = sets.to_list(sets.make(declarations)),
        npm_linked_packages = sets.to_list(sets.make(npm_linked_packages)),
        npm_package_stores = sets.to_list(sets.make(npm_package_stores)),
        sources = sets.to_list(sets.make(sources)),
        transitive_declarations = sets.to_list(sets.make(transitive_declarations)),
        transitive_npm_linked_packages = sets.to_list(sets.make(transitive_npm_linked_packages)),
        transitive_npm_package_stores = sets.to_list(sets.make(transitive_npm_package_stores)),
        transitive_sources = sets.to_list(sets.make(transitive_sources)),
    )
