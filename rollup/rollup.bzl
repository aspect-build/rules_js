"Rollup bundler implmentation"

load("//js:merge_deps.bzl", "merge_deps")

def _impl(ctx):
    (tools, env) = merge_deps(ctx, tool_attr = "_rollup_bin", dep_attr = "deps")

    output = ctx.actions.declare_directory("output")

    args = ctx.actions.args()

    args.add_joined(["bundle", ctx.files.srcs[0]], join_with = "=")
    args.add_all(["--output.dir", output.path])

    if ctx.attr.config_file:
        args.add_all(["--config", ctx.file.config_file])

    args.add("--preserveSymlinks")

    ctx.actions.run(
        inputs = [ctx.files.srcs[0], ctx.file.config_file],
        executable = ctx.executable._rollup_bin,
        arguments = [args],
        outputs = [output],
        tools = [tools],
        env = env,
    )

    return [
        DefaultInfo(files = depset([output])),
    ]

rollup_bundle = rule(
    implementation = _impl,
    attrs = {
        "deps": attr.label_list(),
        "srcs": attr.label_list(allow_files = True),
        "config_file": attr.label(allow_single_file = True),
        "_rollup_bin": attr.label(
            default = "//rollup:bin",
            executable = True,
            cfg = "target",
        ),
    },
)
