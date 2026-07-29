"""Test-only rule that drives a js_binary tool with a path-mapped --bazel-bindir arg.

This rule builds its --bazel-bindir argument from a File added directly to a
ctx.actions.args() object, allowing Bazel's path mapping to rewrite it
consistently across configurations.
"""

load("//js/private:js_binary.bzl", "js_run_binary_action")

def _bindir_path_mapping_check_impl(ctx):
    output = ctx.actions.declare_file(ctx.label.name + ".ok")

    js_run_binary_action(
        ctx = ctx,
        executable = ctx.executable.tool,
        arguments = [output.short_path],
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
