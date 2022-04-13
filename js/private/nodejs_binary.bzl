"nodejs_binary and nodejs_test rules"

load("@aspect_bazel_lib//lib:paths.bzl", "BASH_RLOCATION_FUNCTION")
load("@aspect_bazel_lib//lib:windows_utils.bzl", "BATCH_RLOCATION_FUNCTION")
load("@aspect_bazel_lib//lib:copy_to_bin.bzl", "copy_file_to_bin_action", "copy_files_to_bin_actions")

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

TODO: link to rule_js nodejs_package linker design doc

This rules requires that Bazel was run with
[`--enable_runfiles`](https://docs.bazel.build/versions/main/command-line-reference.html#flag--enable_runfiles). 
"""

_ATTRS = {
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
        allow_single_file = True,
        doc = """The main script which is evaluated by node.js

        This is the module referenced by the `require.main` property in the runtime.
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
    "_runfiles_lib": attr.label(default = "@bazel_tools//tools/bash/runfiles"),
}

# Do the opposite of _to_manifest_path in
# https://github.com/bazelbuild/rules_nodejs/blob/8b5d27400db51e7027fe95ae413eeabea4856f8e/nodejs/toolchain.bzl#L50
# to get back to the short_path.
# TODO: fix toolchain so we don't have to do this
def _target_tool_short_path(path):
    return ("../" + path[len("external/"):]) if path.startswith("external/") else path

def _windows_launcher(ctx, entry_point, args):
    node_bin = ctx.toolchains["@rules_nodejs//nodejs:toolchain_type"].nodeinfo
    launcher = ctx.actions.declare_file("_%s_launcher.bat" % ctx.label.name)

    # TODO: fix windows launcher for build actions
    ctx.actions.write(
        output = launcher,
        content = r"""@echo off
SETLOCAL ENABLEEXTENSIONS
SETLOCAL ENABLEDELAYEDEXPANSION
{rlocation_function}

for %%a in ("{node}") do set "node_dir=%%~dpa"
set PATH=%node_dir%;%PATH%
set args=%*
rem Escape \ and * in args before passsing it with double quote
if defined args (
  set args=!args:\=\\\\!
  set args=!args:"=\"!
)
"{node}" "{entry_point}" "!args!"
""".format(
            rlocation_function = BATCH_RLOCATION_FUNCTION,
            node = _target_tool_short_path(node_bin.target_tool_path),
            entry_point = entry_point.short_path,
            args = " ".join(args),
        ),
        is_executable = True,
    )
    return launcher

def _bash_launcher(ctx, entry_point, args):
    bash_bin = ctx.toolchains["@bazel_tools//tools/sh:toolchain_type"].path
    node_bin = ctx.toolchains["@rules_nodejs//nodejs:toolchain_type"].nodeinfo
    launcher = ctx.actions.declare_file("_%s_launcher.sh" % ctx.label.name)

    # NB: {rlocation_function} required to set RUNFILES_DIR for build actions that
    # use this nodejs_binary as a tool where cwd is the execroot
    ctx.actions.write(
        launcher,
        """#!{bash}
{rlocation_function}
set -o pipefail -o errexit -o nounset
if [[ "${{RUNFILES_DIR:-}}" ]]; then
    node="$RUNFILES_DIR/{workspace_name}/{node}"
else
    node="{node}"
fi
if [ ! -f "$node" ]; then
    printf "\n>>>> FAIL: The node binary '$node' not found in runfiles. <<<<\n\n" >&2
    exit 1
fi
if [ ! -x "$node" ]; then
    printf "\n>>>> FAIL: The node binary '$node' is not executable. <<<<\n\n" >&2
    exit 1
fi
if [[ "${{RUNFILES_DIR:-}}" ]]; then
    entry_point="$RUNFILES_DIR/{workspace_name}/{entry_point}"
else
    entry_point="{entry_point}"
fi
if [ ! -f "$entry_point" ]; then
    printf "\n>>>> FAIL: The entry_point '$entry_point' not found in runfiles. <<<<\n\n" >&2
    exit 1
fi
"$node" "$entry_point" "$@"
""".format(
            bash = bash_bin,
            rlocation_function = BASH_RLOCATION_FUNCTION,
            node = _target_tool_short_path(node_bin.target_tool_path),
            entry_point = entry_point.short_path,
            workspace_name = ctx.workspace_name,
            args = " ".join(args),
        ),
        is_executable = True,
    )
    return launcher

def _create_launcher(ctx):
    if ctx.attr.is_windows and not ctx.attr.enable_runfiles:
        fail("need --enable_runfiles on Windows for to support rules_js")

    # Copy entry and data files that are not already in the output tree to the output tree.
    # See docstring at the top of this file for more info.
    output_entry_point = copy_file_to_bin_action(ctx, ctx.file.entry_point, is_windows = ctx.attr.is_windows)
    output_data_files = copy_files_to_bin_actions(ctx, ctx.files.data, is_windows = ctx.attr.is_windows)

    # create the launcer
    launcher = _windows_launcher(ctx, output_entry_point, ctx.attr.args) if ctx.attr.is_windows else _bash_launcher(ctx, output_entry_point, ctx.attr.args)

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

def _nodejs_binary_impl(ctx):
    launcher = _create_launcher(ctx)
    return DefaultInfo(
        executable = launcher.exe,
        runfiles = launcher.runfiles,
    )

# Expose our library as a struct so that nodejs_binary and nodejs_test can both extend it
nodejs_binary_lib = struct(
    attrs = _ATTRS,
    nodejs_binary_impl = _nodejs_binary_impl,
    toolchains = [
        # TODO: on Windows this toolchain is never referenced
        "@bazel_tools//tools/sh:toolchain_type",
        "@rules_nodejs//nodejs:toolchain_type",
    ],
)

# For stardoc to generate documentation for the rule rather than a wrapper macro
nodejs_binary = rule(
    doc = _DOC,
    implementation = nodejs_binary_lib.nodejs_binary_impl,
    attrs = nodejs_binary_lib.attrs,
    toolchains = nodejs_binary_lib.toolchains,
)
