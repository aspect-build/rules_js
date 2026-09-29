"""Runs a tool in an action whose env has no PATH."""

def _run_without_path_impl(ctx):
    ctx.actions.run(
        outputs = [ctx.outputs.out],
        executable = ctx.executable.tool,
        arguments = [ctx.outputs.out.path],
        env = {"BAZEL_BINDIR": ctx.bin_dir.path},
    )

run_without_path = rule(
    implementation = _run_without_path_impl,
    attrs = {
        "out": attr.output(mandatory = True),
        "tool": attr.label(executable = True, cfg = "exec", mandatory = True),
    },
)
