"JsInfo provider"

JsInfo = provider(
    doc = "Encapsulates information provided by rules in rules_js and derivative rule sets",
    fields = {
        "declarations": "A depset of declaration files produced by the target",
        "npm_linked_packages": "A depset of NpmLinkedPackageInfo providers that are dependencies of this target",
        "npm_package_stores": "A depset of NpmPackageStoreInfo providers from npm dependencies of this target to use as direct dependencies when linking downstream npm_package targets with npm_link_package",
        "sources": "A depset of source files produced by the target",
        "transitive_declarations": "A depset of declaration files produced by the target and the target's transitive deps",
        "transitive_npm_linked_packages": "A depset of NpmLinkedPackageInfo providers that are dependencies of this target and the target's transitive deps",
        "transitive_npm_package_stores": "A depset of NpmPackageStoreInfo providers from npm dependencies of this target and the target's transitive dependencies to use as direct dependencies when linking downstream npm_package targets with npm_link_package",
        "transitive_sources": "A depset of source files produced by the target and the target's transitive deps",
    },
)

def js_info(
        declarations = None,
        npm_linked_packages = None,
        npm_package_stores = None,
        sources = None,
        transitive_declarations = None,
        transitive_npm_linked_packages = None,
        transitive_npm_package_stores = None,
        transitive_sources = None):
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
    # These are for legacy-users of js_info, who might pass in lists instead of depsets.
    if type(declarations) == "list":
      declarations = depset(declarations)
    if type(npm_linked_packages) == "list":
      npm_linked_packages = depset(npm_linked_packages)
    if type(npm_package_stores) == "list":
      npm_package_stores = depset(npm_package_stores)
    if type(sources) == "list":
      sources = depset(sources)
    if type(transitive_declarations) == "list":
      transitive_declarations = depset(transitive_declarations)
    if type(transitive_npm_linked_packages) == "list":
      transitive_npm_linked_packages = depset(transitive_npm_linked_packages)
    if type(transitive_npm_package_stores) == "list":
      transitive_npm_package_stores = depset(transitive_npm_package_stores)
    if type(transitive_sources) == "list":
      transitive_sources = depset(transitive_sources)

    return JsInfo(
        declarations = declarations or depset(),
        npm_linked_packages = npm_linked_packages or depset(),
        npm_package_stores = npm_package_stores or depset(),
        sources = sources or depset(),
        transitive_declarations = transitive_declarations or depset(),
        transitive_npm_linked_packages = transitive_npm_linked_packages or depset(),
        transitive_npm_package_stores = transitive_npm_package_stores or depset(),
        transitive_sources = transitive_sources or depset(),
    )
