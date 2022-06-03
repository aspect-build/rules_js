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

npm_package = _npm_package
NpmPackageInfo = _NpmPackageInfo

link_npm_package = _link_npm_package
link_npm_package_dep = _link_npm_package_dep

# export the starlark libraries as a public API
npm_package_lib = _npm_package_lib
