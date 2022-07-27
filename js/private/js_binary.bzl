"""Rules for running JavaScript programs under Bazel, as tools or with `bazel run` or `bazel test`.

For example, this binary references the `acorn` npm package which was already linked
using an API like `npm_link_all_packages`.

```starlark
load("@aspect_rules_js//js:defs.bzl", "js_binary", "js_test")

js_binary(
    name = "bin",
    # Reference the location where the acorn npm module was linked in the root Bazel package
    data = ["//:node_modules/acorn"],
    entry_point = "require_acorn.js",
)
```
"""

load("@aspect_bazel_lib//lib:paths.bzl", "BASH_RLOCATION_FUNCTION")
load("@aspect_bazel_lib//lib:windows_utils.bzl", "create_windows_native_launcher_script")
load("@aspect_bazel_lib//lib:expand_make_vars.bzl", "expand_locations", "expand_variables")
load("@aspect_bazel_lib//lib:directory_path.bzl", "DirectoryPathInfo")
load(":js_binary_helpers.bzl", "LOG_LEVELS", "envs_for_log_level", "gather_files_from_js_providers")

_DOC = """Execute a program in the node.js runtime.

The version of node is determined by Bazel's toolchain selection. In the WORKSPACE you used
`nodejs_register_toolchains` to provide options to Bazel. Then Bazel selects from these options
based on the requested target platform. Use the
[`--toolchain_resolution_debug`](https://docs.bazel.build/versions/main/command-line-reference.html#flag--toolchain_resolution_debug)
Bazel option to see more detail about the selection.

This rules requires that Bazel was run with
[`--enable_runfiles`](https://docs.bazel.build/versions/main/command-line-reference.html#flag--enable_runfiles). 
"""

