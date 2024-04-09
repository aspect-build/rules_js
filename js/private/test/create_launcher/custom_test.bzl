"custom_test rule"

load("@aspect_rules_js//js:libs.bzl", "js_binary_lib", "js_lib_helpers")

def _custom_test_impl(ctx):
    fixed_args = ["--arg1", "--arg2"]
    fixed_env = {
        "ENV1": "foo",
        "ENV2": "bar",
    }

    launcher = js_binary_lib.create_launcher(
        ctx,
        log_prefix_rule_set = "aspect_rules_js",
        log_prefix_rule = "custom_test",
        fixed_args = fixed_args,
        fixed_env = fixed_env,
    )

    runfiles = ctx.runfiles(
        files = ctx.files.data,
        transitive_files = js_lib_helpers.gather_files_from_js_info(
            targets = ctx.attr.data,
            include_sources = True,
            include_transitive_sources = ctx.attr.include_transitive_sources,
            include_declarations = ctx.attr.include_declarations,
            include_transitive_declarations = ctx.attr.include_declarations,
            include_npm_sources = ctx.attr.include_npm_sources,
        ),
    ).merge(launcher.runfiles).merge_all([
        target[DefaultInfo].default_runfiles
        for target in ctx.attr.data
    ])

    return [
        DefaultInfo(
            executable = launcher.executable,
            runfiles = runfiles,
        ),
    ]

_custom_test = rule(
    attrs = js_binary_lib.attrs,
    implementation = _custom_test_impl,
    test = True,
    toolchains = js_binary_lib.toolchains,
)

def custom_test(**kwargs):
    _custom_test(
        enable_runfiles = select({
            Label("@aspect_bazel_lib//lib:enable_runfiles"): True,
            "//conditions:default": False,
        }),
        **kwargs
    )
