"""Implementation details of js_binary and js_test rules."""

load("@bazel_lib//lib:copy_to_bin.bzl", "COPY_FILE_TO_BIN_TOOLCHAINS")
load("@bazel_lib//lib:directory_path.bzl", "DirectoryPathInfo")
load("@bazel_lib//lib:expand_make_vars.bzl", "expand_locations", "expand_variables")
load("@bazel_lib//lib:paths.bzl", "to_rlocation_path")
load("@bazel_lib//lib:windows_utils.bzl", "create_windows_native_launcher_script")
load("@hermetic_launcher//launcher:lib.bzl", "launcher")
load(":bash.bzl", "BASH_INITIALIZE_RUNFILES")
load(":js_helpers.bzl", "LOG_LEVELS", "envs_for_log_level", "gather_files_from_js_infos", "gather_runfiles")

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
        
        See https://registry.bazel.build/docs/bazel_lib#provider-directorypathinfo
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
    # Required by bootstrap.cjs only when generating a coverage report
    "_coverage_bootstrap": attr.label(
        allow_single_file = True,
        default = Label("@aspect_rules_js//js/private/node-bootstrap:coverage.cjs"),
    ),
    "_hermetic_bootstrap": attr.label(
        allow_single_file = True,
        default = Label("@aspect_rules_js//js/private/node-bootstrap:launcher.cjs"),
    ),
}

_ENV_SET = """export {var}={quoted_value}"""
_ENV_SET_IFF_NOT_SET = """if [[ -z "${{{var}:-}}" ]]; then export {var}={quoted_value}; fi"""
_NODE_OPTION = """JS_BINARY__NODE_OPTIONS+=(\"{value}\")"""

def _expand_env_if_needed(ctx, value):
    if ctx.attr.expand_env:
        return " ".join([expand_variables(ctx, exp, attribute_name = "env") for exp in expand_locations(ctx, value, ctx.attr.data).split(" ")])
    return value

def _bash_quote(value):
    return json.encode(value)

def _generates_coverage_report(ctx):
    """Whether the launcher generates the lcov report in the test action. See #2901."""
    return (hasattr(ctx.file, "_coverage_report") and
            ctx.attr.testonly and
            ctx.configuration.coverage_enabled)

# Resolved here as Labels rather than used as the bare strings hermetic_launcher
# exposes: under --incompatible_auto_exec_groups a string toolchain type is resolved
# against the repository mapping of whichever module is being built, so a consumer
# that does not itself depend on hermetic_launcher cannot resolve the name. A Label
# is resolved against this file's own mapping at load time instead.
_FINALIZER_TOOLCHAIN_TYPE = Label(launcher.finalizer_toolchain_type)
_TEMPLATE_TOOLCHAIN_TYPE = Label(launcher.template_toolchain_type)

# Limits of the prebuilt stub hermetic_launcher patches: arg0..arg9, 256 bytes each.
_MAX_EMBEDDED_ARGS = 10
_MAX_EMBEDDED_ARG_LENGTH = 256