_ATTRS = {
    "chdir": attr.string(
        doc = """Working directory to run the binary or test in, relative to the workspace.

        By default, `js_binary` runs in the root of the output tree.

        To run in the directory containing the `js_binary` use

            chdir = package_name()

        (or if you're in a macro, use `native.package_name()`)

        WARNING: this will affect other paths passed to the program, either as arguments or in configuration files,
        which are workspace-relative.

        You may need `../../` segments to re-relativize such paths to the new working directory.
        In a `BUILD` file you could do something like this to point to the output path:

        ```python
        js_binary(
            ...
            chdir = package_name(),
            # ../.. segments to re-relative paths from the chdir back to workspace;
            # add an additional 3 segments to account for running js_binary running
            # in the root of the output tree
            args = ["/".join([".."] * len(package_name().split("/")) + "$(rootpath //path/to/some:file)"],
        )
        ```""",
    ),
    "data": attr.label_list(
        allow_files = True,
        doc = """Runtime dependencies of the program.

        The transitive closure of the `data` dependencies will be available in
        the .runfiles folder for this binary/test.

        You can use the `@bazel/runfiles` npm library to access these files
        at runtime.

        npm packages are also linked into the `.runfiles/node_modules` folder
        so they may be resolved directly from runfiles.
        """,
    ),
    "entry_point": attr.label(
        allow_files = True,
        doc = """The main script which is evaluated by node.js.

        This is the module referenced by the `require.main` property in the runtime.

        This must be a target that provides a single file or a `DirectoryPathInfo`
        from `@aspect_bazel_lib//lib::directory_path.bzl`.
        
        See https://github.com/aspect-build/bazel-lib/blob/main/docs/directory_path.md
        for more info on creating a target that provides a `DirectoryPathInfo`.
        """,
        mandatory = True,
    ),
    "enable_runfiles": attr.bool(
        mandatory = True,
        doc = """Whether runfiles are enabled in the current build configuration.

        Typical usage of this rule is via a macro which automatically sets this
        attribute based on a `config_setting` rule.
        """,
    ),
    "env": attr.string_dict(
        doc = """Environment variables of the action.

        Subject to `$(location)` and make variable expansion.""",
    ),
    "node_options": attr.string_list(
        doc = """Options to pass to the node.

        https://nodejs.org/api/cli.html
        """,
    ),
    "expected_exit_code": attr.int(
        doc = """The expected exit code.

        Can be used to write tests that are expected to fail.""",
        default = 0,
    ),
    "log_level": attr.string(
        doc = """Set the logging level.

        Log from are written to stderr. They will be supressed on success when running as the tool
        of a js_run_binary when silent_on_success is True. In that case, they will be shown
        only on a build failure along with the stdout & stderr of the node tool being run.""",
        values = LOG_LEVELS.keys(),
        default = "error",
    ),
    "patch_node_fs": attr.bool(
        doc = """Patch the to Node.js `fs` API (https://nodejs.org/api/fs.html) for this node program
        to prevent the program from following symlinks out of the execroot, runfiles and the sandbox.

        When enabled, `js_binary` patches the Node.js sync and async `fs` API functions `lstat`,
        `readlink`, `realpath`, `readdir` and `opendir` so that the node program being
        run cannot resolve symlinks out of the execroot and the runfiles tree. When in the sandbox,
        these patches prevent the program being run from resolving symlinks out of the sandbox.

        When disabled, node programs can leave the execroot, runfiles and sandbox by following symlinks
        which can lead to non-hermetic behavior.""",
        default = True,
    ),
    "include_transitive_sources": attr.bool(
        doc = """When True, 'transitive_sources' from 'JsInfo' providers in data targets are included in the runfiles of the target.""",
        default = True,
    ),
    "include_declarations": attr.bool(
        doc = """When True, 'declarations' and 'transitive_declarations' from 'JsInfo' providers in data targets are included in the runfiles of the target.

        Defaults to false since declarations are generally not needed at runtime and introducing them could slow down developer round trip
        time due to having to generate typings on source file changes.""",
        default = False,
    ),
    "include_npm_linked_packages": attr.bool(
        doc = """When True, files in 'npm_linked_packages' and 'transitive_npm_linked_packages' from 'JsInfo' providers in data targets are included in the runfiles of the target.

        'transitive_files' from 'NpmPackageStoreInfo' providers in data targets are also included in the runfiles of the target.
        """,
        default = True,
    ),
    "_launcher_template": attr.label(
        default = Label("//js/private:js_binary.sh.tpl"),
        allow_single_file = True,
    ),
    "_node_wrapper_sh": attr.label(
        default = Label("//js/private:node_wrapper.sh"),
        allow_single_file = True,
    ),
    "_node_wrapper_bat": attr.label(
        default = Label("//js/private:node_wrapper.bat"),
        allow_single_file = True,
    ),
    "_runfiles_lib": attr.label(default = "@bazel_tools//tools/bash/runfiles"),
    "_windows_constraint": attr.label(default = "@platforms//os:windows"),
    "_node_patches_files": attr.label_list(
        allow_files = True,
        default = ["@aspect_rules_js//js/private/node-patches:fs.js"],
    ),
    "_node_patches": attr.label(
        allow_single_file = True,
        default = "@aspect_rules_js//js/private/node-patches:register.js",
    ),
}

_ENV_SET = """export {var}=\"{value}\""""
_ENV_SET_IFF_NOT_SET = """if [[ -z "${{{var}:-}}" ]]; then export {var}=\"{value}\"; fi"""
_NODE_OPTION = """NODE_OPTIONS+=(\"{value}\")"""

# Do the opposite of _to_manifest_path in
# https://github.com/bazelbuild/rules_nodejs/blob/8b5d27400db51e7027fe95ae413eeabea4856f8e/nodejs/toolchain.bzl#L50
# to get back to the short_path.
# TODO: fix toolchain so we don't have to do this
def _target_tool_short_path(path):
    return ("../" + path[len("external/"):]) if path.startswith("external/") else path

