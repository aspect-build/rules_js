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
    """Gathers a list of depsets from JsInfo and NpmPackageStoreInfo providers.

    Args:
        targets: list of target to gather from
        include_transitive_sources: see js_filegroup documentation
        include_declarations: see js_filegroup documentation
        include_npm_linked_packages: see js_filegroup documentation

    Returns:
        A list of files
    """
    files = [
        item
        for target in targets
        if JsInfo in target and hasattr(target[JsInfo], "sources")
        for item in target[JsInfo].sources
    ]
    if include_transitive_sources:
        files.extend([
            item
            for target in targets
            if JsInfo in target and hasattr(target[JsInfo], "transitive_sources")
            for item in target[JsInfo].transitive_sources
        ])
    if include_declarations:
        files.extend([
            item
            for target in targets
            if JsInfo in target and hasattr(target[JsInfo], "declarations")
            for item in target[JsInfo].declarations
        ])
        files.extend([
            item
            for target in targets
            if JsInfo in target and hasattr(target[JsInfo], "transitive_declarations")
            for item in target[JsInfo].transitive_declarations
        ])
    if include_npm_linked_packages:
        for target in targets:
            if JsInfo in target:
                if hasattr(target[JsInfo], "npm_linked_packages"):
                    for package in target[JsInfo].npm_linked_packages:
                        files.extend(package.transitive_files)
                if hasattr(target[JsInfo], "transitive_npm_linked_packages"):
                    for package in target[JsInfo].transitive_npm_linked_packages:
                        files.extend(package.transitive_files)
        files.extend([
            item
            for target in targets
            if NpmPackageStoreInfo in target
            for item in target[NpmPackageStoreInfo].transitive_files
        ])
    return files
