"JsInfo provider"

JsInfo = provider(
    doc = "Encapsulates information provided by rules in rules_js and derivative rule sets",
    fields = {
        "target": "The label of target that created this JsInfo",
        "sources": "A depset of source files produced by the target",
        "types": "A depset of typings files produced by the target",
        "transitive_sources": "A depset of source files produced by the target and the target's transitive deps",
        "transitive_types": "A depset of declaration files produced by the target and the target's transitive deps",
        "npm_sources": "A depset of files in npm package dependencies of the target and the target's transitive deps",
        "npm_package_store_infos": "A depset of NpmPackageStoreInfo providers from non-dev npm dependencies of the target and the target's transitive dependencies to use as direct dependencies when linking downstream npm_package targets with npm_link_package",
    },
)

_EMPTY_DEPSET = depset()

def js_info(
        target,
        sources = None,
        types = None,
        transitive_sources = None,
        transitive_types = None,
        npm_sources = None,
        npm_package_store_infos = None,
        **kwargs):
    """Construct a JsInfo.

    Args:
        target: See JsInfo documentation
        sources: See JsInfo documentation
        types: See JsInfo documentation
        transitive_sources: See JsInfo documentation
        transitive_types: See JsInfo documentation
        npm_sources: See JsInfo documentation
        npm_package_store_infos: See JsInfo documentation
        **kwargs: For backward compat support

    Returns:
        A JsInfo provider
    """

    # Handle backward compat for rules_js 1.x js_info factory parameters:
    # - declarations
    declarations = kwargs.pop("declarations", None)
    if declarations != None:
        if types != None:
            fail("Cannot set both types and declarations")

        # buildifier: disable=print
        print("""
WARNING: js_info 'declarations' is deprecated. Use 'types' instead.""")
        types = declarations

    # - transitive_declarations
    transitive_declarations = kwargs.pop("transitive_declarations", None)
    if transitive_declarations != None:
        if transitive_types != None:
            fail("Cannot set both transitive_types and transitive_declarations")

        # buildifier: disable=print
        print("""
WARNING: js_info 'transitive_declarations' is deprecated. Use 'transitive_types' instead.""")
        transitive_types = transitive_declarations

    # - npm_package_store_deps
    npm_package_store_deps = kwargs.pop("npm_package_store_deps", None)
    if npm_package_store_deps != None:
        if npm_package_store_infos != None:
            fail("Cannot set both npm_package_store_infos and npm_package_store_deps")

        # buildifier: disable=print
        print("""
WARNING: js_info 'npm_package_store_deps' is deprecated. Use 'npm_package_store_infos' instead.""")
        npm_package_store_infos = npm_package_store_deps

    # - transitive_npm_linked_package_files
    transitive_npm_linked_package_files = kwargs.pop("transitive_npm_linked_package_files", None)
    if transitive_npm_linked_package_files != None:
        if npm_sources != None:
            fail("Cannot set both npm_sources and transitive_npm_linked_package_files")

        # buildifier: disable=print
        print("""
WARNING: js_info 'transitive_npm_linked_package_files' is deprecated. Use 'npm_sources' instead.""")
        npm_sources = transitive_npm_linked_package_files
    if len(kwargs):
        msg = "Invalid js_info parameter '{}'".format(kwargs.keys()[0])
        fail(msg)

    # Default to depset()

    if type(target) != "Label":
        msg = "Expected target to be a Label but got {}".format(type(target))
        fail(msg)

    if sources == None:
        sources = _EMPTY_DEPSET
    elif type(sources) != "depset":
        msg = "Expected sources to be a depset but got {}".format(type(sources))
        fail(msg)

    if types == None:
        types = _EMPTY_DEPSET
    elif type(types) != "depset":
        msg = "Expected types to be a depset but got {}".format(type(types))
        fail(msg)

    if transitive_sources == None:
        transitive_sources = _EMPTY_DEPSET
    elif type(transitive_sources) != "depset":
        msg = "Expected transitive_sources to be a depset but got {}".format(type(transitive_sources))
        fail(msg)

    if transitive_types == None:
        transitive_types = _EMPTY_DEPSET
    elif type(transitive_types) != "depset":
        msg = "Expected transitive_types to be a depset but got {}".format(type(transitive_types))
        fail(msg)

    if npm_sources == None:
        npm_sources = _EMPTY_DEPSET
    elif type(npm_sources) != "depset":
        msg = "Expected npm_sources to be a depset but got {}".format(type(npm_sources))
        fail(msg)

    if npm_package_store_infos == None:
        npm_package_store_infos = _EMPTY_DEPSET
    elif type(npm_package_store_infos) != "depset":
        msg = "Expected npm_package_store_infos to be a depset but got {}".format(type(npm_package_store_infos))
        fail(msg)

    return JsInfo(
        target = target,
        sources = sources,
        types = types,
        transitive_sources = transitive_sources,
        transitive_types = transitive_types,
        npm_sources = npm_sources,
        npm_package_store_infos = npm_package_store_infos,
    )
