"""Implementation details of js_binary and js_test rules."""

load("@bazel_lib//lib:copy_to_bin.bzl", "COPY_FILE_TO_BIN_TOOLCHAINS")
load("@bazel_lib//lib:directory_path.bzl", "DirectoryPathInfo")
load("@bazel_lib//lib:expand_make_vars.bzl", "expand_locations", "expand_variables")
load("@bazel_lib//lib:windows_utils.bzl", "create_windows_native_launcher_script")
load("@bazel_skylib//rules:common_settings.bzl", "BuildSettingInfo")
load("@hermetic_launcher//launcher:lib.bzl", hermetic_launcher = "launcher")
load(":bash.bzl", "BASH_INITIALIZE_RUNFILES")
load(":js_helpers.bzl", "LOG_LEVELS", "envs_for_log_level", "gather_files_from_js_infos", "gather_runfiles", "normalize_chdir")

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

        NB: `data` files are copied to the Bazel output tree before being passed
        as inputs to runfiles. See `copy_data_to_bin` docstring for more info.
        """,
    ),
    "entry_point": attr.label(
        allow_files = True,
        doc = """The main script which is evaluated by node.js.

        This is the module referenced by the `require.main` property in the runtime.

        This must be a target that provides a single file or a `DirectoryPathInfo`
        from `@bazel_lib//lib::directory_path.bzl`.
        
        See https://registry.bazel.build/modules/bazel_lib/latest/docs/lib/directory_path.bzl/DirectoryPathInfo
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

        Subject to [$(location)](https://bazel.build/reference/be/make-variables#predefined_label_variables)
        and ["Make variable"](https://bazel.build/reference/be/make-variables) substitution if `expand_env` is set to True.
        """,
    ),
    "expand_args": attr.bool(
        default = True,
        doc = """Enables [$(location)](https://bazel.build/reference/be/make-variables#predefined_label_variables)
        and ["Make variable"](https://bazel.build/reference/be/make-variables) substitution for `fixed_args`.

        This comes at some analysis-time cost even for a set of args that does not have any expansions.""",
    ),
    "expand_env": attr.bool(
        default = True,
        doc = """Enables [$(location)](https://bazel.build/reference/be/make-variables#predefined_label_variables)
        and ["Make variable"](https://bazel.build/reference/be/make-variables) substitution for `env`.

        This comes at some analysis-time cost even for a set of envs that does not have any expansions.""",
    ),
    "fixed_args": attr.string_list(
        doc = """Fixed command line arguments to pass to the Node.js when this
        binary target is executed.

        Subject to [$(location)](https://bazel.build/reference/be/make-variables#predefined_label_variables)
        and ["Make variable"](https://bazel.build/reference/be/make-variables) substitution if `expand_args` is set to True.

        Unlike the built-in `args`, which are only passed to the target when it is
        executed either by the `bazel run` command or as a test, `fixed_args` are baked
        into the generated launcher script so are always passed even when the binary
        target is run outside of Bazel directly from the launcher script.

        `fixed_args` are passed before the ones specified in `args` and before ones
        that are specified on the `bazel run` or `bazel test` command line.

        See https://bazel.build/reference/be/common-definitions#common-attributes-binaries
        for more info on the built-in `args` attribute.
        """,
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
        only on a build failure along with the stdout & stderr of the node tool being run.

        When js_run_binary captures stderr to an output file, info and debug logs are written to
        that file along with the stderr of the node tool being run, and are not echoed to the
        terminal even on a build failure. Fatal and error logs are always written to the real stderr
        in that case, since Bazel discards the output file of a failed action.

        Log levels: {}""".format(", ".join(LOG_LEVELS.keys())),
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
    "include_sources": attr.bool(
        doc = """When True, `sources` from `JsInfo` providers in `data` targets are included in the runfiles of the target.""",
        default = True,
    ),
    "include_transitive_sources": attr.bool(
        doc = """When True, `transitive_sources` from `JsInfo` providers in `data` targets are included in the runfiles of the target.""",
        default = True,
    ),
    "include_types": attr.bool(
        doc = """When True, `types` from `JsInfo` providers in `data` targets are included in the runfiles of the target.

        Defaults to False since types are generally not needed at runtime and introducing them could slow down developer round trip
        time due to having to generate typings on source file changes.

        NB: These are types from direct `data` dependencies only. You may also need to set `include_transitive_types` to True.""",
        default = False,
    ),
    "include_transitive_types": attr.bool(
        doc = """When True, `transitive_types` from `JsInfo` providers in `data` targets are included in the runfiles of the target.

        Defaults to False since types are generally not needed at runtime and introducing them could slow down developer round trip
        time due to having to generate typings on source file changes.""",
        default = False,
    ),
    "include_npm_sources": attr.bool(
        doc = """When True, files in `npm_sources` from `JsInfo` providers in `data` targets are included in the runfiles of the target.

        `transitive_files` from `NpmPackageStoreInfo` providers in `data` targets are also included in the runfiles of the target.
        """,
        default = True,
    ),
    "preserve_symlinks_main": attr.bool(
        doc = """When True, the --preserve-symlinks-main flag is passed to node.

        This prevents node from following an ESM entry script out of runfiles and the sandbox. This can happen for `.mjs`
        ESM entry points where the fs node patches, which guard the runfiles and sandbox, are not applied.
        See https://github.com/aspect-build/rules_js/issues/362 for more information. Once #362 is resolved,
        the default for this attribute can be set to False.

        See https://nodejs.org/api/cli.html#--preserve-symlinks-main for more information.
        """,
        default = True,
    ),
    "no_copy_to_bin": attr.label_list(
        allow_files = True,
        doc = """List of files to not copy to the Bazel output tree when `copy_data_to_bin` is True.

        This is useful for exceptional cases where a `copy_to_bin` is not possible or not suitable for an input
        file such as a file in an external repository. In most cases, this option is not needed.
        See `copy_data_to_bin` docstring for more info.
        """,
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
    "node_toolchain": attr.label(
        doc = """The Node.js runtime toolchain to use for this target.

        See https://bazel-contrib.github.io/rules_nodejs/Toolchains.html

        Typically this is left unset so that Bazel automatically selects the right Node.js toolchain
        for the target platform. See https://bazel.build/extending/toolchains#toolchain-resolution
        for more information.
        """,
    ),
    "_launcher_template": attr.label(
        default = Label("//js/private:js_binary.sh.tpl"),
        allow_single_file = True,
    ),
    "_launcher_js_template": attr.label(
        default = Label("//js/private:js_binary.cjs.tpl"),
        allow_single_file = True,
    ),
    # Selects the hermetic launcher over the bash launcher. See docs/hermetic_launcher.md.
    "_hermetic_launcher": attr.label(
        default = Label("//js:hermetic_launcher"),
        providers = [BuildSettingInfo],
    ),
    # Windows gets its own separate directory for node and npm wrappers. This
    # ensures that the bash scripts do not end up on the PATH when we build for
    # Windows.
    "_node_wrapper_sh": attr.label(
        default = Label("//js/private:node_bin/node"),
        allow_single_file = True,
    ),
    "_node_wrapper_bat": attr.label(
        default = Label("//js/private:node_bin_windows/node.bat"),
        allow_single_file = True,
    ),
    "_npm_wrapper_sh": attr.label(
        default = Label("//js/private:npm_bin/npm"),
        allow_single_file = True,
    ),
    "_npm_wrapper_bat": attr.label(
        default = Label("//js/private:npm_bin_windows/npm.bat"),
        allow_single_file = True,
    ),
    "_windows_constraint": attr.label(default = "@platforms//os:windows"),
    "_node_patches_files": attr.label_list(
        allow_files = True,
        default = [Label("@aspect_rules_js//js/private/node-bootstrap:fs.cjs")],
    ),
    "_node_patches": attr.label(
        allow_single_file = True,
        default = Label("@aspect_rules_js//js/private/node-bootstrap:bootstrap.cjs"),
    ),
    # Required by bootstrap.cjs only under `bazel coverage`
    "_coverage_bootstrap": attr.label(
        allow_single_file = True,
        default = Label("@aspect_rules_js//js/private/node-bootstrap:coverage.cjs"),
    ),
}

_ENV_SET = """export {var}={quoted_value}"""
_ENV_SET_IFF_NOT_SET = """if [[ -z "${{{var}:-}}" ]]; then export {var}={quoted_value}; fi"""
_NODE_OPTION = """JS_BINARY__NODE_OPTIONS+=(\"{value}\")"""

# The same three, in the JavaScript launcher's syntax. setEnv/setEnvIfUnset and
# addNodeOption are defined by js_binary.cjs.tpl.
_ENV_SET_JS = """setEnv({quoted_var}, {quoted_value})"""
_ENV_SET_IFF_NOT_SET_JS = """setEnvIfUnset({quoted_var}, {quoted_value})"""
_NODE_OPTION_JS = """addNodeOption({quoted_value})"""

# Toolchains of the hermetic launcher, resolved here as Labels rather than used as the
# bare strings hermetic_launcher exposes: under --incompatible_auto_exec_groups a string
# toolchain type is resolved against the repository mapping of whichever module is being
# built, so a consumer that does not itself depend on hermetic_launcher cannot resolve
# the name. A Label is resolved against this file's own mapping at load time instead.
_FINALIZER_TOOLCHAIN_TYPE = Label(hermetic_launcher.finalizer_toolchain_type)
_TEMPLATE_TOOLCHAIN_TYPE = Label(hermetic_launcher.template_toolchain_type)

# Stands in for the launcher on target platforms hermetic_launcher publishes no stub for
# (e.g. linux ppc64le). Not a launcher: it exists only so that `bazel build //...` for
# such a platform succeeds and running the result says why it cannot. See #2347.
_NO_LAUNCHER_PLACEHOLDER = """#!/bin/sh
echo "ERROR: {target}: no hermetic_launcher stub is registered for this target platform, so this js_binary has no launcher and cannot run. See https://github.com/hermeticbuild/hermetic-launcher for the supported platforms." >&2
exit 1
"""

def _expand_env_if_needed(ctx, value):
    if ctx.attr.expand_env:
        return " ".join([expand_variables(ctx, exp, attribute_name = "env") for exp in expand_locations(ctx, value, ctx.attr.data).split(" ")])
    return value

def _quote(value):
    """Quotes a string for either launcher.

    JSON encoding produces a literal that is valid in both bash double quotes and
    JavaScript, so both launchers use it.
    """
    return json.encode(value)

def _shell_tokenize(value):
    """Splits a fixed_arg the way bash does when it is spliced into an array literal.

    The bash launcher builds `ALL_ARGS=({{fixed_args}} "$@")`, so each fixed_arg is
    subject to word splitting and quote removal. `$(rootpaths ...)` expanding to several
    paths relies on the splitting and a `'...'`-wrapped arg relies on the quote removal;
    both are covered by //js/private/test/fixed_args. The JavaScript launcher has no
    shell, so the same splitting is done here.

    Backslash escapes are deliberately not interpreted (bash would have), so a
    Windows-style path in a fixed_arg survives intact. Runtime `$VAR` expansion is done
    by the launcher, not here.

    Args:
        value: the fixed_arg to split

    Returns:
        the list of argv entries it produces
    """
    tokens = []
    current = ""
    has_token = False
    quote = None
    for ch in value.elems():
        if quote:
            if ch == quote:
                quote = None
            else:
                current += ch
        elif ch == "'" or ch == "\"":
            quote = ch
            has_token = True
        elif ch == " " or ch == "\t" or ch == "\n" or ch == "\r":
            if has_token:
                tokens.append(current)
                current = ""
                has_token = False
        else:
            current += ch
            has_token = True
    if has_token:
        tokens.append(current)
    return tokens

def _generates_coverage_report(ctx):
    """Whether the launcher generates the lcov report in the test action. See #2901."""
    return (hasattr(ctx.file, "_coverage_report") and
            ctx.attr.testonly and
            ctx.configuration.coverage_enabled)

def _launcher_envs(ctx, fixed_env, is_windows):
    """The environment the launcher sets, as (var, value, iff_not_set) triples.

    Shared by both launcher implementations so that the two cannot drift; each formats
    the triples in its own syntax. Order is significant: a value may reference an earlier
    one, which both launchers expand as they go.

    Args:
        ctx: the rule context
        fixed_env: environment supplied by the caller of create_launcher
        is_windows: whether the target platform is Windows

    Returns:
        an (envs, normalized_chdir) tuple
    """

    # Explicitly disable node fs patches on Windows:
    # https://github.com/aspect-build/rules_js/issues/1137
    if is_windows:
        fixed_env = dict(fixed_env, **{"JS_BINARY__PATCH_NODE_FS": "0"})

    envs = [
        (key, _expand_env_if_needed(ctx, value), False)
        for key, value in fixed_env.items()
    ] + [
        (key, _expand_env_if_needed(ctx, value), False)
        for key, value in ctx.attr.env.items()
    ]

    # Add common and useful make variables to the environment
    makevars = {
        "JS_BINARY__BINDIR": "$(BINDIR)",
        "JS_BINARY__COMPILATION_MODE": "$(COMPILATION_MODE)",
        "JS_BINARY__TARGET_CPU": "$(TARGET_CPU)",
    }
    for (key, value) in makevars.items():
        envs.append((key, ctx.expand_make_variables("env", value, {}), False))

    # Add rule context variables to the environment
    builtins = {
        "JS_BINARY__BUILD_FILE_PATH": ctx.build_file_path,
        "JS_BINARY__PACKAGE": ctx.label.package,
        "JS_BINARY__TARGET_NAME": ctx.label.name,
        "JS_BINARY__TARGET": "{}//{}:{}".format(
            "@" + ctx.label.repo_name if ctx.label.repo_name else "",
            ctx.label.package,
            ctx.label.name,
        ),
        "JS_BINARY__WORKSPACE": ctx.workspace_name,
    }
    if is_windows and not ctx.attr.enable_runfiles:
        builtins["JS_BINARY__NO_RUNFILES"] = "1"
    for (key, value) in builtins.items():
        envs.append((key, value, False))

    if ctx.attr.patch_node_fs:
        # Set patch node fs API env if not already set to allow js_run_binary to override
        envs.append(("JS_BINARY__PATCH_NODE_FS", "1", True))

    if ctx.attr.expected_exit_code:
        envs.append(("JS_BINARY__EXPECTED_EXIT_CODE", str(ctx.attr.expected_exit_code), False))

    if ctx.attr.copy_data_to_bin:
        # Set an environment variable to flag that we have copied js_binary data to bin
        envs.append(("JS_BINARY__COPY_DATA_TO_BIN", "1", False))

    normalized_chdir = ""

    if ctx.attr.chdir:
        # Set chdir env if not already set to allow js_run_binary to override
        normalized_chdir = normalize_chdir(_expand_env_if_needed(ctx, ctx.attr.chdir), ctx.label.repo_name)
        envs.append(("JS_BINARY__CHDIR", normalized_chdir, True))

    # Set log envs iff not already set to allow js_run_binary to override
    for env in envs_for_log_level(ctx.attr.log_level):
        envs.append((env, "1", True))

    if _generates_coverage_report(ctx):
        envs.append((
            "JS_BINARY__COVERAGE_REPORT",
            "/".join([ctx.workspace_name, ctx.file._coverage_report.short_path]),
            False,
        ))

    return envs, normalized_chdir

def _launcher_node_options(ctx):
    """The node CLI options the launcher passes, in order.

    `--preserve-symlinks-main` is appended unconditionally when the attribute is set,
    which is what the launcher has always done: the de-duplication check this replaced
    compared the flag against already-formatted shell statements and so never matched.
    """
    node_options = [_expand_env_if_needed(ctx, node_option) for node_option in ctx.attr.node_options]
    if ctx.attr.preserve_symlinks_main:
        node_options.append("--preserve-symlinks-main")
    return node_options

def _launcher_paths(ctx, nodeinfo, is_windows):
    """The toolchain paths both launchers bake in, and the files that back them."""
    node_wrapper = ctx.file._node_wrapper_bat if is_windows else ctx.file._node_wrapper_sh
    toolchain_files = [node_wrapper]

    npm_path = ""
    npm_wrapper_path = ""
    if ctx.attr.include_npm:
        npm_path = nodeinfo.npm.short_path if nodeinfo.npm else nodeinfo.npm_path
        npm_wrapper = ctx.file._npm_wrapper_bat if is_windows else ctx.file._npm_wrapper_sh
        npm_wrapper_path = npm_wrapper.short_path
        toolchain_files.append(npm_wrapper)

    return struct(
        node_path = nodeinfo.node.short_path if nodeinfo.node else nodeinfo.node_path,
        node_wrapper_path = node_wrapper.short_path,
        npm_path = npm_path,
        npm_wrapper_path = npm_wrapper_path,
        toolchain_files = toolchain_files,
    )

def _bash_launcher(ctx, entry_point_path, log_prefix_rule_set, log_prefix_rule, fixed_args, envs, node_options, paths):
    launcher_subst = {
        "{{target_label}}": str(ctx.label),
        "{{template_label}}": str(ctx.attr._launcher_template.label),
        "{{entry_point_label}}": str(ctx.attr.entry_point.label),
        "{{entry_point_path}}": entry_point_path,
        "{{envs}}": "\n".join([
            (_ENV_SET_IFF_NOT_SET if iff_not_set else _ENV_SET).format(
                var = var,
                quoted_value = _quote(value),
            )
            for (var, value, iff_not_set) in envs
        ]),
        "{{fixed_args}}": " ".join(fixed_args),
        "{{initialize_runfiles}}": BASH_INITIALIZE_RUNFILES,
        "{{log_prefix_rule_set}}": log_prefix_rule_set,
        "{{log_prefix_rule}}": log_prefix_rule,
        "{{node_options}}": "\n".join([
            _NODE_OPTION.format(value = value)
            for value in node_options
        ]),
        "{{node_patches}}": ctx.file._node_patches.short_path,
        "{{node_wrapper}}": paths.node_wrapper_path,
        "{{node}}": paths.node_path,
        "{{npm}}": paths.npm_path,
        "{{npm_wrapper}}": paths.npm_wrapper_path,
        "{{workspace_name}}": ctx.workspace_name,
    }

    # The '_' avoids collisions with another file matching the label name.
    # For example, test and test/my.spec.ts. This naming scheme is borrowed from rules_go:
    # https://github.com/bazelbuild/rules_go/blob/f3cc8a2d670c7ccd5f45434ab226b25a76d44de1/go/private/context.bzl#L144
    launcher = ctx.actions.declare_file("{}_/{}".format(ctx.label.name, ctx.label.name))
    ctx.actions.expand_template(
        template = ctx.file._launcher_template,
        output = launcher,
        substitutions = launcher_subst,
        is_executable = True,
    )

    return launcher

def _compile_stub(ctx, embedded_args, transformed_args, output_file):
    """Stamps a launcher binary from the prebuilt template stub.

    This is `hermetic_launcher.compile_stub` reimplemented so the finalizer toolchain can
    be named by Label; see the comment on _FINALIZER_TOOLCHAIN_TYPE. Drop this in favour
    of the upstream helper once it takes Labels.
    """
    template = ctx.toolchains[_TEMPLATE_TOOLCHAIN_TYPE].templatetoolchaininfo.template_exe
    args = ctx.actions.args()
    args.add("--template", template)
    args.add("-o", output_file)
    args.add_joined("--transform", transformed_args, join_with = ",")
    args.add("--")
    args.add_all(embedded_args)
    ctx.actions.run(
        outputs = [output_file],
        executable = ctx.toolchains[_FINALIZER_TOOLCHAIN_TYPE].finalizer_info.finalizer,
        arguments = [args],
        inputs = [template],
        toolchain = _FINALIZER_TOOLCHAIN_TYPE,
        mnemonic = "JsLauncher",
        progress_message = "Stamping launcher %{output}",
    )

def _js_launcher(ctx, nodeinfo, entry_point_path, log_prefix_rule_set, log_prefix_rule, fixed_args, envs, node_options, paths, is_windows):
    """The hermetic launcher: a native stub that execs node on a generated JavaScript launcher.

    The stub can only execve, so everything the bash launcher did in shell is done by the
    generated `.cjs` instead -- an almost literal translation of js_binary.sh.tpl, minus
    the stdout/stderr/exit code capture and silent_on_success that js_run_binary no longer
    asks the launcher for. See docs/hermetic_launcher.md.

    Returns:
        an (executable, launcher_js) tuple
    """
    launcher_js = ctx.actions.declare_file("{}_/{}.cjs".format(ctx.label.name, ctx.label.name))
    ctx.actions.expand_template(
        template = ctx.file._launcher_js_template,
        output = launcher_js,
        substitutions = {
            "{{target_label}}": str(ctx.label),
            "{{template_label}}": str(ctx.attr._launcher_js_template.label),
            "{{entry_point_label}}": str(ctx.attr.entry_point.label),
            "{{entry_point_path}}": entry_point_path,
            "{{envs}}": "\n".join([
                (_ENV_SET_IFF_NOT_SET_JS if iff_not_set else _ENV_SET_JS).format(
                    quoted_var = _quote(var),
                    quoted_value = _quote(value),
                )
                for (var, value, iff_not_set) in envs
            ]),
            # Tokenized here rather than in the launcher, which has no shell to do the
            # word splitting and quote removal the bash launcher got for free.
            "{{fixed_args}}": json.encode([
                token
                for fixed_arg in fixed_args
                for token in _shell_tokenize(fixed_arg)
            ]),
            "{{log_prefix_rule_set}}": log_prefix_rule_set,
            "{{log_prefix_rule}}": log_prefix_rule,
            "{{node_options}}": "\n".join([
                _NODE_OPTION_JS.format(quoted_value = _quote(value))
                for value in node_options
            ]),
            "{{node_patches}}": ctx.file._node_patches.short_path,
            "{{node_wrapper}}": paths.node_wrapper_path,
            "{{node}}": paths.node_path,
            "{{npm}}": paths.npm_path,
            "{{npm_wrapper}}": paths.npm_wrapper_path,
            "{{workspace_name}}": ctx.workspace_name,
        },
    )

    if not ctx.toolchains[_TEMPLATE_TOOLCHAIN_TYPE] or not ctx.toolchains[_FINALIZER_TOOLCHAIN_TYPE]:
        launcher = ctx.actions.declare_file("{}_/{}".format(ctx.label.name, ctx.label.name))
        ctx.actions.write(
            output = launcher,
            content = _NO_LAUNCHER_PLACEHOLDER.format(target = ctx.label),
            is_executable = True,
        )
        return launcher, launcher_js

    # The stub embeds two arguments: node, and the JavaScript launcher it runs. Both are
    # rlocation paths, which carry no output-tree configuration segment and so stay
    # correct under path mapping.
    if nodeinfo.node:
        embedded_args, transformed_args = hermetic_launcher.args_from_entrypoint(
            executable_file = nodeinfo.node,
        )
    elif paths.node_path.startswith("/"):
        # A node_toolchain may name a non-hermetic node by absolute path rather than
        # provide a File. The stub passes absolute paths through untouched, so there is
        # nothing for it to resolve.
        embedded_args, transformed_args = [paths.node_path], []
    else:
        # A relative node_path is relative to this workspace within the runfiles tree,
        # matching how the launcher resolves it.
        embedded_args, transformed_args = hermetic_launcher.append_raw_transformed_arg(
            arg = "{}/{}".format(ctx.workspace_name, paths.node_path),
            embedded_args = [],
            transformed_args = [],
        )
    embedded_args, transformed_args = hermetic_launcher.append_runfile(
        file = launcher_js,
        embedded_args = embedded_args,
        transformed_args = transformed_args,
    )

    # args_from_entrypoint yields ints while the append helpers yield strings; ctx.args
    # only takes strings.
    transformed_args = [str(index) for index in transformed_args]

    # Windows dispatches on the file extension, so the stub needs the .exe suffix to be
    # executable at all.
    launcher = ctx.actions.declare_file("{}_/{}{}".format(
        ctx.label.name,
        ctx.label.name,
        ".exe" if is_windows else "",
    ))
    _compile_stub(ctx, embedded_args, transformed_args, launcher)
    return launcher, launcher_js

def _create_launcher(ctx, log_prefix_rule_set, log_prefix_rule, fixed_args = [], fixed_env = {}):
    is_windows = ctx.target_platform_has_constraint(ctx.attr._windows_constraint[platform_common.ConstraintValueInfo])

    if ctx.attr.node_toolchain:
        nodeinfo = ctx.attr.node_toolchain[platform_common.ToolchainInfo].nodeinfo
    else:
        nodeinfo = ctx.toolchains["@rules_nodejs//nodejs:runtime_toolchain_type"].nodeinfo

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

    # Expanded here rather than in either launcher so that both bake in the same
    # arguments.
    if ctx.attr.expand_args:
        fixed_args = [expand_variables(ctx, expand_locations(ctx, fixed_arg, ctx.attr.data)) for fixed_arg in fixed_args]

    envs, chdir = _launcher_envs(ctx, fixed_env, is_windows)
    node_options = _launcher_node_options(ctx)
    paths = _launcher_paths(ctx, nodeinfo, is_windows)

    launcher_js = None
    if ctx.attr._hermetic_launcher[BuildSettingInfo].value:
        launcher, launcher_js = _js_launcher(ctx, nodeinfo, entry_point_path, log_prefix_rule_set, log_prefix_rule, fixed_args, envs, node_options, paths, is_windows)
        launcher_files = [launcher, launcher_js]
    else:
        bash_launcher = _bash_launcher(ctx, entry_point_path, log_prefix_rule_set, log_prefix_rule, fixed_args, envs, node_options, paths)
        launcher = create_windows_native_launcher_script(ctx, bash_launcher) if is_windows else bash_launcher
        launcher_files = [bash_launcher]

    launcher_files.extend(paths.toolchain_files)
    if nodeinfo.node:
        launcher_files.append(nodeinfo.node)

    launcher_files.extend(ctx.files._node_patches_files + [ctx.file._node_patches])

    # The coverage bootstrap code is required in the root node process, which will enable
    # coverage for child processes by setting NODE_V8_COVERAGE. Any js_binary could in
    # principle be the root node process (for example if it is invoked by an sh_test), so we
    # need to include the coverage bootstrap for every js_binary target. It ships with the
    # launcher so that rules such as js_run_devserver get it as well.
    if ctx.configuration.coverage_enabled:
        launcher_files.append(ctx.file._coverage_bootstrap)

    transitive_launcher_files = None
    if ctx.attr.include_npm:
        transitive_launcher_files = nodeinfo.npm_sources

    # The subset of runfiles that make up the entry point and its data, as opposed to the
    # launcher and its other dependencies.
    data_runfiles = gather_runfiles(
        ctx = ctx,
        data = ctx.attr.data,
        data_files = [entry_point] + ctx.files.data,
        copy_data_files_to_bin = ctx.attr.copy_data_to_bin,
        no_copy_to_bin = ctx.files.no_copy_to_bin,
    ).merge(ctx.runfiles(
        transitive_files = gather_files_from_js_infos(
            targets = ctx.attr.data,
            include_sources = ctx.attr.include_sources,
            include_types = ctx.attr.include_types,
            include_transitive_sources = ctx.attr.include_transitive_sources,
            include_transitive_types = ctx.attr.include_transitive_types,
            include_npm_sources = ctx.attr.include_npm_sources,
        ),
    ))

    runfiles = data_runfiles.merge(ctx.runfiles(
        files = launcher_files,
        transitive_files = transitive_launcher_files,
    ))

    return struct(
        executable = launcher,
        runfiles = runfiles,
        data_runfiles = data_runfiles,
        chdir = chdir,
        # The generated JavaScript launcher, or None when the bash launcher is in use.
        # js_image_layer rewrites it for hermeticity; see also the launcher_js output
        # group on js_binary.
        launcher_js = launcher_js,
    )

def _js_binary_impl(ctx):
    launcher = _create_launcher(
        ctx,
        log_prefix_rule_set = "aspect_rules_js",
        log_prefix_rule = "js_test" if ctx.attr.testonly else "js_binary",
        fixed_args = ctx.attr.fixed_args,
    )
    runfiles = launcher.runfiles

    providers = []

    # Create RunEnvironmentInfo provider with both env and env_inherit (if available)
    run_env_info_kwargs = {}

    if ctx.attr.env:
        action_context_env_expanded = {}
        for key, value in ctx.attr.env.items():
            action_context_env_expanded[key] = _expand_env_if_needed(ctx, value)
        run_env_info_kwargs["environment"] = action_context_env_expanded

    # Add inherited environment variables (for js_test)
    if hasattr(ctx.attr, "env_inherit"):
        run_env_info_kwargs["inherited_environment"] = ctx.attr.env_inherit

    # Only create provider if we have something to provide
    if run_env_info_kwargs:
        providers.append(RunEnvironmentInfo(**run_env_info_kwargs))

    if ctx.attr.testonly and ctx.configuration.coverage_enabled:
        # We have to propagate _lcov_merger runfiles since bazel does not treat _lcov_merger as a proper tool.
        # See: https://github.com/bazelbuild/bazel/issues/4033
        # This is optional because:
        # - We do not want to require it for js_binary targets
        #   (but we cannot distinguish js_binary from js_test here, see #2229).
        # - It is not required anymore on bazel 8
        #   (https://github.com/bazelbuild/bazel/issues/4033#issuecomment-2507162290)
        # TODO: Remove once bazel<8 support is dropped.
        if hasattr(ctx.attr, "_lcov_merger"):
            runfiles = runfiles.merge(ctx.attr._lcov_merger[DefaultInfo].default_runfiles)

        # coverage.cjs runs coverage.js when the test program exits to generate the
        # report, so the generator must be included in the test's runfiles. See #2901.
        if _generates_coverage_report(ctx):
            runfiles = runfiles.merge(ctx.runfiles(files = [ctx.file._coverage_report]))

        providers.append(
            coverage_common.instrumented_files_info(
                ctx,
                source_attributes = ["data"],
                dependency_attributes = ["data"],
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
        )

    return providers + [
        DefaultInfo(
            executable = launcher.executable,
            runfiles = runfiles,
        ),
        OutputGroupInfo(
            # The entry point and its data, excluding the launcher/node/npm/node-patches
            # toolchain scaffolding. Consumed by js_run_binary when
            # use_execroot_entry_point is enabled.
            execroot_data_files = launcher.data_runfiles.files,
            # The generated JavaScript launcher, empty unless the hermetic launcher is
            # selected. Consumed by js_image_layer, which has to rewrite it, and by the
            # launcher snapshot test.
            launcher_js = depset([launcher.launcher_js] if launcher.launcher_js else []),
        ),
    ]

def _bazel_bindir_arg(file):
    return file.root.path

def _run_binary_action(ctx, **kwargs):
    """Runs a `js_binary` as a tool in a custom rule's action.

    This helper function handles internal implementation details related to invoking a
    `js_binary`. We recommend that rule authors use this whenever possible, rather than
    directly invoking the `js_binary`. The `executable` must be a `js_binary` target.

    Args:
        ctx: the rule context
        **kwargs: additional arguments forwarded to `ctx.actions.run`, e.g. `executable`,
            `arguments`, `inputs`, `outputs`, `mnemonic`, `execution_requirements`, `env`
    """

    # The only way to trigger path mapping is by passing a File directly to args.add() or
    # args.add_all(). To get ahold of the path-mapped output bin directory, we have to add
    # an output here and then derive the bin directory from it in the map_each callback.
    outputs = kwargs.get("outputs")
    if not outputs:
        fail("run_binary_action requires at least one output")
    extra_args = ctx.actions.args()
    extra_args.add("--bazel-bindir")

    # Set expand_directories = False to ensure this works correctly if
    # outputs[0] is a directory.
    extra_args.add_all([outputs[0]], map_each = _bazel_bindir_arg, expand_directories = False)

    ctx.actions.run(
        arguments = [extra_args] + (kwargs.pop("arguments", None) or []),
        **kwargs
    )

js_binary_lib = struct(
    attrs = _ATTRS,
    create_launcher = _create_launcher,
    implementation = _js_binary_impl,
    run_binary_action = _run_binary_action,
    toolchains = [
        # Optional: only referenced on Windows
        config_common.toolchain_type("@bazel_tools//tools/sh:toolchain_type", mandatory = False),
        # Optional: only referenced when the hermetic launcher is selected, and absent
        # for a target platform hermetic_launcher publishes no stub for.
        config_common.toolchain_type(_FINALIZER_TOOLCHAIN_TYPE, mandatory = False),
        config_common.toolchain_type(_TEMPLATE_TOOLCHAIN_TYPE, mandatory = False),
        "@rules_nodejs//nodejs:runtime_toolchain_type",
    ] + COPY_FILE_TO_BIN_TOOLCHAINS,
)

js_binary = rule(
    implementation = js_binary_lib.implementation,
    attrs = js_binary_lib.attrs,
    executable = True,
    toolchains = js_binary_lib.toolchains,
)

js_test = rule(
    implementation = js_binary_lib.implementation,
    attrs = dict(js_binary_lib.attrs, **{
        "env_inherit": attr.string_list(
            default = [],
            doc = "Specifies additional environment variables to inherit from the external environment when the test is executed by bazel test.",
        ),
        # TODO: Remove once bazel<8 support is dropped.
        # See comment at usage site in the rule impl for more.
        "_lcov_merger": attr.label(
            executable = True,
            default = Label("//js/private/coverage:merger"),
            cfg = "exec",
        ),
        # Run by the launcher in the test action to generate the lcov report, which
        # _lcov_merger above then publishes. A test rule built on js_binary_lib needs
        # both halves. See #2901.
        "_coverage_report": attr.label(
            default = Label("//js/private/coverage:coverage.js"),
            allow_single_file = [".js"],
        ),
    }),
    test = True,
    toolchains = js_binary_lib.toolchains,
)
