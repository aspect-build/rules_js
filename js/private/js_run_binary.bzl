"""Runs a js_binary as a build action.

This macro wraps Aspect bazel-lib's run_binary (https://github.com/aspect-build/bazel-lib/blob/main/lib/run_binary.bzl)
and adds attributes and features specific to rules_js's js_binary.

Load this with,

```starlark
load("@aspect_rules_js//js:defs.bzl", "js_run_binary")
```
"""

load("@aspect_bazel_lib//lib:run_binary.bzl", _run_binary = "run_binary")
load("@aspect_bazel_lib//lib:utils.bzl", "to_label")
load("@aspect_bazel_lib//lib:copy_to_bin.bzl", _copy_to_bin = "copy_to_bin")
load("@bazel_skylib//lib:dicts.bzl", "dicts")
load(":js_helpers.bzl", _envs_for_log_level = "envs_for_log_level")
load(":js_filegroup.bzl", _js_filegroup = "js_filegroup")
load(":js_library.bzl", _js_library = "js_library")

def js_run_binary(
        name,
        tool,
        env = {},
        srcs = [],
        outs = [],
        out_dirs = [],
        args = [],
        chdir = None,
        stdout = None,
        stderr = None,
        exit_code_out = None,
        silent_on_success = True,
        use_execroot_entry_point = True,
        copy_srcs_to_bin = True,
        include_transitive_sources = True,
        include_declarations = False,
        include_npm_linked_packages = True,
        log_level = None,
        mnemonic = "JsRunBinary",
        progress_message = None,
        execution_requirements = None,
        stamp = 0,
        patch_node_fs = True,
        allow_execroot_entry_point_with_no_copy_data_to_bin = False,
        **kwargs):
    """Wrapper around @aspect_bazel_lib `run_binary` that adds convenience attributes for using a `js_binary` tool.

    This rule does not require Bash `native.genrule`.

    The following environment variables are made available to the Node.js runtime based on available Bazel [Make variables](https://bazel.build/reference/be/make-variables#predefined_variables):

    * BAZEL_BINDIR: the WORKSPACE-relative bazel bin directory; equivalent to the `$(BINDIR)` Make variable of the `js_run_binary` target
    * BAZEL_COMPILATION_MODE: One of `fastbuild`, `dbg`, or `opt` as set by [`--compilation_mode`](https://bazel.build/docs/user-manual#compilation-mode); equivalent to `$(COMPILATION_MODE)` Make variable of the `js_run_binary` target
    * BAZEL_TARGET_CPU: the target cpu architecture; equivalent to `$(TARGET_CPU)` Make variable of the `js_run_binary` target

    The following environment variables are made available to the Node.js runtime based on the rule context:

    * BAZEL_BUILD_FILE_PATH: the WORKSPACE-relative path to the BUILD file of the bazel target being run; equivalent to `ctx.build_file_path` of the `js_run_binary` target's rule context
    * BAZEL_PACKAGE: the package of the bazel target being run; equivalent to `ctx.label.package` of the `js_run_binary` target's rule context
    * BAZEL_TARGET_NAME: the full label of the bazel target being run; a stringified version of `ctx.label` of the `js_run_binary` target's rule context
    * BAZEL_TARGET: the name of the bazel target being run; equivalent to `ctx.label.name` of the  `js_run_binary` target's rule context
    * BAZEL_WORKSPACE: the bazel workspace name; equivalent to `ctx.workspace_name` of the `js_run_binary` target's rule context

    Args:
        name: Target name

        tool: The tool to run in the action.

            Should be a `js_binary` rule. Use Aspect bazel-lib's run_binary
            (https://github.com/aspect-build/bazel-lib/blob/main/lib/run_binary.bzl)
            for other *_binary rule types.

        env: Environment variables of the action.

            Subject to `$(location)` and make variable expansion.

        srcs: Additional inputs of the action.

            These labels are available for `$(location)` expansion in `args` and `env`.

        outs: Output files generated by the action.

            These labels are available for `$(location)` expansion in `args` and `env`.

        out_dirs: Output directories generated by the action.

            These labels are _not_ available for `$(location)` expansion in `args` and `env` since
            they are not pre-declared labels created via attr.output_list(). Output directories are
            declared instead by `ctx.actions.declare_directory`.

        args: Command line arguments of the binary.

            Subject to `$(location)` and make variable expansion.

        chdir: Working directory to run the build action in.

            This overrides the chdir value if set on the `js_binary` tool target.

            By default, `js_binary` tools run in the root of the output tree. For more context on why, please read the
            aspect_rules_js README
            https://github.com/aspect-build/rules_js/tree/dbb5af0d2a9a2bb50e4cf4a96dbc582b27567155#running-nodejs-programs.

            To run in the directory containing the js_run_binary in the output tree, use
            `chdir = package_name()` (or if you're in a macro, use `native.package_name()`).

            WARNING: this will affect other paths passed to the program, either as arguments or in configuration files,
            which are workspace-relative.

            You may need `../../` segments to re-relativize such paths to the new working directory.

        stderr: set to capture the stderr of the binary to a file, which can later be used as an input to another target
            subject to the same semantics as `outs`

        stdout: set to capture the stdout of the binary to a file, which can later be used as an input to another target
            subject to the same semantics as `outs`

        exit_code_out: set to capture the exit code of the binary to a file, which can later be used as an input to another target
            subject to the same semantics as `outs`. Note that setting this will force the binary to exit 0.

            If the binary creates outputs and these are declared, they must still be created

        silent_on_success: produce no output on stdout nor stderr when program exits with status code 0.

            This makes node binaries match the expected bazel paradigm.

        use_execroot_entry_point: Use the `entry_point` script of the `js_binary` `tool` that is in the execroot output tree
            instead of the copy that is in runfiles.

            Runfiles of `tool` are all hoisted to `srcs` of the underlying `run_binary` so they are included as execroot
            inputs to the action.

            Using the entry point script that is in the execroot output tree means that there will be no conflicting
            runfiles `node_modules` in the node_modules resolution path which can confuse npm packages such as next and
            react that don't like being resolved in multiple node_modules trees. This more closely emulates the
            environment that tools such as Next.js see when they are run outside of Bazel.

            When True, the `js_binary` tool must have `copy_data_to_bin` set to True (the default) so that all data files
            needed by the binary are available in the execroot output tree. This requirement can be turned off with by
            setting `allow_execroot_entry_point_with_no_copy_data_to_bin` to True.

        copy_srcs_to_bin: When True, all srcs files are copied to the output tree that are not already there.

        include_transitive_sources: see `js_filegroup` documentation

        include_declarations: see `js_filegroup` documentation

        include_npm_linked_packages: see `js_filegroup` documentation

        log_level: Set the logging level of the `js_binary` tool.

            This overrides the log level set on the `js_binary` tool target.

        mnemonic: A one-word description of the action, for example, CppCompile or GoLink.

        progress_message: Progress message to show to the user during the build, for example,
            "Compiling foo.cc to create foo.o". The message may contain %{label}, %{input}, or
            %{output} patterns, which are substituted with label string, first input, or output's
            path, respectively. Prefer to use patterns instead of static strings, because the former
            are more efficient.

        execution_requirements: Information for scheduling the action.

            For example,

            ```
            execution_requirements = {
                "no-cache": "1",
            },
            ```

            See https://docs.bazel.build/versions/main/be/common-definitions.html#common.tags for useful keys.

        stamp: Whether to include build status files as inputs to the tool. Possible values:

            - `stamp = 0 (default)`: Never include build status files as inputs to the tool.
                This gives good build result caching.
                Most tools don't use the status files, so including them in `--stamp` builds makes those
                builds have many needless cache misses.
                (Note: this default is different from most rules with an integer-typed `stamp` attribute.)
            - `stamp = 1`: Always include build status files as inputs to the tool, even in
                [--nostamp](https://docs.bazel.build/versions/main/user-manual.html#flag--stamp) builds.
                This setting should be avoided, since it is non-deterministic.
                It potentially causes remote cache misses for the target and
                any downstream actions that depend on the result.
            - `stamp = -1`: Inclusion of build status files as inputs is controlled by the
                [--[no]stamp](https://docs.bazel.build/versions/main/user-manual.html#flag--stamp) flag.
                Stamped targets are not rebuilt unless their dependencies change.

            Default value is `0` since the majority of js_run_binary targets in a build graph typically do not use build
            status files and including them for all js_run_binary actions whenever `--stamp` is set would result in
            invalidating the entire graph and would prevent cache hits. Stamping is typically done in terminal targets
            when building release artifacts and stamp should typically be set explicitly in these targets to `-1` so it
            is enabled when the `--stamp` flag is set.

            When stamping is enabled, an additional two environment variables will be set for the action:
                - `BAZEL_STABLE_STATUS_FILE`
                - `BAZEL_VOLATILE_STATUS_FILE`

            These files can be read and parsed by the action, for example to pass some values to a bundler.

        patch_node_fs: Patch the to Node.js `fs` API (https://nodejs.org/api/fs.html) for this node program
            to prevent the program from following symlinks out of the execroot, runfiles and the sandbox.

            When enabled, `js_binary` patches the Node.js sync and async `fs` API functions `lstat`,
            `readlink`, `realpath`, `readdir` and `opendir` so that the node program being
            run cannot resolve symlinks out of the execroot and the runfiles tree. When in the sandbox,
            these patches prevent the program being run from resolving symlinks out of the sandbox.

            When disabled, node programs can leave the execroot, runfiles and sandbox by following symlinks
            which can lead to non-hermetic behavior.

        allow_execroot_entry_point_with_no_copy_data_to_bin: Turn off validation that the `js_binary` tool
            has `copy_data_to_bin` set to True when `use_execroot_entry_point` is set to True.

            See `use_execroot_entry_point` doc for more info.

        **kwargs: Additional arguments
    """

    # Friendly fail if user has specified invalid parameters
    if "data" in kwargs.keys():
        fail("Use srcs instead of data in js_run_binary: https://docs.aspect.build/rules/aspect_rules_js/docs/js_run_binary#srcs")
    if "deps" in kwargs.keys():
        fail("Use srcs instead of deps in js_run_binary: https://docs.aspect.build/rules/aspect_rules_js/docs/js_run_binary#srcs")

    extra_srcs = []

    # Hoist js provider files to DefaultInfo
    make_js_filegroup_target = (include_transitive_sources or
                                include_declarations or
                                include_npm_linked_packages)
    if make_js_filegroup_target:
        js_filegroup_name = "{}_js_filegroup".format(name)
        _js_filegroup(
            name = js_filegroup_name,
            srcs = srcs,
            include_transitive_sources = include_transitive_sources,
            include_declarations = include_declarations,
            include_npm_linked_packages = include_npm_linked_packages,
            # Always tag the target manual since we should only build it when the final target is built.
            tags = kwargs.get("tags", []) + ["manual"],
            # Always propagate the testonly attribute
            testonly = kwargs.get("testonly", False),
        )
        extra_srcs.append(":{}".format(js_filegroup_name))

    # Copy srcs to bin
    if copy_srcs_to_bin:
        copy_to_bin_name = "{}_copy_srcs_to_bin".format(name)
        _copy_to_bin(
            name = copy_to_bin_name,
            srcs = srcs,
            # Always tag the target manual since we should only build it when the final target is built.
            tags = kwargs.get("tags", []) + ["manual"],
            # Always propagate the testonly attribute
            testonly = kwargs.get("testonly", False),
        )
        extra_srcs.append(":{}".format(copy_to_bin_name))

    # Automatically add common and useful make variables to the environment for js_run_binary build targets
    fixed_env = {
        "BAZEL_BINDIR": "$(BINDIR)",
        "BAZEL_BUILD_FILE_PATH": "$(BUILD_FILE_PATH)",
        "BAZEL_COMPILATION_MODE": "$(COMPILATION_MODE)",
        "BAZEL_PACKAGE": native.package_name(),
        "BAZEL_TARGET_CPU": "$(TARGET_CPU)",
        "BAZEL_TARGET_NAME": name,
        "BAZEL_TARGET": "$(TARGET)",
        "BAZEL_WORKSPACE": "$(WORKSPACE)",
    }

    # Configure working directory to `chdir` is set
    if chdir:
        fixed_env["JS_BINARY__CHDIR"] = chdir

    # Configure capturing stdout, stderr and/or the exit code
    extra_outs = []
    if stdout:
        fixed_env["JS_BINARY__STDOUT_OUTPUT_FILE"] = "$(execpath {})".format(stdout)
        extra_outs.append(stdout)
    if stderr:
        fixed_env["JS_BINARY__STDERR_OUTPUT_FILE"] = "$(execpath {})".format(stderr)
        extra_outs.append(stderr)
    if exit_code_out:
        fixed_env["JS_BINARY__EXIT_CODE_OUTPUT_FILE"] = "$(execpath {})".format(exit_code_out)
        extra_outs.append(exit_code_out)

    # Configure silent on success
    if silent_on_success:
        fixed_env["JS_BINARY__SILENT_ON_SUCCESS"] = "1"

    # Disable node patches if requested
    if patch_node_fs:
        fixed_env["JS_BINARY__PATCH_NODE_FS"] = "1"
    else:
        # Set explicitly to "0" so disable overrides any enable in the js_binary
        fixed_env["JS_BINARY__PATCH_NODE_FS"] = "0"

    # Configure log_level if specified
    if log_level:
        for log_level_env in _envs_for_log_level(log_level):
            fixed_env[log_level_env] = "1"

    if not stdout and not stderr and not exit_code_out and (len(outs) + len(out_dirs) < 1):
        # run_binary will produce the actual error, but we want to give an additional JS-specific
        # warning message here. Note that as a macro, we can't tell the name of the rule provided
        # by the users BUILD file (e.g. for "typescript_bin.tsc(outs = [])" we'd wish to say
        # "try using tsc_binary instead")
        # buildifier: disable=print
        print("""
WARNING: {name} is not configured to produce outputs.

If this is a generated bin from package_json.bzl, consider using the *_binary or *_test variant instead.
See https://github.com/aspect-build/rules_js/tree/main/docs#using-binaries-published-to-npm
""".format(
            name = to_label(name),
        ))

    # Configure run from execroot
    if use_execroot_entry_point:
        fixed_env["JS_BINARY__USE_EXECROOT_ENTRY_POINT"] = "1"

        # hoist all runfiles to srcs when running from execroot
        js_runfiles_lib_name = "{}_runfiles_lib".format(name)
        _js_library(
            name = js_runfiles_lib_name,
            srcs = [tool],
            # Always tag the target manual since we should only build it when the final target is built.
            tags = kwargs.get("tags", []) + ["manual"],
            # Always propagate the testonly attribute
            testonly = kwargs.get("testonly", False),
        )
        js_runfiles_name = "{}_runfiles".format(name)
        native.filegroup(
            name = js_runfiles_name,
            output_group = "runfiles",
            srcs = [":{}".format(js_runfiles_lib_name)],
            # Always tag the target manual since we should only build it when the final target is built.
            tags = kwargs.get("tags", []) + ["manual"],
            # Always propagate the testonly attribute
            testonly = kwargs.get("testonly", False),
        )
        extra_srcs.append(":{}".format(js_runfiles_name))

    if allow_execroot_entry_point_with_no_copy_data_to_bin:
        fixed_env["JS_BINARY__ALLOW_EXECROOT_ENTRY_POINT_WITH_NO_COPY_DATA_TO_BIN"] = "1"

    _run_binary(
        name = name,
        tool = tool,
        env = dicts.add(fixed_env, env),
        srcs = srcs + extra_srcs,
        outs = outs + extra_outs,
        out_dirs = out_dirs,
        args = args,
        mnemonic = mnemonic,
        progress_message = progress_message,
        execution_requirements = execution_requirements,
        stamp = stamp,
        **kwargs
    )
