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
    _JS_LIBRARY_DATA_ATTR = "JS_LIBRARY_DATA_ATTR",
    _gather_npm_linked_packages = "gather_npm_linked_packages",
    _gather_npm_package_stores = "gather_npm_package_stores",
    _gather_runfiles = "gather_runfiles",
    _gather_transitive_declarations = "gather_transitive_declarations",
    _gather_transitive_sources = "gather_transitive_sources",
    _gather_npm_linked_packages_legacy = "gather_npm_linked_packages_legacy",
    _gather_npm_package_stores_legacy = "gather_npm_package_stores_legacy",
    _gather_transitive_declarations_legacy = "gather_transitive_declarations_legacy",
    _gather_transitive_sources_legacy = "gather_transitive_sources_legacy",
)

js_binary_lib = _js_binary_lib
js_library_lib = _js_library_lib

# The updated versions of helpers, returning depsets where appropriate.
js_lib_depset_helpers = struct(
    envs_for_log_level = _envs_for_log_level,
    gather_files_from_js_providers = _gather_files_from_js_providers,
    gather_npm_linked_packages = _gather_npm_linked_packages,
    gather_npm_package_stores = _gather_npm_package_stores,
    gather_runfiles = _gather_runfiles,
    gather_transitive_declarations = _gather_transitive_declarations,
    gather_transitive_sources = _gather_transitive_sources,
    JS_LIBRARY_DATA_ATTR = _JS_LIBRARY_DATA_ATTR,
)

js_lib_helpers = struct(
    envs_for_log_level = _envs_for_log_level,
    gather_files_from_js_providers = _gather_files_from_js_providers,
    gather_npm_linked_packages = _gather_npm_linked_packages_legacy,
    gather_npm_package_stores = _gather_npm_package_stores_legacy,
    gather_runfiles = _gather_runfiles,
    gather_transitive_declarations = _gather_transitive_declarations_legacy,
    gather_transitive_sources = _gather_transitive_sources_legacy,
    JS_LIBRARY_DATA_ATTR = _JS_LIBRARY_DATA_ATTR,
)

js_lib_constants = struct(
    LOG_LEVELS = _LOG_LEVELS,
)
