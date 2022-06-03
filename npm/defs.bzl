"""Rules for fetching and linking npm dependencies and packaging and linking first-party deps
"""

load(
    "//npm/private:npm_package.bzl",
    _NpmPackageInfo = "NpmPackageInfo",
    _npm_package = "npm_package",
    _npm_package_lib = "npm_package_lib",
)
load(
    "//npm/private:link_npm_package.bzl",
    _link_npm_package = "link_npm_package",
    _link_npm_package_dep = "link_npm_package_dep",
)
load("//npm/private:utils.bzl", _utils = "utils")

npm_package = _npm_package
NpmPackageInfo = _NpmPackageInfo

link_npm_package = _link_npm_package
link_npm_package_dep = _link_npm_package_dep

# export the starlark libraries as a public API
npm_package_lib = _npm_package_lib

# export constants since users might not always have syntax sugar
constants = struct(
    # Prefix for link_npm_package_direct links
    direct_link_prefix = _utils.direct_link_prefix,
    # Prefix for link_npm_package_store links
    store_link_prefix = _utils.store_link_prefix,
    # Suffix for package directory filegroup and alias targets
    dir_suffix = _utils.dir_suffix,
)

# export utils since users might not always have syntax sugar
utils = struct(
    # Prefix for link_npm_package_direct links
    bazel_name = _utils.bazel_name,
)
