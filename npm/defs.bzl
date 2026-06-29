"""Rules for fetching and linking npm dependencies and packaging and linking first-party deps
"""

load("@aspect_tools_telemetry_report//:defs.bzl", "TELEMETRY")  # buildifier: disable=load
load(
    "//npm/private:npm_link_package.bzl",
    _npm_link_package = "npm_link_package",
)
load(
    "//npm/private:npm_package.bzl",
    _npm_package = "npm_package",
    _stamped_package_json = "stamped_package_json",
)
load(
    "//npm/private:pnpm_extract_catalogs.bzl",
    _pnpm_extract_catalogs = "pnpm_extract_catalogs",
)
load(
    "//npm/private:pnpm_package.bzl",
    _pnpm_package = "pnpm_package",
)
npm_package = _npm_package
npm_link_package = _npm_link_package
pnpm_extract_catalogs = _pnpm_extract_catalogs
pnpm_package = _pnpm_package
stamped_package_json = _stamped_package_json
