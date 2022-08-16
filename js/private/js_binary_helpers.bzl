"""`js_binary` helper functions.
"""

load(":js_info.bzl", "JsInfo")
load("//npm:providers.bzl", "NpmPackageStoreInfo")

LOG_LEVELS = {
    "fatal": 1,
    "error": 2,
    "warn": 3,
    "info": 4,
    "debug": 5,
}

def envs_for_log_level(log_level):
    """Returns a list environment variables to set for a given log level

    Args:
        log_level: The log level string value

    Returns:
        A list of environment variables to set to turn on the js_binary runtime
        logs for the given log level. Typically, they are each set to "1".
    """
    if log_level not in LOG_LEVELS.keys():
        fail("log_level must be one of {} but got {}".format(LOG_LEVELS.keys(), log_level))
    envs = []
    log_level_numeric = LOG_LEVELS[log_level]
    if log_level_numeric >= LOG_LEVELS["fatal"]:
        envs.append("JS_BINARY__LOG_FATAL")
    if log_level_numeric >= LOG_LEVELS["error"]:
        envs.append("JS_BINARY__LOG_ERROR")
    if log_level_numeric >= LOG_LEVELS["warn"]:
        envs.append("JS_BINARY__LOG_WARN")
    if log_level_numeric >= LOG_LEVELS["info"]:
        envs.append("JS_BINARY__LOG_INFO")
    if log_level_numeric >= LOG_LEVELS["debug"]:
        envs.append("JS_BINARY__LOG_DEBUG")
    return envs

def gather_files_from_js_providers(
        targets,
        include_transitive_sources,
        include_declarations,
        include_npm_linked_packages):
    """Gathers a list of files from JsInfo and NpmPackageStoreInfo providers.

    Args:
        targets: list of target to gather from
        include_transitive_sources: see js_filegroup documentation
        include_declarations: see js_filegroup documentation
        include_npm_linked_packages: see js_filegroup documentation

    Returns:
        A list of files
    """
    files_depsets = [
        target[JsInfo].sources
        for target in targets
        if JsInfo in target
    ]
    if include_transitive_sources:
        files_depsets.extend([
            target[JsInfo].transitive_sources
            for target in targets
            if JsInfo in target
        ])
    if include_declarations:
        files_depsets.extend([
            target[JsInfo].transitive_declarations
            for target in targets
            if JsInfo in target
        ])
    if include_npm_linked_packages:
        files_depsets.extend([
            package.transitive_files
            for target in targets
            if JsInfo in target
            for package in target[JsInfo].transitive_npm_linked_packages.to_list()
        ])
        files_depsets.extend([
            target[NpmPackageStoreInfo].transitive_files
            for target in targets
            if NpmPackageStoreInfo in target
        ])
    return depset([], transitive = files_depsets).to_list()