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

load("@aspect_bazel_lib//lib:windows_utils.bzl", "create_windows_native_launcher_script")
load("@aspect_bazel_lib//lib:expand_make_vars.bzl", "expand_locations", "expand_variables")
load("@aspect_bazel_lib//lib:directory_path.bzl", "DirectoryPathInfo")
load("@aspect_bazel_lib//lib:copy_to_bin.bzl", "copy_file_to_bin_action", "copy_files_to_bin_actions")
load("@aspect_bazel_lib//lib:utils.bzl", "is_bazel_6_or_greater")
load("@bazel_skylib//lib:dicts.bzl", "dicts")
load(":js_binary_helpers.bzl", "LOG_LEVELS", "envs_for_log_level", "gather_files_from_js_providers")
load(":bash.bzl", "BASH_INITIALIZE_RUNFILES")

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
            args = ["/".join([".."] * len(package_name().split("/"))) + "$(rootpath //path/to/some:file)"],
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
        doc = """Options to pass to the node invocation on the command line.

        https://nodejs.org/api/cli.html

        These options are passed directly to the node invocation on the command line.
        Options passed here will take precendence over options passed via
        the NODE_OPTIONS environment variable. Options passed here are not added
        to the NODE_OPTIONS environment variable so will not be automatically
        picked up by child processes that inherit that enviroment variable.
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
        doc = """When True, `transitive_sources` from `JsInfo` providers in data targets are included in the runfiles of the target.""",
        default = True,
    ),
    "include_declarations": attr.bool(
        doc = """When True, `declarations` and `transitive_declarations` from `JsInfo` providers in data targets are included in the runfiles of the target.

        Defaults to false since declarations are generally not needed at runtime and introducing them could slow down developer round trip
        time due to having to generate typings on source file changes.""",
        default = False,
    ),
    "include_npm_linked_packages": attr.bool(
        doc = """When True, files in `npm_linked_packages` and `transitive_npm_linked_packages` from `JsInfo` providers in data targets are included in the runfiles of the target.

        `transitive_files` from `NpmPackageStoreInfo` providers in data targets are also included in the runfiles of the target.
        """,
        default = True,
    ),
    "preserve_symlinks_main": attr.bool(
        doc = """When True, the --preserve-symlinks-main flag is passed to node.

        This prevents node from following an ESM entry script out of runfiles and the sandbox. This can happen for `.mjs`
        ESM entry points where the fs node patches, which guard the runfiles and sandbox, are not applied.
        See https://github.com/aspect-build/rules_js/issues/362 for more information. Once #362 is resolved,
        the default for this attribute can be set to False.

        This flag was added in Node.js v10.2.0 (released 2018-05-23). If your node toolchain is configured to use a
        Node.js version older than this you'll need to set this attribute to False.

        See https://nodejs.org/api/cli.html#--preserve-symlinks-main for more information.
        """,
        default = True,
    ),
    "copy_data_to_bin": attr.bool(
        doc = """When True, `data` files and the `entry_point` file are copied to the Bazel output tree before being passed
        as inputs to runfiles.

        Defaults to True so that a `js_binary` with the default value is compatible with `js_run_binary` with
        `use_execroot_entry_point` set to True, the default there.

        Setting this to False is more optimal in terms of inputs, but there is a yet unresolved issue of ESM imports
        skirting the node fs patches and escaping the sandbox: https://github.com/aspect-build/rules_js/issues/362.
        This is hit in some popular test runners such as mocha, which use native `import()` statements
        (https://github.com/aspect-build/rules_js/pull/353). When set to False, a program such as mocha that uses ESM
        imports may escape the execroot by following symlinks into the source tree. When set to True, such a program
        would escape the sandbox but will end up in the output tree where `node_modules` and other inputs required
        will be available.
        """,
        default = True,
    ),
    "include_npm": attr.bool(
        doc = """When True, npm is included in the runfiles of the target.

        An npm binary is also added on the PATH so tools can spawn npm processes. This is a bash script
        on Linux and MacOS and a batch script on Windows.
        
        A minimum of rules_nodejs version 5.7.0 is required which contains the Node.js toolchain changes
        to use npm.
        """,
    ),
    "unresolved_symlinks_enabled": attr.bool(
        doc = """Whether unresolved symlinks are enabled in the current build configuration.

        These are enabled with the --experimental_allow_unresolved_symlinks flag.

        Typical usage of this rule is via a macro which automatically sets this
        attribute based on a `config_setting` rule.
        """,
        # TODO(2.0): make this mandatory so that downstream binary rules that inherit these attributes are required to set it
        mandatory = False,
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
    "_npm_wrapper_sh": attr.label(
        default = Label("//js/private:npm_wrapper.sh"),
        allow_single_file = True,
    ),
    "_npm_wrapper_bat": attr.label(
        default = Label("//js/private:npm_wrapper.bat"),
        allow_single_file = True,
    ),
    "_windows_constraint": attr.label(default = "@platforms//os:windows"),
    "_node_patches_legacy_files": attr.label_list(
        allow_files = True,
        default = ["@aspect_rules_js//js/private/node-patches_legacy:fs.js"],
    ),
    "_node_patches_legacy": attr.label(
        allow_single_file = True,
        default = "@aspect_rules_js//js/private/node-patches_legacy:register.js",
    ),
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
_NODE_OPTION = """JS_BINARY__NODE_OPTIONS+=(\"{value}\")"""

# Do the opposite of _to_manifest_path in
# https://github.com/bazelbuild/rules_nodejs/blob/8b5d27400db51e7027fe95ae413eeabea4856f8e/nodejs/toolchain.bzl#L50
# to get back to the short_path.
# TODO: fix toolchain so we don't have to do this
def _target_tool_short_path(workspace_name, path):
    return (workspace_name + "/../" + path[len("external/"):]) if path.startswith("external/") else path

# Generate a consistent label string between Bazel versions.
# TODO: hoist this function to bazel-lib and use from there (as well as the dup in npm/private/utils.bzl)
def _consistent_label_str(workspace_name, label):
    # Starting in Bazel 6, the workspace name is empty for the local workspace and there's no other way to determine it.
    # This behavior differs from Bazel 5 where the local workspace name was fully qualified in str(label).
    workspace_name = "" if label.workspace_name == workspace_name else label.workspace_name
    return "@{}//{}:{}".format(
        workspace_name,
        label.package,
        label.name,
    )

def _bash_launcher(ctx, entry_point_path, log_prefix_rule_set, log_prefix_rule, fixed_args, fixed_env, is_windows, use_legacy_node_patches):
    envs = []
    for (key, value) in dicts.add(fixed_env, ctx.attr.env).items():
        envs.append(_ENV_SET.format(
            var = key,
            value = " ".join([expand_variables(ctx, exp, attribute_name = "env") for exp in expand_locations(ctx, value, ctx.attr.data).split(" ")]),
        ))

    # Automatically add common and useful make variables to the environment
    builtin_envs = {
        "JS_BINARY__BINDIR": "$(BINDIR)",
        "JS_BINARY__BUILD_FILE_PATH": "$(BUILD_FILE_PATH)",
        "JS_BINARY__COMPILATION_MODE": "$(COMPILATION_MODE)",
        "JS_BINARY__PACKAGE": ctx.label.package,
        "JS_BINARY__TARGET_CPU": "$(TARGET_CPU)",
        "JS_BINARY__TARGET_NAME": ctx.label.name,
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

    if ctx.attr.copy_data_to_bin:
        # Set an environment variable to flag that we have copied js_binary data to bin
        envs.append(_ENV_SET.format(var = "JS_BINARY__COPY_DATA_TO_BIN", value = "1"))

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
    if ctx.attr.preserve_symlinks_main and "--preserve-symlinks-main" not in node_options:
        node_options.append(_NODE_OPTION.format(value = "--preserve-symlinks-main"))

    fixed_args_expanded = [expand_variables(ctx, fixed_arg, attribute_name = "fixed_args") for fixed_arg in fixed_args]

    toolchain_files = []
    if is_windows:
        node_wrapper = ctx.actions.declare_file("%s_node_bin/node.bat" % ctx.label.name)
        ctx.actions.expand_template(
            template = ctx.file._node_wrapper_bat,
            output = node_wrapper,
            substitutions = {},
            is_executable = True,
        )
    else:
        node_wrapper = ctx.actions.declare_file("%s_node_bin/node" % ctx.label.name)
        ctx.actions.expand_template(
            template = ctx.file._node_wrapper_sh,
            output = node_wrapper,
            substitutions = {},
            is_executable = True,
        )
    toolchain_files.append(node_wrapper)

    npm_path = ""
    if ctx.attr.include_npm:
        npm_path = _target_tool_short_path(ctx.workspace_name, ctx.toolchains["@rules_nodejs//nodejs:toolchain_type"].nodeinfo.npm_path)
        if is_windows:
            npm_wrapper = ctx.actions.declare_file("%s_node_bin/npm.bat" % ctx.label.name)
            ctx.actions.expand_template(
                template = ctx.file._npm_wrapper_bat,
                output = npm_wrapper,
                substitutions = {},
                is_executable = True,
            )
        else:
            npm_wrapper = ctx.actions.declare_file("%s_node_bin/npm" % ctx.label.name)
            ctx.actions.expand_template(
                template = ctx.file._npm_wrapper_sh,
                output = npm_wrapper,
                substitutions = {},
                is_executable = True,
            )
        toolchain_files.append(npm_wrapper)

    node_path = _target_tool_short_path(ctx.workspace_name, ctx.toolchains["@rules_nodejs//nodejs:toolchain_type"].nodeinfo.target_tool_path)

    launcher_subst = {
        "{{target_label}}": _consistent_label_str(ctx.workspace_name, ctx.label),
        "{{template_label}}": _consistent_label_str(ctx.workspace_name, ctx.attr._launcher_template.label),
        "{{entry_point_label}}": _consistent_label_str(ctx.workspace_name, ctx.attr.entry_point.label),
        "{{entry_point_path}}": entry_point_path,
        "{{envs}}": "\n".join(envs),
        "{{fixed_args}}": " ".join(fixed_args_expanded),
        "{{initialize_runfiles}}": BASH_INITIALIZE_RUNFILES,
        "{{log_prefix_rule_set}}": log_prefix_rule_set,
        "{{log_prefix_rule}}": log_prefix_rule,
        "{{node_options}}": "\n".join(node_options),
        "{{node_patches}}": ctx.file._node_patches_legacy.short_path if use_legacy_node_patches else ctx.file._node_patches.short_path,
        "{{node_wrapper}}": node_wrapper.short_path,
        "{{node}}": node_path,
        "{{npm}}": npm_path,
        "{{workspace_name}}": ctx.workspace_name,
    }

    launcher = ctx.actions.declare_file("%s.sh" % ctx.label.name)
    ctx.actions.expand_template(
        template = ctx.file._launcher_template,
        output = launcher,
        substitutions = launcher_subst,
        is_executable = True,
    )

    return launcher, toolchain_files

def _create_launcher(ctx, log_prefix_rule_set, log_prefix_rule, fixed_args = [], fixed_env = {}):
    is_windows = ctx.target_platform_has_constraint(ctx.attr._windows_constraint[platform_common.ConstraintValueInfo])
    is_bazel_6 = is_bazel_6_or_greater()
    unresolved_symlinks_enabled = False
    if hasattr(ctx.attr, "unresolved_symlinks_enabled"):
        unresolved_symlinks_enabled = ctx.attr.unresolved_symlinks_enabled
    use_legacy_node_patches = not is_bazel_6 or not unresolved_symlinks_enabled

    if is_windows and not ctx.attr.enable_runfiles:
        fail("need --enable_runfiles on Windows for to support rules_js")

    if ctx.attr.include_npm and not hasattr(ctx.toolchains["@rules_nodejs//nodejs:toolchain_type"].nodeinfo, "npm_files"):
        fail("include_npm requires a minimum @rules_nodejs version of 5.7.0")

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

    bash_launcher, toolchain_files = _bash_launcher(ctx, entry_point_path, log_prefix_rule_set, log_prefix_rule, fixed_args, fixed_env, is_windows, use_legacy_node_patches)
    launcher = create_windows_native_launcher_script(ctx, bash_launcher) if is_windows else bash_launcher

    files = [bash_launcher] + toolchain_files
    if ctx.attr.copy_data_to_bin:
        files.append(copy_file_to_bin_action(ctx, entry_point))
        files.extend(copy_files_to_bin_actions(ctx, ctx.files.data))
    else:
        files.append(entry_point)
        files.extend(ctx.files.data)
    if use_legacy_node_patches:
        files.extend(ctx.files._node_patches_legacy_files + [ctx.file._node_patches_legacy])
    else:
        files.extend(ctx.files._node_patches_files + [ctx.file._node_patches])
    files.extend(ctx.toolchains["@rules_nodejs//nodejs:toolchain_type"].nodeinfo.tool_files)
    if ctx.attr.include_npm:
        files.extend(ctx.toolchains["@rules_nodejs//nodejs:toolchain_type"].nodeinfo.npm_files)

    runfiles = ctx.runfiles(
        files = files,
        transitive_files = gather_files_from_js_providers(
            targets = ctx.attr.data,
            include_transitive_sources = ctx.attr.include_transitive_sources,
            include_declarations = ctx.attr.include_declarations,
            include_npm_linked_packages = ctx.attr.include_npm_linked_packages,
        ),
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
    doc = """Identical to js_binary, but usable under `bazel test`.

Bazel will set environment variables when a test target is run under `bazel test` and `bazel run`
that a test runner can use.

A runner can write arbitrary outputs files it wants Bazel to pickup and save with the test logs to
`TEST_UNDECLARED_OUTPUTS_DIR`. These get zipped up and saved along with the test logs.

JUnit XML reports can be written to `XML_OUTPUT_FILE` for Bazel to consume.

`TEST_TMPDIR` is an absolute path to a private writeable directory that the test runner can use for
creating temporary files.

LCOV coverage reports can be written to `COVERAGE_OUTPUT_FILE` when running under `bazel coverage`
or if the `--coverage` flag is set.

See the Bazel [Test encyclopedia](https://bazel.build/reference/test-encyclopedia) for details on
the contract between Bazel and a test runner.""",
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
