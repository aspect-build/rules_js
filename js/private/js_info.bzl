"JsInfo provider"

JsInfo = provider(
    doc = "Encapsulates information provided by rules in rules_js and derivative rule sets",
    fields = {
        "types": "A depset of typings files produced by the target",
        "npm_sources": "A depset of files in npm package dependencies of the target and the target's transitive deps",
        "npm_package_store_infos": "A depset of NpmPackageStoreInfo providers from non-dev npm dependencies of the target and the target's transitive dependencies to use as direct dependencies when linking downstream npm_package targets with npm_link_package",
        "sources": "A depset of source files produced by the target",
        "transitive_types": "A depset of declaration files produced by the target and the target's transitive deps",
        "transitive_sources": "A depset of source files produced by the target and the target's transitive deps",
    },
)

def js_info(
        types = depset(),
        npm_sources = depset(),
        npm_package_store_infos = depset(),
        sources = depset(),
        transitive_types = depset(),
        transitive_sources = depset()):
    """Construct a JsInfo.

    Args:
        types: See JsInfo documentation
        npm_sources: See JsInfo documentation
        npm_package_store_infos: See JsInfo documentation
        sources: See JsInfo documentation
        transitive_types: See JsInfo documentation
        transitive_sources: See JsInfo documentation

    Returns:
        A JsInfo provider
    """
    if type(types) != "depset":
        fail("Expected types to be a depset")
    if type(npm_sources) != "depset":
        fail("Expected npm_sources to be a depset")
    if type(npm_package_store_infos) != "depset":
        fail("Expected npm_package_store_infos to be a depset")
    if type(sources) != "depset":
        fail("Expected sources to be a depset")
    if type(transitive_types) != "depset":
        fail("Expected transitive_types to be a depset")
    if type(transitive_sources) != "depset":
        fail("Expected transitive_sources to be a depset")

    return JsInfo(
        types = types,
        npm_sources = npm_sources,
        npm_package_store_infos = npm_package_store_infos,
        sources = sources,
        transitive_types = transitive_types,
        transitive_sources = transitive_sources,
    )
