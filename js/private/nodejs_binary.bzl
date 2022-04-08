"nodejs_binary and nodejs_test rules"

load("@aspect_bazel_lib//lib:paths.bzl", "BASH_RLOCATION_FUNCTION", "to_manifest_path")
load("@aspect_bazel_lib//lib:windows_utils.bzl", "BATCH_RLOCATION_FUNCTION")
load("@aspect_bazel_lib//lib:copy_file.bzl", "copy_file_action")

_DOC = """Execute a program in the node.js runtime.

The version of node is determined by Bazel's toolchain selection.
In the WORKSPACE you used `nodejs_register_toolchains` to provide options to Bazel.
Then Bazel selects from these options based on the requested target platform.
Use the 
[`--toolchain_resolution_debug`](https://docs.bazel.build/versions/main/command-line-reference.html#flag--toolchain_resolution_debug)
Bazel option to see more detail about the selection.

### Static linking

This rule executes node with the Global Folders set to Bazel's runfiles folder.
<https://nodejs.org/docs/latest-v16.x/api/modules.html#loading-from-the-global-folders>
describes Node's module resolution algorithm.
By setting the `NODE_PATH` variable, we supply a location for `node_modules` resolution
outside of the project's source folder.
This means that all transitive dependencies of the `data` attribute will be available at
runtime for every execution of this program.

This requires that Bazel was run with
[`--enable_runfiles`](https://docs.bazel.build/versions/main/command-line-reference.html#flag--enable_runfiles). 

In some language runtimes, this concept is called "static linking", so we use the same term
in aspect_rules_js. This is in contrast to "dynamic linking", where the program needs to
resolve a module which is declared only in the place where the program is used, generally
with a `deps` attribute at the callsite.

> Note that some libraries do not follow the semantics of Node.js module resolution,
> and instead make fixed assumptions about the `node_modules` folder existing in some
> parent directory of a source file. These libraries will need some patching to work
> under this "static linker" approach. We expect to provide more detail about how to do
> this in a future release.
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

def _strip_external(path):
    return path[len("external/"):] if path.startswith("external/") else path

def _windows_launcher(ctx, entry_point, args):
    node_bin = ctx.toolchains["@rules_nodejs//nodejs:toolchain_type"].nodeinfo
    launcher = ctx.actions.declare_file("_%s_launcher.bat" % ctx.label.name)

    ctx.actions.write(
        output = launcher,
        content = r"""@echo off
SETLOCAL ENABLEEXTENSIONS
SETLOCAL ENABLEDELAYEDEXPANSION
set RUNFILES_MANIFEST_ONLY=1
{rlocation_function}
call :rlocation "{node}" node
call :rlocation "{entry_point}" entry_point

for %%a in ("!node!") do set "node_dir=%%~dpa"
set PATH=%node_dir%;%PATH%
set args=%*
rem Escape \ and * in args before passsing it with double quote
if defined args (
  set args=!args:\=\\\\!
  set args=!args:"=\"!
)
"!node!" "!entry_point!" "!args!"
""".format(
            node = _strip_external(node_bin.target_tool_path),
            rlocation_function = BATCH_RLOCATION_FUNCTION,
            entry_point = to_manifest_path(ctx, entry_point),
            # FIXME: wire in the args to the batch script
            args = " ".join(args),
        ),
        is_executable = True,
    )
    return launcher

def _bash_launcher(ctx, entry_point, args):
    bash_bin = ctx.toolchains["@bazel_tools//tools/sh:toolchain_type"].path
    node_bin = ctx.toolchains["@rules_nodejs//nodejs:toolchain_type"].nodeinfo
    launcher = ctx.actions.declare_file("_%s_launcher.sh" % ctx.label.name)

    ctx.actions.write(
        launcher,
        """#!{bash}
{rlocation_function}
set -o pipefail -o errexit -o nounset
$(rlocation {node}) \\
$(rlocation {entry_point}) \\
$@
""".format(
            bash = bash_bin,
            rlocation_function = BASH_RLOCATION_FUNCTION,
            node = _strip_external(node_bin.target_tool_path),
            entry_point = to_manifest_path(ctx, entry_point),
            args = " ".join(args),
        ),
        is_executable = True,
    )
    return launcher

def _create_launcher(ctx, args):
    if args == None:
        args = ctx.attr.args

    # copy the entry_point to bazel-out if it is a source file
    if ctx.file.entry_point.is_source:
        entry_point = ctx.actions.declare_file(ctx.file.entry_point.basename, sibling = ctx.file.entry_point)
        copy_file_action(ctx, ctx.file.entry_point, entry_point, is_windows = ctx.attr.is_windows)
    else:
        entry_point = ctx.file.entry_point

    # create the launcer
    launcher = _windows_launcher(ctx, entry_point, args) if ctx.attr.is_windows else _bash_launcher(ctx, entry_point, args)

    all_files = ctx.files.data + ctx.files._runfiles_lib + [entry_point] + ctx.toolchains["@rules_nodejs//nodejs:toolchain_type"].nodeinfo.tool_files
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
    launcher = _create_launcher(ctx, ctx.attr.args)
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
