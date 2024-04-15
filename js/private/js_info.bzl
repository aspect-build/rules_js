"JsInfo provider"

JsInfo = provider(
    doc = "Encapsulates information provided by rules in rules_js and derivative rule sets",
    fields = {
        "sources": "A depset of source files produced by the target",
        "types": "A depset of typings files produced by the target",
        "transitive_sources": "A depset of source files produced by the target and the target's transitive deps",
        "transitive_types": "A depset of declaration files produced by the target and the target's transitive deps",
        "npm_sources": "A depset of files in npm package dependencies of the target and the target's transitive deps",
        "npm_package_store_infos": "A depset of NpmPackageStoreInfo providers from non-dev npm dependencies of the target and the target's transitive dependencies to use as direct dependencies when linking downstream npm_package targets with npm_link_package",
    },
)

def js_info(
        sources = depset(),
        types = depset(),
        transitive_sources = depset(),
        transitive_types = depset(),
        npm_sources = depset(),
        npm_package_store_infos = depset()):
    """Construct a JsInfo.

    Args:
        sources: See JsInfo documentation
        types: See JsInfo documentation
        transitive_sources: See JsInfo documentation
        transitive_types: See JsInfo documentation
        npm_sources: See JsInfo documentation
        npm_package_store_infos: See JsInfo documentation

    Returns:
        A JsInfo provider
    """
    if type(sources) != "depset":
        msg = "Expected sources to be a depset but got {}".format(type(sources))
        fail(msg)
    if type(types) != "depset":
        msg = "Expected types to be a depset but got {}".format(type(types))
        fail(msg)
    if type(transitive_sources) != "depset":
        msg = "Expected transitive_sources to be a depset but got {}".format(type(transitive_sources))
        fail(msg)
    if type(transitive_types) != "depset":
        msg = "Expected transitive_types to be a depset but got {}".format(type(transitive_types))
        fail(msg)
    if type(npm_sources) != "depset":
        msg = "Expected npm_sources to be a depset but got {}".format(type(npm_sources))
        fail(msg)
    if type(npm_package_store_infos) != "depset":
        msg = "Expected npm_package_store_infos to be a depset but got {}".format(type(npm_package_store_infos))
        fail(msg)

    return JsInfo(
        sources = sources,
        types = types,
        transitive_sources = transitive_sources,
        transitive_types = transitive_types,
        npm_sources = npm_sources,
        npm_package_store_infos = npm_package_store_infos,
    )
