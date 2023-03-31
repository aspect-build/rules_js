"Internal use only"

# Simple binary that call coverage.js with node toolchain
load("@aspect_bazel_lib//lib:windows_utils.bzl", "create_windows_native_launcher_script")
load("//js/private:bash.bzl", "BASH_INITIALIZE_RUNFILES")

_ATTRS = {
    "entry_point": attr.label(default = Label("//js/private/coverage:coverage.js"), allow_single_file = [".js"]),
    "is_windows_host": attr.bool(
        mandatory = True,
        doc = """Whether running on windows or not.

        Typical usage of this rule is via a macro which automatically sets this
        attribute based on a `config_setting` rule.
        """,
    ),
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

def _impl(ctx):
    is_windows = ctx.attr.is_windows_host
    node_bin = ctx.toolchains["@rules_nodejs//nodejs:toolchain_type"].nodeinfo

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

_coverage_merger = rule(
    implementation = _impl,
    attrs = _ATTRS,
    executable = True,
    toolchains = [
        "@bazel_tools//tools/sh:toolchain_type",
        "@rules_nodejs//nodejs:toolchain_type",
    ],
)

def coverage_merger(**kwargs):
    _coverage_merger(
        is_windows_host = select({
            str(Label("@bazel_tools//src/conditions:host_windows")): True,
            "//conditions:default": False,
        }),
        **kwargs
    )
