"""Test-only rule that drives a js_binary tool with a path-mapped --bazel-bindir arg.
"""

load("@aspect_rules_js//js:libs.bzl", "js_run_binary_action")

def _bindir_path_mapping_check_impl(ctx):
    output = ctx.actions.declare_file(ctx.label.name + ".ok")

    # Baking the value of this env var (set via --action_env) into the action lets
    # test.sh force this one action to be treated as new -- without invalidating
    # Bazel's other cached state -- by passing a fresh value on each run instead of
    # running `bazel clean`.
    env = {}
    invalidate = ctx.configuration.default_shell_env.get("BINDIR_PATH_MAPPING_CHECK_INVALIDATE")
    if invalidate != None:
        env["BINDIR_PATH_MAPPING_CHECK_INVALIDATE"] = invalidate

    js_run_binary_action(
        ctx = ctx,
        executable = ctx.executable.tool,
        arguments = [output.short_path],
        outputs = [output],
        execution_requirements = {"supports-path-mapping": "1"},
        mnemonic = "BindirPathMappingCheck",
        env = env,
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