def _bash_launcher(ctx, entry_point_path, log_prefix_rule_set, log_prefix_rule, fixed_args, is_windows):
    envs = []
    for (key, value) in ctx.attr.env.items():
        envs.append(_ENV_SET.format(
            var = key,
            value = " ".join([expand_variables(ctx, exp, attribute_name = "env") for exp in expand_locations(ctx, value, ctx.attr.data).split(" ")]),
        ))

    # Automatically add common and useful make variables to the environment
    builtin_envs = {
        "JS_BINARY__BINDIR": "$(BINDIR)",
        "JS_BINARY__BUILD_FILE_PATH": "$(BUILD_FILE_PATH)",
        "JS_BINARY__COMPILATION_MODE": "$(COMPILATION_MODE)",
        "JS_BINARY__TARGET_CPU": "$(TARGET_CPU)",
        "JS_BINARY__TARGET": "$(TARGET)",
        "JS_BINARY__WORKSPACE": "$(WORKSPACE)",
    }
    for (key, value) in builtin_envs.items():
        envs.append(_ENV_SET.format(
            var = key,
            value = " ".join([expand_variables(ctx, exp, attribute_name = "env") for exp in expand_locations(ctx, value, ctx.attr.data).split(" ")]),
        ))

    if ctx.attr.patch_node_fs:
        # Set patch node fs API env if not already set to allow js_run_binary to override
        envs.append(_ENV_SET_IFF_NOT_SET.format(var = "JS_BINARY__PATCH_NODE_FS", value = "1"))

    if ctx.attr.expected_exit_code:
        envs.append(_ENV_SET.format(
            var = "JS_BINARY__EXPECTED_EXIT_CODE",
            value = str(ctx.attr.expected_exit_code),
        ))

    if ctx.attr.chdir:
        # Set chdir env if not already set to allow js_run_binary to override
        envs.append(_ENV_SET_IFF_NOT_SET.format(
            var = "JS_BINARY__CHDIR",
            value = " ".join([expand_variables(ctx, exp, attribute_name = "env") for exp in expand_locations(ctx, ctx.attr.chdir, ctx.attr.data).split(" ")]),
        ))

    # Set log envs iff not already set to allow js_run_binary to override
    for env in envs_for_log_level(ctx.attr.log_level):
        envs.append(_ENV_SET_IFF_NOT_SET.format(var = env, value = "1"))

    node_options = []
    for node_option in ctx.attr.node_options:
        node_options.append(_NODE_OPTION.format(
            value = " ".join([expand_variables(ctx, exp, attribute_name = "env") for exp in expand_locations(ctx, node_option, ctx.attr.data).split(" ")]),
        ))

    fixed_args_expanded = [expand_variables(ctx, fixed_arg, attribute_name = "fixed_args") for fixed_arg in fixed_args]

    if is_windows:
        node_wrapper = ctx.actions.declare_file("%s_node_wrapper/node.bat" % ctx.label.name)
        ctx.actions.expand_template(
            template = ctx.file._node_wrapper_bat,
            output = node_wrapper,
            substitutions = {},
            is_executable = True,
        )
    else:
        node_wrapper = ctx.actions.declare_file("%s_node_wrapper/node" % ctx.label.name)
        ctx.actions.expand_template(
            template = ctx.file._node_wrapper_sh,
            output = node_wrapper,
            substitutions = {},
            is_executable = True,
        )

    launcher_subst = {
        "{{entry_point_path}}": entry_point_path,
        "{{envs}}": "\n".join(envs),
        "{{fixed_args}}": " ".join(fixed_args_expanded),
        "{{log_prefix_rule_set}}": log_prefix_rule_set,
        "{{log_prefix_rule}}": log_prefix_rule,
        "{{node_options}}": "\n".join(node_options),
        "{{node_patches}}": ctx.file._node_patches.short_path,
        "{{node_wrapper}}": node_wrapper.short_path,
        "{{node}}": _target_tool_short_path(ctx.toolchains["@rules_nodejs//nodejs:toolchain_type"].nodeinfo.target_tool_path),
        "{{rlocation_function}}": BASH_RLOCATION_FUNCTION,
        "{{workspace_name}}": ctx.workspace_name,
    }

    launcher = ctx.actions.declare_file("%s.sh" % ctx.label.name)
    ctx.actions.expand_template(
        template = ctx.file._launcher_template,
        output = launcher,
        substitutions = launcher_subst,
        is_executable = True,
    )

    return launcher, node_wrapper

