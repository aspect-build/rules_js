"""`js_library` helper functions.
"""

load("@aspect_bazel_lib//lib:copy_to_bin.bzl", "copy_file_to_bin_action")
load(":js_info.bzl", "JsInfo")

def gather_transitive_sources(sources, targets):
    """Gathers transitive sources from a list of direct sources and targets

    Args:
        sources: list or depset of direct sources which should be included in `transitive_sources`
        targets: list of targets to gather `transitive_sources` from `JsInfo`

    Returns:
        A depset of transitive sources
    """
    if type(sources) == "list":
        sources = depset(sources)
    transitive = [
        target[JsInfo].transitive_sources
        for target in targets
        if JsInfo in target and hasattr(target[JsInfo], "transitive_sources")
    ]
    return depset([], transitive = [sources] + transitive)

def gather_transitive_types(types, targets):
    """Gathers transitive types from a list of direct types and targets

    Args:
        types: list or depset of direct sources which should be included in `transitive_types`
        targets: list of targets to gather `transitive_types` from `JsInfo`

    Returns:
        A depset of transitive sources
    """
    if type(types) == "list":
        types = depset(types)
    transitive = [
        target[JsInfo].transitive_types
        for target in targets
        if JsInfo in target and hasattr(target[JsInfo], "transitive_types")
    ]
    return depset([], transitive = [types] + transitive)

def gather_npm_sources(srcs, deps):
    """Gathers npm sources from a list of srcs and deps targets

    Args:
        srcs: source targets; these typically come from the `srcs` and/or `data` attributes of a rule
        deps: dep targets; these typically come from the `deps` attribute of a rule

    Returns:
        Depset of npm sources
    """

    return depset([], transitive = [
        target[JsInfo].npm_sources
        for target in srcs + deps
        if JsInfo in target and hasattr(target[JsInfo], "npm_sources")
    ])

def gather_npm_package_store_infos(targets):
    """Gathers NpmPackageStoreInfo providers from the list of targets

    Args:
        targets: the list of targets to gather from

    Returns:
        A depset of npm package stores gathered
    """

    # npm_package_store_infos
    npm_package_store_infos = [
        target[JsInfo].npm_package_store_infos
        for target in targets
        if JsInfo in target
    ]

    return depset([], transitive = npm_package_store_infos)

def copy_js_file_to_bin_action(ctx, file):
    if ctx.label.workspace_name != file.owner.workspace_name or ctx.label.package != file.owner.package:
        msg = """

Expected to find source file {file_basename} in '{this_package}', but instead it is in '{file_package}'.

All source and data files that are not in the Bazel output tree must be in the same package as the
target so that they can be copied to the output tree in an action.

See https://docs.aspect.build/rules/aspect_rules_js/docs/#javascript for more context on why this is required.

Either move {file_basename} to '{this_package}', or add a 'js_library'
target in {file_basename}'s package and add that target to the deps of {this_target}:

buildozer 'new_load @aspect_rules_js//js:defs.bzl js_library' {file_package}:__pkg__
buildozer 'new js_library {new_target_name}' {file_package}:__pkg__
buildozer 'add srcs {file_basename}' {file_package}:{new_target_name}
buildozer 'add visibility {this_package}:__pkg__' {file_package}:{new_target_name}
buildozer 'remove srcs {file_package}:{file_basename}' {this_target}
buildozer 'add srcs {file_package}:{new_target_name}' {this_target}

For exceptional cases where copying is not possible or not suitable for an input file such as
a file in an external repository, exceptions can be added to 'no_copy_to_bin'. In most cases,
this option is not needed.

""".format(
            file_basename = file.basename,
            file_package = "%s//%s" % (file.owner.workspace_name, file.owner.package),
            new_target_name = file.basename.replace(".", "_"),
            this_package = "%s//%s" % (ctx.label.workspace_name, ctx.label.package),
            this_target = ctx.label,
        )
        fail(msg)

    return copy_file_to_bin_action(ctx, file)