def _compile_stub(ctx, embedded_args, transformed_args, output_file):
    """Stamps a launcher binary from the prebuilt template stub.

    This is `launcher.compile_stub` reimplemented so the finalizer toolchain can be
    named by Label; see the comment on _FINALIZER_TOOLCHAIN_TYPE. Drop this in favour
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

# The two spellings of the runfiles-root reference that the bash launcher expands in
# `fixed_args`, and that the stub can resolve instead. See _classify_fixed_args.
_RUNFILES_DIR_PREFIXES = ["$RUNFILES_DIR/", "${RUNFILES_DIR}/"]

def _classify_fixed_args(fixed_args):
    """Splits expanded `fixed_args` into stub arguments, or reports that it cannot.

    The bash launcher inlines `fixed_args` into the script, so the shell expands them.
    The stub has no shell, but it can resolve an argument through runfiles, which is
    exactly what the documented `"$$RUNFILES_DIR/$(rlocationpath :config)"` idiom needs:
    `$(rlocationpath ...)` is already expanded by the time we get here, so what is left
    is a runfiles-root reference followed by an rlocation path.

    Returns a `(specs, blockers)` tuple. Each spec is a `(kind, value)` pair, where kind
    is "embedded" for a verbatim argument or "runfile" for one the launcher resolves
    against its runfiles at startup. Anything else needs a shell and is a blocker.
    """
    specs = []
    for arg in fixed_args:
        prefix = None
        for candidate in _RUNFILES_DIR_PREFIXES:
            if arg.startswith(candidate):
                prefix = candidate
        if prefix:
            rlocation = arg[len(prefix):]

            # Only a bare rlocation path can be resolved; anything else in there is
            # more shell than the stub can do.
            if "$" in rlocation or not rlocation:
                return [], ["JS_BINARY_FIXED_ARGS"]
            specs.append(("runfile", rlocation))
            continue

        # Any other `$` is a shell expansion, a make variable that expand_args was not
        # asked to substitute, or a runfiles reference in a form not handled above.
        if "$" in arg:
            return [], ["JS_BINARY_FIXED_ARGS"]

        # js_run_binary passes `--bazel-bindir <path>` after the embedded arguments, and
        # launcher.cjs consumes the first occurrence. A fixed arg spelled the same way
        # would be consumed instead.
        if arg == "--bazel-bindir":
            return [], ["JS_BINARY_FIXED_ARGS"]
        specs.append(("embedded", arg))

    return specs, []

def _hermetic_launcher_blockers(ctx, fixed_arg_blockers, fixed_env, is_windows):
    """Why this target cannot use the hermetic launcher, as a list of reason codes.

    An allowlist rather than a denylist: everything the bash launcher does has to be
    either reproduced by launcher.cjs or named here, so an attribute added to
    js_binary later makes targets ineligible rather than silently losing behaviour.
    """
    blockers = []

    # Baked into the launcher script, so the stub can never see them. `env` and
    # `chdir` are also delivered by js_run_binary as action env, which launcher.cjs
    # does honour; it is only the js_binary-level values that have no channel.
    if ctx.attr.chdir:
        blockers.append("JS_BINARY_CHDIR")
    if ctx.attr.env or fixed_env:
        blockers.append("JS_BINARY_ENV")

    # `fixed_args` are baked into the launcher script too, but the stub can carry them
    # as embedded arguments, so only the ones needing a shell are a blocker.
    blockers.extend(fixed_arg_blockers)

    # node parses its options before any preload runs, so these can only be embedded
    # arguments; only --preserve-symlinks-main is, so far.
    if ctx.attr.node_options:
        blockers.append("JS_BINARY_NODE_OPTIONS")

    # Needs work after the program exits, and the stub execve's.
    if ctx.attr.expected_exit_code:
        blockers.append("JS_BINARY_EXPECTED_EXIT_CODE")

    # Needs JS_BINARY__NPM_BINARY and the npm wrapper directory on the PATH.
    if ctx.attr.include_npm:
        blockers.append("JS_BINARY_INCLUDE_NPM")

    # The launcher script refuses to run the execroot entry point without this, since
    # nothing would have put the entry point in the bindir (js_binary.sh.tpl). The check
    # cannot be ported: it reads JS_BINARY__COPY_DATA_TO_BIN, a per-target constant the
    # stub has no way to carry, and js_run_binary's
    # allow_execroot_entry_point_with_no_copy_data_to_bin escape hatch is not visible from
    # here either. Defaults to True, so this blocks almost nothing.
    if not ctx.attr.copy_data_to_bin:
        blockers.append("JS_BINARY_COPY_DATA_TO_BIN")

    # `patch_node_fs` is deliberately not a blocker: js_run_binary always passes
    # JS_BINARY__PATCH_NODE_FS through the action environment, and the launcher script
    # only sets it if it is not already set, so the caller's value wins either way.

    # `log_level` is deliberately not a blocker. The launcher script's info and debug
    # output is diagnostic only -- it dumps PATH, the BAZEL_* and JS_BINARY__* values it
    # computed, and the node command line -- so losing it changes what is printed and
    # nothing else. launcher.cjs logs the steps it performs, and js_run_binary passes
    # JS_BINARY__LOG_* through the action environment, so a log level set there still
    # reaches the preload and bootstrap.cjs. Only a level set on the js_binary itself has
    # no channel to the stub, and is silently not applied.

    # Coverage is deliberately not a blocker. Neither half of it needs the launcher
    # script any more: coverage.cjs generates the lcov report from a node exit hook rather
    # than the script running it once node is gone (#2984), and launcher.cjs starts node
    # over with NODE_V8_COVERAGE set, which is the one thing a preload cannot do to the
    # process it is already running in.

    # The fs patches are force-disabled on Windows (#1137), and the stub there spawns
    # and waits rather than execve'ing.
    #
    # This subsumes `enable_runfiles`, which switches every path to execroot
    # resolution: the launcher script only consults it on Windows, and its
    # config_setting matches only when --enable_runfiles is passed explicitly, so it
    # reads False on a normal Linux build where runfiles are in fact enabled.
    if is_windows:
        blockers.append("WINDOWS")

    return blockers

def _hermetic_launcher(ctx, nodeinfo, entry_point_rlocation, fixed_arg_specs, blockers, is_windows):
    """Stamps a launcher binary that runs the entry point on node with the fs patches applied.

    This is an alternative to the bash launcher: everything it needs is baked into the
    binary, so running it with no arguments runs the js_binary's program with no shell
    involved. It is independent of the bash launcher, which is still what `bazel run`
    executes, and is exposed only through the `hermetic_launcher` output group so that
    the stamping action does not run unless something asks for it.

    The stub can only execve, so the environment setup the bash launcher does in shell
    is done by the launcher.cjs preload instead, in node, before the entry point loads.
    What neither of them can do is named by _hermetic_launcher_blockers; a target with
    any blocker gets no launcher at all and its consumers keep using the bash one.

    Returns None when there is a blocker, or when hermetic_launcher publishes no stub
    for the target platform (e.g. linux ppc64le, windows arm64).
    """
    if not ctx.toolchains[_TEMPLATE_TOOLCHAIN_TYPE] or not ctx.toolchains[_FINALIZER_TOOLCHAIN_TYPE]:
        return None
    if blockers:
        return None

    # Each entry is either a File, resolved through runfiles when the launcher runs, or
    # a string, embedded verbatim.
    #
    # There is no `--` before the entry point. It would only be needed if the entry
    # point could look like a node option, and it cannot: the launcher resolves a
    # transformed argument by prefixing the runfiles root, which is absolute, so what
    # node sees always begins with a path separator. Spending a tenth of the argument
    # budget to guard an impossible case is worse than not having the guard.
    #
    # The preload is launcher.cjs rather than the fs patches directly: it reconstructs
    # what the bash launcher's environment setup would have done and then requires the
    # patches itself. --preserve-symlinks-main has to be here because it is a node CLI
    # flag, so no preload can apply it.
    #
    # `--require` and its value stay two arguments. The launcher cannot resolve
    # `--require=<path>` as one, because the transform prepends the runfiles root to the
    # whole argument rather than to a path inside it: the result is
    # `<runfiles>/--require=<path>`, and node reports the module as missing.
    args = []
    if ctx.attr.preserve_symlinks_main:
        args.append("--preserve-symlinks-main")
    args.extend(["--require", ctx.file._hermetic_bootstrap])

    if nodeinfo.node:
        embedded_args, transformed_args = launcher.args_from_entrypoint(nodeinfo.node)
    elif nodeinfo.node_path.startswith("/"):
        # A node_toolchain may name a non-hermetic node by absolute path rather than
        # provide a File. The launcher passes absolute paths through untouched, so
        # there is nothing for it to resolve.
        embedded_args, transformed_args = [nodeinfo.node_path], []
    else:
        # A relative node_path is relative to this workspace within the runfiles tree,
        # matching how the launcher script resolves it.
        embedded_args, transformed_args = ["{}/{}".format(ctx.workspace_name, nodeinfo.node_path)], [0]

    for arg in args:
        if type(arg) == "File":
            embedded_args, transformed_args = launcher.append_runfile(
                file = arg,
                embedded_args = embedded_args,
                transformed_args = transformed_args,
            )
        else:
            embedded_args, transformed_args = launcher.append_embedded_arg(
                arg = arg,
                embedded_args = embedded_args,
                transformed_args = transformed_args,
            )

    # A runfiles path we already hold as a string rather than a File, since the entry
    # point may be a file inside a directory artifact.
    embedded_args, transformed_args = launcher.append_raw_transformed_arg(
        arg = entry_point_rlocation,
        embedded_args = embedded_args,
        transformed_args = transformed_args,
    )

    # After the entry point and before the arguments the caller passes at run time,
    # which is where the launcher script puts them. A "runfile" spec is resolved by the
    # launcher at startup, the same absolute path the script gets from expanding
    # `$RUNFILES_DIR`; see _classify_fixed_args.
    for (kind, value) in fixed_arg_specs:
        if kind == "runfile":
            embedded_args, transformed_args = launcher.append_raw_transformed_arg(
                arg = value,
                embedded_args = embedded_args,
                transformed_args = transformed_args,
            )
        else:
            embedded_args, transformed_args = launcher.append_embedded_arg(
                arg = value,
                embedded_args = embedded_args,
                transformed_args = transformed_args,
            )

    # The stub holds 10 embedded arguments of at most 256 bytes each. Exceeding either
    # is a build failure inside the finalizer, so degrade to the bash launcher instead:
    # a deeply nested external repository can produce an rlocation path that long.
    if len(embedded_args) > _MAX_EMBEDDED_ARGS:
        return None
    for arg in embedded_args:
        if len(arg) > _MAX_EMBEDDED_ARG_LENGTH:
            return None

    # Declared only now that it is certain to be written: a file declared on a path that
    # returns None above would have no generating action, which fails analysis rather
    # than degrading to the bash launcher.
    #
    # Windows needs the .exe suffix for this to be executable at all. It gets a
    # directory to itself so that its basename can be the target's own name, which is
    # what a reader of `ps` output sees.
    #
    # NB: a js_binary named `hermetic` cannot work, since the bash launcher would be
    # the file `hermetic_/hermetic` and this the directory `hermetic_/hermetic/`.
    output = ctx.actions.declare_file("{}_/hermetic/{}{}".format(
        ctx.label.name,
        ctx.label.name,
        ".exe" if is_windows else "",
    ))

    _compile_stub(ctx, embedded_args, transformed_args, output)
    return output

def _bash_launcher(ctx, nodeinfo, entry_point_path, log_prefix_rule_set, log_prefix_rule, fixed_args, fixed_env, is_windows):
    # Explicitly disable node fs patches on Windows:
    # https://github.com/aspect-build/rules_js/issues/1137
    if is_windows:
        fixed_env = dict(fixed_env, **{"JS_BINARY__PATCH_NODE_FS": "0"})

    envs = [
        _ENV_SET.format(var = key, quoted_value = _bash_quote(_expand_env_if_needed(ctx, value)))
        for key, value in fixed_env.items()
    ] + [
        _ENV_SET.format(var = key, quoted_value = _bash_quote(_expand_env_if_needed(ctx, value)))
        for key, value in ctx.attr.env.items()
    ]

    # Add common and useful make variables to the environment
    makevars = {
        "JS_BINARY__BINDIR": "$(BINDIR)",
        "JS_BINARY__COMPILATION_MODE": "$(COMPILATION_MODE)",
        "JS_BINARY__TARGET_CPU": "$(TARGET_CPU)",
    }
    for (key, value) in makevars.items():
        envs.append(_ENV_SET.format(
            var = key,
            quoted_value = _bash_quote(ctx.expand_make_variables("env", value, {})),
        ))

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
        envs.append(_ENV_SET.format(var = key, quoted_value = _bash_quote(value)))

    if ctx.attr.patch_node_fs:
        # Set patch node fs API env if not already set to allow js_run_binary to override
        envs.append(_ENV_SET_IFF_NOT_SET.format(
            var = "JS_BINARY__PATCH_NODE_FS",
            quoted_value = _bash_quote("1"),
        ))

    if ctx.attr.expected_exit_code:
        envs.append(_ENV_SET.format(
            var = "JS_BINARY__EXPECTED_EXIT_CODE",
            quoted_value = _bash_quote(str(ctx.attr.expected_exit_code)),
        ))

    if ctx.attr.copy_data_to_bin:
        # Set an environment variable to flag that we have copied js_binary data to bin
        envs.append(_ENV_SET.format(var = "JS_BINARY__COPY_DATA_TO_BIN", quoted_value = _bash_quote("1")))

    if ctx.attr.chdir:
        # Set chdir env if not already set to allow js_run_binary to override
        chdir_value = _expand_env_if_needed(ctx, ctx.attr.chdir)

        # Normalize workspace-relative chdir for external repositories to avoid requiring
        # callers to manually prefix with "external/<repo>/".
        if (
            ctx.label.repo_name and
            not (chdir_value.startswith("external/") or chdir_value.startswith("/")) and
            not chdir_value.startswith("@")
        ):
            if chdir_value == ".":
                normalized_chdir = "external/{}".format(ctx.label.repo_name)
            else:
                normalized_chdir = "external/{}/{}".format(ctx.label.repo_name, chdir_value)
        else:
            normalized_chdir = chdir_value

        envs.append(_ENV_SET_IFF_NOT_SET.format(var = "JS_BINARY__CHDIR", quoted_value = _bash_quote(normalized_chdir)))

    # Set log envs iff not already set to allow js_run_binary to override
    for env in envs_for_log_level(ctx.attr.log_level):
        envs.append(_ENV_SET_IFF_NOT_SET.format(var = env, quoted_value = _bash_quote("1")))

    node_options = []
    for node_option in ctx.attr.node_options:
        node_options.append(_NODE_OPTION.format(value = _expand_env_if_needed(ctx, node_option)))
    if ctx.attr.preserve_symlinks_main and "--preserve-symlinks-main" not in node_options:
        node_options.append(_NODE_OPTION.format(value = "--preserve-symlinks-main"))

    node_wrapper = ctx.file._node_wrapper_bat if is_windows else ctx.file._node_wrapper_sh
    toolchain_files = [node_wrapper]

    npm_path = ""
    npm_wrapper_path = ""
    if ctx.attr.include_npm:
        npm_path = nodeinfo.npm.short_path if nodeinfo.npm else nodeinfo.npm_path
        npm_wrapper = ctx.file._npm_wrapper_bat if is_windows else ctx.file._npm_wrapper_sh
        npm_wrapper_path = npm_wrapper.short_path
        toolchain_files.append(npm_wrapper)

    node_path = nodeinfo.node.short_path if nodeinfo.node else nodeinfo.node_path

    if _generates_coverage_report(ctx):
        envs.append(_ENV_SET.format(
            var = "JS_BINARY__COVERAGE_REPORT",
            quoted_value = _bash_quote("/".join([ctx.workspace_name, ctx.file._coverage_report.short_path])),
        ))

    launcher_subst = {
        "{{target_label}}": str(ctx.label),
        "{{template_label}}": str(ctx.attr._launcher_template.label),
        "{{entry_point_label}}": str(ctx.attr.entry_point.label),
        "{{entry_point_path}}": entry_point_path,
        "{{envs}}": "\n".join(envs),
        "{{fixed_args}}": " ".join(fixed_args),
        "{{initialize_runfiles}}": BASH_INITIALIZE_RUNFILES,
        "{{log_prefix_rule_set}}": log_prefix_rule_set,
        "{{log_prefix_rule}}": log_prefix_rule,
        "{{node_options}}": "\n".join(node_options),
        "{{node_patches}}": ctx.file._node_patches.short_path,
        "{{node_patches_rlocation}}": to_rlocation_path(ctx, ctx.file._node_patches),
        "{{node_wrapper}}": node_wrapper.short_path,
        "{{node}}": node_path,
        "{{npm}}": npm_path,
        "{{npm_wrapper}}": npm_wrapper_path,
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

    return launcher, toolchain_files

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
        entry_point_rlocation = "/".join([
            to_rlocation_path(ctx, entry_point),
            ctx.attr.entry_point[DirectoryPathInfo].path,
        ])
    else:
        if len(ctx.files.entry_point) != 1:
            fail("entry_point must be a single file or a target that provides a DirectoryPathInfo")
        entry_point = ctx.files.entry_point[0]
        entry_point_path = entry_point.short_path
        entry_point_rlocation = to_rlocation_path(ctx, entry_point)

    # Expanded here rather than in _bash_launcher so that the hermetic launcher embeds
    # the same arguments the script would have run with, not the unexpanded spelling.
    if ctx.attr.expand_args:
        fixed_args = [expand_variables(ctx, expand_locations(ctx, fixed_arg, ctx.attr.data)) for fixed_arg in fixed_args]

    bash_launcher, toolchain_files = _bash_launcher(ctx, nodeinfo, entry_point_path, log_prefix_rule_set, log_prefix_rule, fixed_args, fixed_env, is_windows)
    launcher = create_windows_native_launcher_script(ctx, bash_launcher) if is_windows else bash_launcher

    launcher_files = [bash_launcher]
    launcher_files.extend(toolchain_files)
    if nodeinfo.node:
        launcher_files.append(nodeinfo.node)

    launcher_files.extend(ctx.files._node_patches_files + [ctx.file._node_patches])

    # Neither the hermetic launcher nor its preload goes into runfiles: the launcher is
    # not built unless its output group is requested, and whoever requests it is
    # responsible for putting launcher.cjs in the runfiles the launcher will resolve
    # against. Carrying the preload here instead would put it in every js_binary's
    # runfiles, and into every container image built from one, for the benefit of the
    # few that use it.
    fixed_arg_specs, fixed_arg_blockers = _classify_fixed_args(fixed_args)
    blockers = _hermetic_launcher_blockers(ctx, fixed_arg_blockers, fixed_env, is_windows)
    hermetic_launcher = _hermetic_launcher(ctx, nodeinfo, entry_point_rlocation, fixed_arg_specs, blockers, is_windows)

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
        # Deliberately not in runfiles: nothing builds this unless it is requested
        # through the output group of the same name.
        hermetic_launcher = hermetic_launcher,
        hermetic_launcher_blockers = blockers,
    )

def _hermetic_launcher_report(ctx, launcher):
    """A one-line verdict on this target's hermetic launcher, for the output group."""
    if launcher.hermetic_launcher:
        verdict = "eligible"
    elif launcher.hermetic_launcher_blockers:
        verdict = "blocked: {}".format(",".join(launcher.hermetic_launcher_blockers))
    else:
        # No blocker but no launcher either: hermetic_launcher publishes no stub for
        # this platform, or an embedded argument was too long for one.
        verdict = "unavailable"
    report = ctx.actions.declare_file("{}_/hermetic_launcher_report.txt".format(ctx.label.name))
    ctx.actions.write(report, "{} {}\n".format(ctx.label, verdict))
    return report

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
        # report, so both must be in the test's runfiles. See #2901.
        if _generates_coverage_report(ctx):
            runfiles = runfiles.merge(ctx.runfiles(files = [
                ctx.file._coverage_bootstrap,
                ctx.file._coverage_report,
            ]))

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
            # A launcher binary that runs the entry point on a patched node, in place of
            # the bash launcher script. Not used by `bazel run` and not in runfiles, so
            # it only gets stamped when explicitly requested. Empty on platforms
            # hermetic_launcher publishes no stub for.
            hermetic_launcher = depset(
                [launcher.hermetic_launcher] if launcher.hermetic_launcher else [],
            ),
            # Why this target has no hermetic launcher, for
            # `bazel build --output_groups=hermetic_launcher_report //...` to collect
            # into a picture of what is blocking adoption. Written only on request.
            hermetic_launcher_report = depset([_hermetic_launcher_report(ctx, launcher)]),
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
        "@rules_nodejs//nodejs:runtime_toolchain_type",
        # Optional: only needed to stamp the hermetic_launcher output group, and
        # hermetic_launcher publishes no stub for some platforms rules_js supports
        # (linux ppc64le, windows arm64). Requiring these would stop js_binary from
        # building there at all.
        config_common.toolchain_type(_FINALIZER_TOOLCHAIN_TYPE, mandatory = False),
        config_common.toolchain_type(_TEMPLATE_TOOLCHAIN_TYPE, mandatory = False),
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
