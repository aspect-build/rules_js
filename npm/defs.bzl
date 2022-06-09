"""Rules for fetching and linking npm dependencies and packaging and linking first-party deps
"""

load(
    "//npm/private:npm_package.bzl",
    _NpmPackageInfo = "NpmPackageInfo",
    _npm_package = "npm_package",
    _npm_package_lib = "npm_package_lib",
)
load(
    "//npm/private:npm_link_package.bzl",
    _npm_link_package = "npm_link_package",
)

npm_package = _npm_package
NpmPackageInfo = _NpmPackageInfo

npm_link_package = _npm_link_package

# export the starlark libraries as a public API
npm_package_lib = _npm_package_lib
