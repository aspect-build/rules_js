"NpmLinkedPackageDirectInfo provider"

NpmLinkedPackageDirectInfo = provider(
    doc = "Provides a direct linked npm package",
    fields = {
        "label": "the label of the npm_link_package_direct target the created this provider",
        "link_package": "package that this npm package is directly linked at",
        "package": "name of this npm package",
        "version": "version of this npm package",
        "direct_files": "a depset of direct files that are part of this npm package",
        "files": "a depset of the transitive closure of all files required for this linked npm package needs to be used",
        "store_info": "the NpmLinkedPackageStoreInfo of the linked npm package store that is backing this direct link",
    },
)
