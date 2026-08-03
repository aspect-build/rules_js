"A simple custom rule for testing js_binary used in a custom rule"

load("@aspect_rules_js//js:libs.bzl", "js_binary_lib")

def _custom_rule_impl(ctx):
    out = ctx.actions.declare_file("{}.out".format(ctx.label.name))
    args = ctx.actions.args()
    args.add(out.short_path)
    js_binary_lib.run_binary_action(
        ctx,
        arguments = [args],
        outputs = [out],
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
