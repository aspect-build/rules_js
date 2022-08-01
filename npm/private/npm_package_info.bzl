"NpmPackageInfo provider"

NpmPackageInfo = provider(
    doc = "Provides the output directory (TreeArtifact) of an npm package containing the packages sources along with the package name and version",
    fields = {
        "label": "the label of the target the created this provider",
        "package": "name of this npm package",
        "version": "version of this npm package",
        "directory": "the output directory (a TreeArtifact) that contains the package sources",
    },
)
