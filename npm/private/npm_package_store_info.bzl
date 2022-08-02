"NpmPackageStoreInfo provider"

NpmPackageStoreInfo = provider(
    doc = """Provides information about an npm package within the virtual store of a pnpm-style
    symlinked node_modules tree.

    See https://pnpm.io/symlinked-node-modules-structure for more information about
    symlinked node_modules trees.""",
    fields = {
        "root_package": "package that this npm package store is linked at",
        "package": "name of this npm package",
        "version": "version of this npm package",
        "ref_deps": "list of dependency npm_package_store ref targets",
        "virtual_store_directory": "the TreeArtifact of this npm package's virtual store location",
        "files": "list of files that are part of the npm package",
        "transitive_files": "list of the files that are part of the npm package and its transitive deps",
    },
)
