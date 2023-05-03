"Internal use only"

# Simple binary that call coverage.js with node toolchain
load("@aspect_bazel_lib//lib:windows_utils.bzl", "create_windows_native_launcher_script")
load("//js/private:bash.bzl", "BASH_INITIALIZE_RUNFILES")

_ATTRS = {
    "entry_point": attr.label(default = Label("//js/private/coverage:coverage.js"), allow_single_file = [".js"]),
    "_launcher_template": attr.label(
        default = Label("//js/private/coverage:coverage.sh.tpl"),
        allow_single_file = True,
    ),
}

# Do the opposite of _to_manifest_path in
# https://github.com/bazelbuild/rules_nodejs/blob/8b5d27400db51e7027fe95ae413eeabea4856f8e/nodejs/toolchain.bzl#L50
# to get back to the short_path.
# TODO: fix toolchain so we don't have to do this
def _target_tool_short_path(workspace_name, path):
    return (workspace_name + "/../" + path[len("external/"):]) if path.startswith("external/") else path

def _is_windows(nodeinfo):
    target_tool_path = nodeinfo.target_tool_path
    return target_tool_path.endswith('.exe') or target_tool_path.endswith('.cmd') or target_tool_path.endswith('.bat')

def _impl(ctx):
    node_bin = ctx.toolchains["@rules_nodejs//nodejs:toolchain_type"].nodeinfo
    is_windows = _is_windows(node_bin)

    # Create launcher
    bash_launcher = ctx.actions.declare_file("%s.sh" % ctx.label.name)
    node_path = _target_tool_short_path(ctx.workspace_name, ctx.toolchains["@rules_nodejs//nodejs:toolchain_type"].nodeinfo.target_tool_path)
    ctx.actions.expand_template(
        template = ctx.file._launcher_template,
        output = bash_launcher,
        substitutions = {
            "{{entry_point_path}}": ctx.file.entry_point.short_path,
            "{{initialize_runfiles}}": BASH_INITIALIZE_RUNFILES,
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
    implementation = _impl,
    attrs = _ATTRS,
    executable = True,
    toolchains = [
        "@bazel_tools//tools/sh:toolchain_type",
        "@rules_nodejs//nodejs:toolchain_type",
    ],
)
