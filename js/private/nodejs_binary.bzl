"nodejs_binary and nodejs_test rules"

load("@rules_nodejs//nodejs:providers.bzl", "LinkablePackageInfo")
load("@aspect_bazel_lib//lib:paths.bzl", "BASH_RLOCATION_FUNCTION", "to_manifest_path")
load("@aspect_bazel_lib//lib:windows_utils.bzl", "BATCH_RLOCATION_FUNCTION")

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

def _windows_launcher(ctx, linkable):
    node_bin = ctx.toolchains["@rules_nodejs//nodejs:toolchain_type"].nodeinfo
    launcher = ctx.actions.declare_file("_%s_launcher.bat" % ctx.label.name)

    if len(linkable):
        p = linkable[0][LinkablePackageInfo].package_name
        dots = "/".join([".."] * len(p.split("/")))
        node_path = "call :rlocation \"node_modules/{0}\" node_path\nset NODE_PATH=!node_path!/{1}".format(p, dots)
    else:
        node_path = ""

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
{node_path}
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
            entry_point = to_manifest_path(ctx, ctx.file.entry_point),
            # FIXME: wire in the args to the batch script
            args = " ".join(ctx.attr.args),
            node_path = node_path,
        ),
        is_executable = True,
    )
    return launcher

def _bash_launcher(ctx, linkable):
    bash_bin = ctx.toolchains["@bazel_tools//tools/sh:toolchain_type"].path
    node_bin = ctx.toolchains["@rules_nodejs//nodejs:toolchain_type"].nodeinfo
    launcher = ctx.actions.declare_file("_%s_launcher.sh" % ctx.label.name)

    # The working directory in a bazel binary is runfiles/my_wksp
    node_paths = ["$(pwd)/../node_modules"]
    if len(linkable):
        pkgs = [link[LinkablePackageInfo].package_name for link in linkable]
        node_paths.extend([
            "$(rlocation node_modules/{0})/{1}".format(
                p,
                "/".join([".."] * len(p.split("/"))),
            )
            for p in pkgs
        ])
    else:
        node_path = ""
    node_path = "export NODE_PATH=" + ":".join(node_paths)
    ctx.actions.write(
        launcher,
        """#!{bash}
{rlocation_function}
set -o pipefail -o errexit -o nounset
{node_path}
$(rlocation {node}) \\
$(rlocation {entry_point}) \\
{args} $@
""".format(
            bash = bash_bin,
            rlocation_function = BASH_RLOCATION_FUNCTION,
            node = _strip_external(node_bin.target_tool_path),
            entry_point = to_manifest_path(ctx, ctx.file.entry_point),
            args = " ".join(ctx.attr.args),
            node_path = node_path,
        ),
        is_executable = True,
    )
    return launcher

def _nodejs_binary_impl(ctx):
    linkable = [
        d
        for d in ctx.attr.data
        if LinkablePackageInfo in d and
           len(d[LinkablePackageInfo].files) == 1 and
           d[LinkablePackageInfo].files[0].is_directory
    ]

    # We use the root_symlinks feature of runfiles to make a node_modules directory
    # containing all our modules, but you need to have --enable_runfiles for that to
    # exist on the disk. If it doesn't we can probably do something else, like a very
    # long NODE_PATH composed of all the locations of the packages, or adapt the linker
    # to still fill in the runfiles case.
    # For now we just require it if there's more than one package to resolve
    if len(linkable) > 1 and not ctx.attr.enable_runfiles:
        fail("need --enable_runfiles for multiple node_modules to be resolved")

    launcher = _windows_launcher(ctx, linkable) if ctx.attr.is_windows else _bash_launcher(ctx, linkable)
    all_files = ctx.files.data + ctx.files._runfiles_lib + [ctx.file.entry_point] + ctx.toolchains["@rules_nodejs//nodejs:toolchain_type"].nodeinfo.tool_files
    runfiles = ctx.runfiles(
        files = all_files,
        transitive_files = depset(all_files),
    )
    for dep in ctx.attr.data:
        runfiles = runfiles.merge(dep[DefaultInfo].default_runfiles)
    return DefaultInfo(
        executable = launcher,
        runfiles = runfiles,
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
