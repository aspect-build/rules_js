"""A js_binary tool that runs through the hermetic launcher where that is possible.

`js_run_binary` runs its tool through bazel-lib's `run_binary`, which uses the tool
target's `DefaultInfo.executable` -- the bash launcher script. Swapping in the native
launcher therefore means handing `run_binary` a different tool target, which is what
this rule is.

It also solves where the launcher finds its runfiles. The launcher resolves its
embedded rlocation paths against `$RUNFILES_DIR` or a `<executable>.runfiles` tree
adjacent to itself, and `RUNFILES_DIR` cannot be set in the action environment because
environment values are never path-mapped. Bazel materializes a runfiles tree next to
whatever a target declares as its executable, so a symlink owned by this rule gets one.
"""

def _hermetic_tool_impl(ctx):
    binary = ctx.attr.binary
    default_info = binary[DefaultInfo]

    launchers = []
    if OutputGroupInfo in binary and hasattr(binary[OutputGroupInfo], "hermetic_launcher"):
        launchers = binary[OutputGroupInfo].hermetic_launcher.to_list()

    extra_runfiles = []
    if launchers:
        target_file = launchers[0]

        # Not part of the js_binary's own runfiles, so that a target which never uses a
        # hermetic launcher does not carry it. Add it here, where it is needed.
        extra_runfiles.append(ctx.file._hermetic_bootstrap)
    else:
        # No launcher for this target: it has a blocker, or hermetic_launcher publishes
        # no stub for this platform. Fall back to the bash launcher, which is what the
        # tool would have been used as anyway.
        target_file = default_info.files_to_run.executable

    # Windows dispatches on the file extension, so the symlink has to keep the one the
    # file it points at has: the js_binary's executable there is a .bat wrapper, and a
    # copy of it named without the extension is not executable at all (CreateProcessW
    # fails with error 193, "not a valid Win32 application").
    name = ctx.label.name
    if target_file.extension:
        name += "." + target_file.extension
    executable = ctx.actions.declare_file(name)
    ctx.actions.symlink(
        output = executable,
        target_file = target_file,
        is_executable = True,
    )

    return [DefaultInfo(
        files = depset([executable]),
        executable = executable,
        runfiles = default_info.default_runfiles.merge(
            ctx.runfiles(files = extra_runfiles),
        ),
    )]

hermetic_tool = rule(
    doc = "Wraps a `js_binary` so that it runs through its hermetic launcher when it has one.",
    implementation = _hermetic_tool_impl,
    attrs = {
        "binary": attr.label(
            doc = "The `js_binary` to wrap.",
            mandatory = True,
            providers = [DefaultInfo],
        ),
        "_hermetic_bootstrap": attr.label(
            allow_single_file = True,
            default = Label("@aspect_rules_js//js/private/node-bootstrap:launcher.cjs"),
        ),
    },
    executable = True,
)
