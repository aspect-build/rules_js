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

def _coverage_merger_impl(ctx):
    is_windows = ctx.target_platform_has_constraint(ctx.attr._windows_constraint[platform_common.ConstraintValueInfo])
    nodeinfo = ctx.toolchains["@rules_nodejs//nodejs:toolchain_type"].nodeinfo

    # Create launcher
    bash_launcher = ctx.actions.declare_file(ctx.label.name)
    ctx.actions.expand_template(
        template = ctx.file._launcher_template,
        output = bash_launcher,
        substitutions = {
            "{{entry_point_path}}": ctx.file.entry_point.short_path,
            "{{initialize_js_binary_runfiles}}": BASH_INITIALIZE_JS_BINARY_RUNFILES,
            "{{node}}": nodeinfo.node.short_path if nodeinfo.node else nodeinfo.node_path,
            "{{workspace_name}}": ctx.workspace_name,
        },
        is_executable = True,
    )

    launcher = create_windows_native_launcher_script(ctx, bash_launcher) if is_windows else bash_launcher

    runfiles = [ctx.file.entry_point]
    if nodeinfo.node:
        runfiles.append(nodeinfo.node)

    return DefaultInfo(
        executable = launcher,
        runfiles = ctx.runfiles(files = runfiles),
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
