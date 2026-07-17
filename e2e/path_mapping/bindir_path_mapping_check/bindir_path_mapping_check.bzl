"""Test-only rule that drives a js_binary tool with a path-mapped --bazel-bindir arg.

This rule builds its --bazel-bindir argument from a File added directly to a
ctx.actions.args() object, allowing Bazel's path mapping to rewrite it
consistently across configurations.
"""

def _bazel_bindir_arg(file):
    return "--bazel-bindir=" + file.root.path

def _bindir_path_mapping_check_impl(ctx):
    output = ctx.actions.declare_file(ctx.label.name + ".ok")

    args = ctx.actions.args()

    # The only way to trigger path mapping is by passing a File directly to
    # args.add() or args.add_all(). To get ahold of the path-mapped output bin
    # directory, we have to add an output here and then derive the bin
    # directory from it in the map_each callback.
    args.add_all([output], map_each = _bazel_bindir_arg)

    # short_path never includes the bazel-out/<cfg>/bin prefix, so it needs no
    # path mapping of its own. It's also what the tool must use to locate the
    # output: js_binary's launcher cds into BAZEL_BINDIR by default, so a path
    # relative to that directory (not output.path, which is execroot-relative)
    # is what resolves correctly from the tool's cwd.
    args.add(output.short_path)

    ctx.actions.run(
        executable = ctx.executable.tool,
        arguments = [args],
        outputs = [output],
        execution_requirements = {"supports-path-mapping": "1"},
        mnemonic = "BindirPathMappingCheck",
    )

    return [DefaultInfo(files = depset([output]))]

bindir_path_mapping_check = rule(
    implementation = _bindir_path_mapping_check_impl,
    attrs = {
        "tool": attr.label(
            executable = True,
            allow_files = True,
            mandatory = True,
            cfg = "exec",
        ),
    },
)
