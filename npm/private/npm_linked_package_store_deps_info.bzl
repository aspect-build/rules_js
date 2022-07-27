"npm providers"

NpmLinkedPackageStoreDepsInfo = provider(
    doc = """Provides a list of linked npm package store dependencies.
    
    These are typically accumulated and re-exported by a downstream NpmPackage target to be used when
    linking that package.
    """,
    fields = {
        "deps": "list of NpmLinkedPackageStoreInfo providers that represent npm dependencies",
    },
)

NPM_LINKED_PACKAGE_STORE_DEPS_ATTRS = {
    "npm_linked_package_deps": attr.label_list(
        doc = """A list of targets that provide NpmLinkedPackageStoreInfo and/or NpmLinkedPackageStoreDepsInfo.

        These can be direct npm links targets from any directly linked npm package such as //:node_modules/foo
        or virtual store npm link targets such as //.aspect_rules_js/node_modules/foo/1.2.3.
        When a direct npm link target is passed, the underlying virtual store npm link target is used.
        They can also be targets from rules that have also npm_linked_package_deps attributes and follow the same
        pattern of re-exporting all NpmLinkedPackageStoreInfo providers found with a NpmLinkedPackageStoreDepsInfo provider.

        The transitive closure of NpmLinkedPackageStoreInfo providers found in this list of targets is
        collected and re-exported by this target with a NpmLinkedPackageStoreDepsInfo provider.
        
        These are typically accumulated and re-exported by a downstream NpmPackage target to be used when
        linking that package.
        """,
        # allow files so that users can blanket pass target to this attribute without worrying about typing
        allow_files = True,
    ),
}
