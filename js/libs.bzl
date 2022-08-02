"""Starlark libraries for building derivative rules"""

load(
    "//js/private:js_binary.bzl",
    _js_binary_lib = "js_binary_lib",
)
load(
    "//js/private:js_library.bzl",
    _js_library_lib = "js_library_lib",
)
load(
    "//js/private:js_binary_helpers.bzl",
    _LOG_LEVELS = "LOG_LEVELS",
    _envs_for_log_level = "envs_for_log_level",
    _gather_files_from_js_providers = "gather_files_from_js_providers",
)
load(
    "//js/private:js_library_helpers.bzl",
    _gather_npm_linked_packages = "gather_npm_linked_packages",
    _gather_npm_package_stores = "gather_npm_package_stores",
    _gather_runfiles = "gather_runfiles",
    _gather_transitive_declarations = "gather_transitive_declarations",
    _gather_transitive_sources = "gather_transitive_sources",
)

js_binary_lib = _js_binary_lib
js_library_lib = _js_library_lib

js_lib_helpers = struct(
    envs_for_log_level = _envs_for_log_level,
    gather_files_from_js_providers = _gather_files_from_js_providers,
    gather_npm_linked_packages = _gather_npm_linked_packages,
    gather_npm_package_stores = _gather_npm_package_stores,
    gather_runfiles = _gather_runfiles,
    gather_transitive_declarations = _gather_transitive_declarations,
    gather_transitive_sources = _gather_transitive_sources,
)

js_lib_constants = struct(
    LOG_LEVELS = _LOG_LEVELS,
)