def _create_launcher(ctx, log_prefix_rule_set, log_prefix_rule, fixed_args = []):
    is_windows = ctx.target_platform_has_constraint(ctx.attr._windows_constraint[platform_common.ConstraintValueInfo])

    if is_windows and not ctx.attr.enable_runfiles:
        fail("need --enable_runfiles on Windows for to support rules_js")

    if DirectoryPathInfo in ctx.attr.entry_point:
        entry_point = ctx.attr.entry_point[DirectoryPathInfo].directory
        entry_point_path = "/".join([
            ctx.attr.entry_point[DirectoryPathInfo].directory.short_path,
            ctx.attr.entry_point[DirectoryPathInfo].path,
        ])
    else:
        if len(ctx.files.entry_point) != 1:
            fail("entry_point must be a single file or a target that provides a DirectoryPathInfo")
        entry_point = ctx.files.entry_point[0]
        entry_point_path = entry_point.short_path

    bash_launcher, node_wrapper = _bash_launcher(ctx, entry_point_path, log_prefix_rule_set, log_prefix_rule, fixed_args, is_windows)
    launcher = create_windows_native_launcher_script(ctx, bash_launcher) if is_windows else bash_launcher

    files = [
        ctx.file._node_patches,
        entry_point,
        bash_launcher,
        node_wrapper,
    ]
    files.extend(ctx.files.data)
    files.extend(ctx.files._runfiles_lib)
    files.extend(ctx.files._node_patches_files)
    files.extend(ctx.toolchains["@rules_nodejs//nodejs:toolchain_type"].nodeinfo.tool_files)

    files.extend(gather_files_from_js_providers(
        targets = ctx.attr.data,
        include_transitive_sources = ctx.attr.include_transitive_sources,
        include_declarations = ctx.attr.include_declarations,
        include_npm_linked_packages = ctx.attr.include_npm_linked_packages,
    ))

    runfiles = ctx.runfiles(
        files = files,
    ).merge_all([
        target[DefaultInfo].default_runfiles
        for target in ctx.attr.data
    ])

    return struct(
        executable = launcher,
        runfiles = runfiles,
    )

def _impl(ctx):
    launcher = _create_launcher(
        ctx,
        log_prefix_rule_set = "aspect_rules_js",
        log_prefix_rule = "js_test" if ctx.attr.testonly else "js_binary",
    )
    runfiles = launcher.runfiles

    providers = []

    if ctx.attr.testonly and ctx.configuration.coverage_enabled:
        # We have to instruct rule implementers to have this attribute present.
        if not hasattr(ctx.attr, "_lcov_merger"):
            fail("_lcov_merger attribute is missing and coverage was requested")

        # We have to propagate _lcov_merger runfiles since bazel does not treat _lcov_merger as a proper tool.
        # See: https://github.com/bazelbuild/bazel/issues/4033
        runfiles = runfiles.merge(ctx.attr._lcov_merger[DefaultInfo].default_runfiles)
        providers = [
            coverage_common.instrumented_files_info(
                ctx,
                source_attributes = ["data"],
                # TODO: check if there is more extensions
                # TODO: .ts should not be here since we ought to only instrument transpiled files?
                extensions = [
                    "mjs",
                    "mts",
                    "cjs",
                    "cts",
                    "ts",
                    "js",
                    "jsx",
                    "tsx",
                ],
            ),
        ]

    return providers + [
        DefaultInfo(
            executable = launcher.executable,
            runfiles = runfiles,
        ),
    ]

js_binary_lib = struct(
    attrs = _ATTRS,
    create_launcher = _create_launcher,
    implementation = _impl,
    toolchains = [
        # TODO: on Windows this toolchain is never referenced
        "@bazel_tools//tools/sh:toolchain_type",
        "@rules_nodejs//nodejs:toolchain_type",
    ],
)

js_binary = rule(
    doc = _DOC,
    implementation = js_binary_lib.implementation,
    attrs = js_binary_lib.attrs,
    executable = True,
    toolchains = js_binary_lib.toolchains,
)

js_test = rule(
    doc = "Identical to js_binary, but usable under `bazel test`.",
    implementation = js_binary_lib.implementation,
    attrs = dict(js_binary_lib.attrs, **{
        "_lcov_merger": attr.label(
            executable = True,
            default = Label("//js/private/coverage:merger"),
            cfg = "exec",
        ),
    }),
    test = True,
    toolchains = js_binary_lib.toolchains,
)
