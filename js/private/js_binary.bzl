"""Rules for running JavaScript programs under Bazel, as tools or with `bazel run` or `bazel test`.

Load these with

```starlark
load("@aspect_rules_js//js:defs.bzl", "js_binary", "js_test")
```
"""

load("@aspect_bazel_lib//lib:paths.bzl", "BASH_RLOCATION_FUNCTION")
load("@aspect_bazel_lib//lib:windows_utils.bzl", "create_windows_native_launcher_script")
load("@aspect_bazel_lib//lib:copy_to_bin.bzl", "copy_file_to_bin_action", "copy_files_to_bin_actions")
load("@aspect_bazel_lib//lib:expand_make_vars.bzl", "expand_locations", "expand_variables")
load("@aspect_bazel_lib//lib:directory_path.bzl", "DirectoryPathInfo")

_DOC = """Execute a program in the node.js runtime.

The version of node is determined by Bazel's toolchain selection. In the WORKSPACE you used
`nodejs_register_toolchains` to provide options to Bazel. Then Bazel selects from these options
based on the requested target platform. Use the
[`--toolchain_resolution_debug`](https://docs.bazel.build/versions/main/command-line-reference.html#flag--toolchain_resolution_debug)
Bazel option to see more detail about the selection.

For node_modules resolution support and to prevent node programs for following symlinks back to the
user source tree when outside of the sandbox, this rule always copies the entry_point to the output
tree (if it is not already there) and run the programs from the entry points's runfiles location.

Data files that are not already in the output tree are also copied there so that node programs can
find them when outside of the sandbox and so that they don't follow symlinks back to the user source
tree.

TODO: link to rule_js node_package linker design doc

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
    "is_windows": attr.bool(
        mandatory = True,
        doc = """Whether the build is being performed on a Windows host platform.

        Typical usage of this rule is via a macro which automatically sets this
        attribute based on a `select()` on `@bazel_tools//src/conditions:host_windows`.
        """,
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
    "verbose": attr.bool(
        doc = """Produce verbose output.""",
    ),
    "_launcher_template": attr.label(
        default = Label("//js/private:js_binary.sh.tpl"),
        allow_single_file = True,
    ),
    "_runfiles_lib": attr.label(default = "@bazel_tools//tools/bash/runfiles"),
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

def _bash_launcher(ctx, entry_point_path, args):
    bash_bin = ctx.toolchains["@bazel_tools//tools/sh:toolchain_type"].path
    node_bin = ctx.toolchains["@rules_nodejs//nodejs:toolchain_type"].nodeinfo
    launcher = ctx.actions.declare_file("_%s_launcher.sh" % ctx.label.name)

    envs = []
    for (key, value) in ctx.attr.env.items():
        envs.append(_ENV_SET.format(
            var = key,
            value = " ".join([expand_variables(ctx, exp, attribute_name = "env") for exp in expand_locations(ctx, value, ctx.attr.data).split(" ")]),
        ))
    if ctx.attr.chdir:
        envs.append(_ENV_SET_IFF_NOT_SET.format(
            var = "JS_BINARY__CHDIR",
            value = " ".join([expand_variables(ctx, exp, attribute_name = "env") for exp in expand_locations(ctx, ctx.attr.chdir, ctx.attr.data).split(" ")]),
        ))
    if ctx.attr.expected_exit_code:
        envs.append(_ENV_SET.format(
            var = "JS_BINARY__EXPECTED_EXIT_CODE",
            value = str(ctx.attr.expected_exit_code),
        ))
    if ctx.attr.verbose:
        envs.append(_ENV_SET.format(
            var = "JS_BINARY__VERBOSE",
            value = "1",
        ))

    node_options = []
    for node_option in ctx.attr.node_options:
        node_options.append(_NODE_OPTION.format(
            value = " ".join([expand_variables(ctx, exp, attribute_name = "env") for exp in expand_locations(ctx, node_option, ctx.attr.data).split(" ")]),
        ))

    launcher_subst = {
        "{{rlocation_function}}": BASH_RLOCATION_FUNCTION,
        "{{node}}": _target_tool_short_path(node_bin.target_tool_path),
        "{{entry_point_path}}": entry_point_path,
        "{{workspace_name}}": ctx.workspace_name,
        "{{envs}}": "\n".join(envs),
        "{{node_options}}": "\n".join(node_options),
    }

    ctx.actions.expand_template(
        template = ctx.file._launcher_template,
        output = launcher,
        substitutions = launcher_subst,
        is_executable = True,
    )

    return launcher

def _create_launcher(ctx):
    if ctx.attr.is_windows and not ctx.attr.enable_runfiles:
        fail("need --enable_runfiles on Windows for to support rules_js")

    if DirectoryPathInfo in ctx.attr.entry_point:
        output_entry_point = ctx.attr.entry_point[DirectoryPathInfo].directory
        entry_point_path = "/".join([
            ctx.attr.entry_point[DirectoryPathInfo].directory.short_path,
            ctx.attr.entry_point[DirectoryPathInfo].path,
        ])
    else:
        if len(ctx.files.entry_point) != 1:
            fail("entry_point must be a single file or a target that provides a DirectoryPathInfo")

        # Copy entry and data files that are not already in the output tree to the output tree.
        # See docstring at the top of this file for more info.
        output_entry_point = copy_file_to_bin_action(ctx, ctx.files.entry_point[0], is_windows = ctx.attr.is_windows)
        entry_point_path = output_entry_point.short_path

    output_data_files = copy_files_to_bin_actions(ctx, ctx.files.data, is_windows = ctx.attr.is_windows)

    bash_launcher = _bash_launcher(ctx, entry_point_path, ctx.attr.args)
    launcher = create_windows_native_launcher_script(ctx, ctx.outputs.launcher_sh) if ctx.attr.is_windows else bash_launcher

    all_files = output_data_files + ctx.files._runfiles_lib + [output_entry_point] + ctx.toolchains["@rules_nodejs//nodejs:toolchain_type"].nodeinfo.tool_files
    runfiles = ctx.runfiles(
        files = all_files,
        transitive_files = depset(all_files),
    )
    runfiles = runfiles.merge_all([
        dep[DefaultInfo].default_runfiles
        for dep in ctx.attr.data
    ])
    return struct(
        exe = launcher,
        runfiles = runfiles,
    )

def _js_binary_impl(ctx):
    launcher = _create_launcher(ctx)
    return DefaultInfo(
        executable = launcher.exe,
        runfiles = launcher.runfiles,
    )

# Expose our library as a struct so that js_binary and js_test can both extend it
js_binary_lib = struct(
    attrs = _ATTRS,
    js_binary_impl = _js_binary_impl,
    toolchains = [
        # TODO: on Windows this toolchain is never referenced
        "@bazel_tools//tools/sh:toolchain_type",
        "@rules_nodejs//nodejs:toolchain_type",
    ],
)

js_binary = rule(
    doc = _DOC,
    implementation = js_binary_lib.js_binary_impl,
    attrs = js_binary_lib.attrs,
    executable = True,
    toolchains = js_binary_lib.toolchains,
)

js_test = rule(
    doc = "Identical to js_binary, but usable under `bazel test`.",
    implementation = js_binary_lib.js_binary_impl,
    attrs = js_binary_lib.attrs,
    test = True,
    toolchains = js_binary_lib.toolchains,
)
