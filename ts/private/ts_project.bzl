"ts_project implementation"

# buildifier: disable=bzl-visibility
load("@rules_nodejs//nodejs/private:ts_project.bzl", _ts_project_lib = "ts_project")

# buildifier: disable=bzl-visibility
load("@rules_nodejs//nodejs/private:ts_validate_options.bzl", validate_lib = "lib")
load("//js:merge_deps.bzl", "merge_deps")
load("@bazel_skylib//lib:dicts.bzl", "dicts")

validate_options = rule(
    implementation = validate_lib.implementation,
    attrs = validate_lib.attrs,
)

def _run_tsc(ctx, link_workspace_root, executable = "tsc", **kwargs):
    # TODO: get name of the deps attribute from somewhere?
    (tools, env) = merge_deps(ctx, tool_attr = executable, dep_attr = "deps")
    ctx.actions.run(
        executable = ctx.executable.tsc,
        tools = [tools],
        env = env,
        **kwargs
    )

def _ts_project_impl(ctx):
    return _ts_project_lib.implementation(ctx, run_action = _run_tsc)

ts_project = rule(
    implementation = _ts_project_impl,
    attrs = dicts.add(_ts_project_lib.attrs, {"link_workspace_root": attr.bool()}),
)
