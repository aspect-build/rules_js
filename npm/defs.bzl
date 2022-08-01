"""Rules for fetching and linking npm dependencies and packaging and linking first-party deps
"""

load(
    "//npm/private:npm_package.bzl",
    _npm_package = "npm_package",
    _npm_package_lib = "npm_package_lib",
)
load(
    "//npm/private:npm_link_package.bzl",
    _npm_link_package = "npm_link_package",
)
load(
    "//npm/private:npm_linked_package_info.bzl",
    _NpmLinkedPackageInfo = "NpmLinkedPackageInfo",
)
load(
    "//npm/private:npm_package_info.bzl",
    _NpmPackageInfo = "NpmPackageInfo",
)
load(
    "//npm/private:npm_package_store_info.bzl",
    _NpmPackageStoreInfo = "NpmPackageStoreInfo",
)

# export rules & macros as public API
npm_package = _npm_package
npm_link_package = _npm_link_package

# export providers as public API
NpmPackageInfo = _NpmPackageInfo
NpmPackageStoreInfo = _NpmPackageStoreInfo
NpmLinkedPackageInfo = _NpmLinkedPackageInfo

# export the starlark libraries as a public API
npm_package_lib = _npm_package_lib
