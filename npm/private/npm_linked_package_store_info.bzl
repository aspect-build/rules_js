"NpmLinkedPackageStoreInfo provider"

NpmLinkedPackageStoreInfo = provider(
    doc = "Provides a linked npm package store",
    fields = {
        "label": "the label of the npm_link_package_store target the created this provider",
        "root_package": "package that this npm package store is linked at",
        "package": "name of this npm package",
        "version": "version of this npm package",
        "ref_deps": "list of dependency ref targets",
        "virtual_store_directory": "the TreeArtifact of this npm package's virtual store location",
        "files": "a depset of the transitive closure of all files required for this linked npm package needs to be used",
    },
)
