"""A dummy pi rule for end-to-end testing of worker library"""

load("@aspect_rules_js//js:libs.bzl", "js_run_binary_action")

def _pi_impl(ctx):
    output = ctx.actions.declare_file(ctx.label.name)

    arguments = ctx.actions.args()
    arguments.use_param_file("@%s", use_always = True)
    arguments.set_param_file_format("multiline")
    arguments.add(output.short_path)

    js_run_binary_action(
        ctx,
        executable = ctx.executable.worker,
        inputs = [],
        arguments = [arguments],
        outputs = [output],
        mnemonic = "Pi",
        execution_requirements = {
            "supports-workers": "1",
            "worker-key-mnemonic": "Pi",
        },
    )

    return DefaultInfo(files = depset([output]), runfiles = ctx.runfiles([output]))

pi_rule = rule(
    implementation = _pi_impl,
    attrs = {
        "worker": attr.label(
            executable = True,
            cfg = "exec",
            default = ":worker",
        ),
    },
)
