"Experiments to run eslint"

load("@aspect_bazel_lib//lib:copy_to_bin.bzl", "copy_files_to_bin_actions")

def _gather_srcs(src_lst):
    return [
        file
        for src in src_lst
        for file in src.files.to_list()
    ]

def _eslint_aspect_impl(_, ctx):
    src_files = []
    if hasattr(ctx.rule.attr, "srcs"):
        src_files.extend(copy_files_to_bin_actions(ctx, _gather_srcs(ctx.rule.attr.srcs)))

    report_out = ctx.actions.declare_file("report")
    exit_code_out = ctx.actions.declare_file("exit_code")
    ctx.actions.run(
        outputs = [report_out, exit_code_out],
        executable = ctx.executable._eslint_bin,
        inputs = src_files + ctx.files._config,
        arguments = [
            "--config",
            ctx.files._config[0].short_path,
        ] + [
            # FIXME: not just .js
            s.short_path
            for s in src_files
            if s.short_path.endswith(".js")
        ],
        env = {
            "BAZEL_BINDIR": ctx.bin_dir.path,
            "JS_BINARY__EXIT_CODE_OUTPUT_FILE": exit_code_out.path,
            "JS_BINARY__STDOUT_OUTPUT_FILE": report_out.path,
        },
    )
    return [
        DefaultInfo(files = depset([report_out])),
        OutputGroupInfo(report = depset([report_out])),
    ]

eslint = aspect(
    implementation = _eslint_aspect_impl,
    attr_aspects = [],
    attrs = {
        "_config": attr.label(default = "//:.eslintrc"),
        "_eslint_bin": attr.label(
            default = "//js/private/eslint:lint__js_binary",
            executable = True,
            cfg = "exec",
        ),
    },
)
