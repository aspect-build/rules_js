"npm_package_store_internal rule"

load(":npm_package_store.bzl", _npm_package_store_lib = "npm_package_store_lib")
load(":npm_package_store_info.bzl", "NpmPackageStoreInfo")

_INTERNAL_ATTRS_STORE = _npm_package_store_lib.attrs | {
    "key": attr.string(mandatory = True),
    "src": attr.label(
        doc = """A target providing a `NpmPackageInfo` or `JsInfo` containing the package sources.

        Can be left unspecified to allow for npm_link_package "reference" targets. `npm_link_package`
        targets without a `src` are used internally by `npm_import` to create "reference"
        `npm_link_package` targets in order to break circular dependencies between 3rd party npm
        dependencies. This pattern is not recommended outside of `npm_import` as it adds
        complication. Outside our `npm_import` you should structure you `npm_link_package` targets in
        a DAG (without cycles).
        """,
    ),
    "package": attr.string(
        doc = """The package name to link to.
        
        Takes precedence over the package name in the `NpmPackageInfo` src.""",
        mandatory = True,
    ),
    "version": attr.string(
        doc = """The package version to link to.
        
        Takes precedence over the package version in the `NpmPackageInfo` src.""",
        mandatory = True,
    ),
    "shared_links": attr.label_keyed_string_dict(
        doc = """`npm_package_store_links` targets providing the dependency symlinks of every package
        in the transitive closure of a terminal `npm_package_store_internal` target.

        When set, the terminal target does not create those symlinks itself.""",
        providers = [DefaultInfo],
    ),
}

npm_package_store_internal = rule(
    implementation = _npm_package_store_lib.implementation,
    attrs = _INTERNAL_ATTRS_STORE,
    provides = _npm_package_store_lib.provides,
    toolchains = _npm_package_store_lib.toolchains,
)

npm_package_store_links = rule(
    doc = """Creates the symlinks from one package's package store entry to its direct dependencies.

    Terminal `npm_package_store_internal` targets with a transitive closure of circular dependencies
    share these instead of each re-creating the symlinks of every package in the closure.""",
    implementation = _npm_package_store_lib.links_implementation,
    attrs = {
        "key": attr.string(mandatory = True),
        "deps": attr.label_keyed_string_dict(
            doc = "Dependency package store targets mapped to the comma separated names to link them as",
            providers = [NpmPackageStoreInfo],
        ),
    },
)
