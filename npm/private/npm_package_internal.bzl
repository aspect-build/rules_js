"npm_package_internal rule"

load(":npm_package_info.bzl", "NpmPackageInfo")

_ATTRS = {
    "src": attr.label(
        doc = "A source directory or output directory to use for this package.",
        allow_single_file = True,
        mandatory = True,
    ),
    "package": attr.string(
        doc = """The package name.""",
        mandatory = True,
    ),
    "version": attr.string(
        doc = """The package version.""",
        mandatory = True,
    ),
    "license": attr.string(doc = "todo"),
}

def _npm_package_internal_impl(ctx):
    if ctx.file.src.is_source or ctx.file.src.is_directory:
        # pass the source directory or TreeArtifact through
        dst = ctx.file.src
    else:
        fail("Expected src to be a source directory or an output directory")

    return [
        DefaultInfo(
            files = depset([dst]),
        ),
        NpmPackageInfo(
            package = ctx.attr.package,
            version = ctx.attr.version,
            directory = dst,
            npm_package_store_deps = depset(),
            hardlink = True,  # always hardlink downstream
            license = ctx.attr.license,
        ),
    ]

npm_package_internal = rule(
    implementation = _npm_package_internal_impl,
    attrs = _ATTRS,
    provides = [DefaultInfo, NpmPackageInfo],
)