def gather_runfiles(
        ctx,
        sources,
        data,
        deps,
        data_files = [],
        copy_data_files_to_bin = False,
        no_copy_to_bin = [],
        include_sources = True,
        include_transitive_sources = True,
        include_types = False,
        include_transitive_types = False,
        include_npm_sources = True):
    """Creates a runfiles object containing files in `sources`, default outputs from `data` and transitive runfiles from `data` & `deps`.

    As a defense in depth against `data` & `deps` targets not supplying all required runfiles, also
    gathers the transitive sources & transitive npm sources from the `JsInfo` providers of
    `data` & `deps` targets.

    See https://bazel.build/extending/rules#runfiles for more info on providing runfiles in build rules.

    Args:
        ctx: the rule context

        sources: list or depset of files which should be included in runfiles

        deps: list of dependency targets; only transitive runfiles are gather from these targets

        data: list of data targets; default outputs and transitive runfiles are gather from these targets

            See https://bazel.build/reference/be/common-definitions#typical.data and
            https://bazel.build/concepts/dependencies#data-dependencies for more info and guidance
            on common usage of the `data` attribute in build rules.

        data_files: a list of data files which should be included in runfiles

            Data files that are source files are copied to the Bazel output tree when
            `copy_data_files_to_bin` is set to `True`.

        copy_data_files_to_bin: When True, `data` files that are source files and are copied to the
            Bazel output tree before being passed to returned runfiles.

        no_copy_to_bin: List of files to not copy to the Bazel output tree when `copy_data_to_bin` is True.

            This is useful for exceptional cases where a `copy_data_files_to_bin` is not possible or not suitable for an input
            file such as a file in an external repository. In most cases, this option is not needed.
            See `copy_data_files_to_bin` docstring for more info.

        include_sources: see js_info_files documentation

        include_transitive_sources: see js_info_files documentation

        include_types: see js_info_files documentation

        include_transitive_types: see js_info_files documentation

        include_npm_sources: see js_info_files documentation

    Returns:
        A [runfiles](https://bazel.build/rules/lib/runfiles) object created with [ctx.runfiles](https://bazel.build/rules/lib/ctx#runfiles).
    """

    # Includes sources
    if type(sources) == "list":
        sources = depset(sources)
    transitive_files_depsets = [sources]

    # Gather the default outputs of data targets
    transitive_files_depsets.extend([
        target[DefaultInfo].files
        for target in data
    ])

    # Gather files from JsInfo providers of data & deps
    transitive_files_depsets.append(gather_files_from_js_infos(
        targets = data + deps,
        include_sources = include_sources,
        include_types = include_types,
        include_transitive_sources = include_transitive_sources,
        include_transitive_types = include_transitive_types,
        include_npm_sources = include_npm_sources,
    ))

    files_runfiles = []
    for d in data_files:
        if copy_data_files_to_bin and d.is_source and d not in no_copy_to_bin:
            files_runfiles.append(copy_js_file_to_bin_action(ctx, d))
        else:
            files_runfiles.append(d)

    if len(files_runfiles) > 0:
        transitive_files_depsets.append(depset(files_runfiles))

    # Merge the above with the transitive runfiles of data & deps.
    return ctx.runfiles(
        files = files_runfiles,
        transitive_files = depset(transitive = transitive_files_depsets),
    ).merge_all([
        target[DefaultInfo].default_runfiles
        for target in data + deps
    ])

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
        msg = "log_level must be one of {} but got {}".format(LOG_LEVELS.keys(), log_level)
        fail(msg)
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

def gather_files_from_js_infos(
        targets,
        include_sources,
        include_types,
        include_transitive_sources,
        include_transitive_types,
        include_npm_sources):
    """Gathers files from JsInfo providers.

    Args:
        targets: list of target to gather from
        include_sources: see js_info_files documentation
        include_types: see js_info_files documentation
        include_transitive_sources: see js_info_files documentation
        include_transitive_types: see js_info_files documentation
        include_npm_sources: see js_info_files documentation

    Returns:
        A depset of files
    """
    files_depsets = []
    if include_sources:
        files_depsets = [
            target[JsInfo].sources
            for target in targets
            if JsInfo in target and hasattr(target[JsInfo], "sources")
        ]
    if include_types:
        files_depsets.extend([
            target[JsInfo].types
            for target in targets
            if JsInfo in target and hasattr(target[JsInfo], "types")
        ])
    if include_transitive_sources:
        files_depsets.extend([
            target[JsInfo].transitive_sources
            for target in targets
            if JsInfo in target and hasattr(target[JsInfo], "transitive_sources")
        ])
    if include_transitive_types:
        files_depsets.extend([
            target[JsInfo].transitive_types
            for target in targets
            if JsInfo in target and hasattr(target[JsInfo], "transitive_types")
        ])
    if include_npm_sources:
        files_depsets.extend([
            target[JsInfo].npm_sources
            for target in targets
            if JsInfo in target and hasattr(target[JsInfo], "npm_sources")
        ])
    return depset([], transitive = files_depsets)
