"""Runs one js_binary under both launchers and diffs the state node ends up in.

js_binary emits exactly one launcher per configuration (see `_create_launcher` in
js/private/js_binary.bzl), so the only way to get both into one `bazel test` is to build the
same target twice in two configurations that differ in //js:hermetic_launcher. That is what the
transition below does.

The comparison is relative -- it asserts the two launchers agree, not that either matches a
recorded golden -- so it is unaffected by the Bazel version, the platform, the output base, or
the other flags the CI matrix flips, and it fails on every CI leg rather than just one.
"""

load("@bazel_lib//lib:diff_test.bzl", "diff_test")
load("//js:libs.bzl", "js_binary_lib")

def _hermetic_launcher_transition_impl(settings, attr):
    # buildifier: disable=unused-variable
    _ignore = (settings)
    return {"//js:hermetic_launcher": attr.hermetic_launcher}

_hermetic_launcher_transition = transition(
    implementation = _hermetic_launcher_transition_impl,
    inputs = [],
    outputs = ["//js:hermetic_launcher"],
)

def _dump_launcher_state_impl(ctx):
    # The transition is on this rule, so it reaches the tool down a cfg = "exec" edge. The exec
    # transition resets the platform and the mirrored --host_* options but not Starlark build
    # settings, so the flag survives. If that ever stops being true both variants would quietly
    # be the bash launcher and the diff would pass for the wrong reason, so check rather than
    # assume: js_binary's launcher_js output group is non-empty exactly when the hermetic
    # launcher was selected.
    launcher_js = ctx.attr.tool[OutputGroupInfo].launcher_js.to_list()
    if ctx.attr.hermetic_launcher and not launcher_js:
        fail("{} was built without the hermetic launcher, so this test would have compared the bash launcher against itself. The //js:hermetic_launcher transition did not reach the tool.".format(ctx.attr.tool.label))
    if not ctx.attr.hermetic_launcher and launcher_js:
        fail("{} was built with the hermetic launcher but the bash launcher was requested.".format(ctx.attr.tool.label))

    out = ctx.actions.declare_file("{}.txt".format(ctx.label.name))

    js_binary_lib.run_binary_action(
        ctx = ctx,
        executable = ctx.executable.tool,
        outputs = [out],
        mnemonic = "LauncherStateDump",
        # ctx.actions.run replaces the action environment rather than extending it, so start
        # from the default one. Without it the launcher would run with no PATH at all, which no
        # real action does, and bash would silently substitute its own built-in default while
        # node would not -- a difference in the rig rather than in the launchers.
        env = dict(ctx.configuration.default_shell_env, JS_LAUNCHER_SYNC_OUT = out.path),
    )

    return [DefaultInfo(files = depset([out]))]

_dump_launcher_state = rule(
    doc = "Runs a js_binary under a chosen launcher and captures the state node starts in.",
    implementation = _dump_launcher_state_impl,
    cfg = _hermetic_launcher_transition,
    attrs = {
        "hermetic_launcher": attr.bool(
            doc = "Which launcher to build the tool with.",
            mandatory = True,
        ),
        "tool": attr.label(
            doc = "The js_binary to run. Its entry point must be dump_state.mjs.",
            mandatory = True,
            executable = True,
            cfg = "exec",
        ),
        # Still required by Bazel 7, which this repo supports.
        "_allowlist_function_transition": attr.label(
            default = "@bazel_tools//tools/allowlists/function_transition_allowlist",
        ),
    },
)

def launcher_sync_test(name, tool, **kwargs):
    """Asserts that `tool` leaves node in the same state under both launchers.

    Args:
        name: name of the resulting diff_test.
        tool: a js_binary whose entry point is dump_state.mjs.
        **kwargs: forwarded to diff_test.
    """
    _dump_launcher_state(
        name = "{}_bash".format(name),
        tool = tool,
        hermetic_launcher = False,
    )
    _dump_launcher_state(
        name = "{}_hermetic".format(name),
        tool = tool,
        hermetic_launcher = True,
    )
    diff_test(
        name = name,
        file1 = "{}_bash".format(name),
        file2 = "{}_hermetic".format(name),
        failure_message = "The bash and JavaScript js_binary launchers no longer leave a js_binary in the same state. See js/private/test/launcher_sync/BUILD.bazel and docs/hermetic_launcher.md.",
        **kwargs
    )
