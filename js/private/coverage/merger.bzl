"Internal use only"

# Simple binary that call coverage.js with node toolchain
load("@aspect_bazel_lib//lib:windows_utils.bzl", "create_windows_native_launcher_script")
load("//js/private:bash.bzl", "BASH_INITIALIZE_JS_BINARY_RUNFILES")

_ATTRS = {
    "entry_point": attr.label(default = Label("//js/private/coverage:coverage.js"), allow_single_file = [".js"]),
    "_launcher_template": attr.label(
        default = Label("//js/private/coverage:coverage.sh.tpl"),
        allow_single_file = True,
    ),
    "_windows_constraint": attr.label(default = "@platforms//os:windows"),
}

# Do the opposite of _to_manifest_path in
# https://github.com/bazelbuild/rules_nodejs/blob/8b5d27400db51e7027fe95ae413eeabea4856f8e/nodejs/toolchain.bzl#L50
# to get back to the short_path.
# TODO(2.0): fix toolchain so we don't have to do this
def _target_tool_path_to_short_path(tool_path):
    return ("../" + tool_path[len("external/"):]) if tool_path.startswith("external/") else tool_path

def _coverage_merger_impl(ctx):
    is_windows = ctx.target_platform_has_constraint(ctx.attr._windows_constraint[platform_common.ConstraintValueInfo])
    node_bin = ctx.toolchains["@rules_nodejs//nodejs:toolchain_type"].nodeinfo

    # Create launcher
    bash_launcher = ctx.actions.declare_file(ctx.label.name)
    node_path = _target_tool_path_to_short_path(ctx.toolchains["@rules_nodejs//nodejs:toolchain_type"].nodeinfo.target_tool_path)
    ctx.actions.expand_template(
        template = ctx.file._launcher_template,
        output = bash_launcher,
        substitutions = {
            "{{entry_point_path}}": ctx.file.entry_point.short_path,
            "{{initialize_js_binary_runfiles}}": BASH_INITIALIZE_JS_BINARY_RUNFILES,
            "{{node}}": node_path,
            "{{workspace_name}}": ctx.workspace_name,
        },
        is_executable = True,
    )

    launcher = create_windows_native_launcher_script(ctx, bash_launcher) if is_windows else bash_launcher

    runfiles = ctx.runfiles(
        files = [ctx.file.entry_point] + node_bin.tool_files,
    )

    return DefaultInfo(
        executable = launcher,
        runfiles = runfiles,
    )

coverage_merger = rule(
    implementation = _coverage_merger_impl,
    attrs = _ATTRS,
    executable = True,
    toolchains = [
        "@bazel_tools//tools/sh:toolchain_type",
        "@rules_nodejs//nodejs:toolchain_type",
    ],
)
