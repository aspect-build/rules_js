"A simple custom rule for testing js_binary used in a custom rule"

def _custom_rule_impl(ctx):
    out = ctx.actions.declare_file("{}.out".format(ctx.label.name))
    args = ctx.actions.args()
    args.add(out.short_path)
    ctx.actions.run(
        arguments = [args],
        outputs = [out],
        env = {
            "BAZEL_BINDIR": ctx.bin_dir.path,
        },
        executable = ctx.executable.tool,
        execution_requirements = ctx.attr.execution_requirements,
    )

    return DefaultInfo(
        files = depset([out]),
    )

custom_rule = rule(
    implementation = _custom_rule_impl,
    attrs = {
        "tool": attr.label(
            executable = True,
            cfg = "exec",
        ),
        "execution_requirements": attr.string_dict(),
    },
)
