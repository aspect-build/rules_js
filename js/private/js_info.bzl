"JsInfo provider"

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
        declarations = declarations,
        npm_linked_packages = npm_linked_packages,
        npm_package_stores = npm_package_stores,
        sources = sources,
        transitive_declarations = transitive_declarations,
        transitive_npm_linked_packages = transitive_npm_linked_packages,
        transitive_npm_package_stores = transitive_npm_package_stores,
        transitive_sources = transitive_sources,
    )
