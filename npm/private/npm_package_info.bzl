"NpmPackageInfo provider"

NpmPackageInfo = provider(
    doc = "Provides the sources of an npm package along with the package name and version",
    fields = {
        "package": "name of this npm package",
        "version": "version of this npm package",
        "src": "the sources of this npm package; either a tarball file, a TreeArtifact or a source directory",
        "npm_package_store_infos": "A depset of NpmPackageStoreInfo providers from npm dependencies of the package and the packages's transitive deps to use as direct dependencies when linking with npm_link_package",
    },
)
