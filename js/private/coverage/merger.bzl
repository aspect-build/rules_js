"Internal use only"

# Publishes the lcov report generated in the test action; see coverage.js and #2901.
load("@bazel_lib//lib:windows_utils.bzl", "create_windows_native_launcher_script")

_ATTRS = {
    # Test-only: bash appended after the report is published, with COVERAGE_DIR and
    # COVERAGE_OUTPUT_FILE set. See //js/private/test/coverage.
    "merge_assertions": attr.string(),
    "_launcher_template": attr.label(
        default = Label("//js/private/coverage:coverage.sh.tpl"),
        allow_single_file = True,
    ),
    "_windows_constraint": attr.label(default = "@platforms//os:windows"),
}

def _coverage_merger_impl(ctx):
    is_windows = ctx.target_platform_has_constraint(ctx.attr._windows_constraint[platform_common.ConstraintValueInfo])

    # The '_' avoids collisions with another file matching the label name.
    # For example, test and test/my.spec.ts. This naming scheme is borrowed from rules_go:
    # https://github.com/bazelbuild/rules_go/blob/f3cc8a2d670c7ccd5f45434ab226b25a76d44de1/go/private/context.bzl#L144
    bash_launcher = ctx.actions.declare_file("{}_/{}".format(ctx.label.name, ctx.label.name))
    ctx.actions.expand_template(
        template = ctx.file._launcher_template,
        output = bash_launcher,
        substitutions = {
            # The '#' is part of the placeholder; see coverage.sh.tpl.
            "#{{merge_assertions}}": ctx.attr.merge_assertions,
        },
        is_executable = True,
    )

    launcher = create_windows_native_launcher_script(ctx, bash_launcher) if is_windows else bash_launcher

    # The .bat launcher resolves the bash script through its own runfiles.
    runfiles = [bash_launcher] if is_windows else []

    return DefaultInfo(
        executable = launcher,
        runfiles = ctx.runfiles(files = runfiles),
    )

coverage_merger = rule(
    implementation = _coverage_merger_impl,
    attrs = _ATTRS,
    executable = True,
    toolchains = [
        # Optional: only referenced on Windows, to wrap the bash script in a .bat launcher.
        config_common.toolchain_type("@bazel_tools//tools/sh:toolchain_type", mandatory = False),
    ],
)
