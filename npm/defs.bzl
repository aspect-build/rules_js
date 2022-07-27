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
    "//npm/private:npm_package_info.bzl",
    _NpmPackageInfo = "NpmPackageInfo",
)
load(
    "//npm/private:npm_linked_package_direct_info.bzl",
    _NpmLinkedPackageDirectInfo = "NpmLinkedPackageDirectInfo",
)
load(
    "//npm/private:npm_linked_package_store_info.bzl",
    _NpmLinkedPackageStoreInfo = "NpmLinkedPackageStoreInfo",
)
load(
    "//npm/private:npm_linked_package_store_deps_info.bzl",
    _NPM_LINKED_PACKAGE_STORE_DEPS_ATTRS = "NPM_LINKED_PACKAGE_STORE_DEPS_ATTRS",
    _NpmLinkedPackageStoreDepsInfo = "NpmLinkedPackageStoreDepsInfo",
)

npm_package = _npm_package
npm_link_package = _npm_link_package

# export providers & helpers as public API for use in downstream rules
NpmPackageInfo = _NpmPackageInfo
NpmLinkedPackageDirectInfo = _NpmLinkedPackageDirectInfo
NpmLinkedPackageStoreInfo = _NpmLinkedPackageStoreInfo
NpmLinkedPackageStoreDepsInfo = _NpmLinkedPackageStoreDepsInfo
NPM_LINKED_PACKAGE_STORE_DEPS_ATTRS = _NPM_LINKED_PACKAGE_STORE_DEPS_ATTRS

# export the starlark libraries as a public API for use in downstream rules
npm_package_lib = _npm_package_lib
