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
    "//js/private:js_helpers.bzl",
    _LOG_LEVELS = "LOG_LEVELS",
    _envs_for_log_level = "envs_for_log_level",
    _gather_files_from_js_info = "gather_files_from_js_info",
    _gather_npm_package_store_infos = "gather_npm_package_store_infos",
    _gather_npm_sources = "gather_npm_sources",
    _gather_runfiles = "gather_runfiles",
    _gather_transitive_sources = "gather_transitive_sources",
    _gather_transitive_types = "gather_transitive_types",
)

js_binary_lib = _js_binary_lib
js_library_lib = _js_library_lib

js_lib_helpers = struct(
    envs_for_log_level = _envs_for_log_level,
    gather_files_from_js_info = _gather_files_from_js_info,
    gather_npm_sources = _gather_npm_sources,
    gather_npm_package_store_infos = _gather_npm_package_store_infos,
    gather_runfiles = _gather_runfiles,
    gather_transitive_types = _gather_transitive_types,
    gather_transitive_sources = _gather_transitive_sources,
)

js_lib_constants = struct(
    LOG_LEVELS = _LOG_LEVELS,
)
