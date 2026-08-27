"""Tests that the //js:silent_on_success build flag controls the js_run_binary default.

bazel-lib's `run_binary` passes `--silent-on-success` to the wrapper it spawns only when its
`silent_on_success` attribute is true, so the presence of that argument in the action's command
line tells us which value the attribute resolved to.
"""

load("@bazel_skylib//lib:unittest.bzl", "analysistest", "asserts")
load("//js:defs.bzl", "js_run_binary")

_SILENT_ON_SUCCESS_FLAG = str(Label("//js:silent_on_success"))

def _silent_on_success_test_impl(ctx):
    env = analysistest.begin(ctx)

    actions = [
        a
        for a in analysistest.target_actions(env)
        if a.mnemonic == "JsRunBinary"
    ]
    asserts.equals(env, 1, len(actions), "expected exactly one JsRunBinary action")

    if len(actions) == 1:
        asserts.equals(
            env,
            ctx.attr.expect_silent,
            "--silent-on-success" in actions[0].argv,
            "--silent-on-success should{} be passed to the action".format(
                "" if ctx.attr.expect_silent else " not",
            ),
        )

    return analysistest.end(env)

_silent_on_success_test = analysistest.make(
    _silent_on_success_test_impl,
    attrs = {
        "expect_silent": attr.bool(
            mandatory = True,
            doc = "Whether the action is expected to be run with --silent-on-success",
        ),
    },
)

_silent_on_success_flag_off_test = analysistest.make(
    _silent_on_success_test_impl,
    attrs = {
        "expect_silent": attr.bool(
            mandatory = True,
            doc = "Whether the action is expected to be run with --silent-on-success",
        ),
    },
    config_settings = {
        _SILENT_ON_SUCCESS_FLAG: False,
    },
)

def silent_on_success_test_suite(name, tool):
    """Test suite for the //js:silent_on_success build flag.

    Args:
        name: Name of the test suite
        tool: js_binary label to use as the js_run_binary tool
    """

    # Each subject leaves stdout/stderr/exit_code_out/chdir unset, since any of those would make
    # run_binary use its wrapper regardless of silent_on_success. The actions are never executed:
    # the tests only need the target analyzed.
    for suffix, silent_on_success in [
        ("flag", None),
        ("true", True),
        ("false", False),
    ]:
        js_run_binary(
            name = "{}_{}_subject".format(name, suffix),
            outs = ["{}_{}_subject.out".format(name, suffix)],
            silent_on_success = silent_on_success,
            tags = ["manual"],
            tool = tool,
        )

    # With the flag at its default of True, a target that does not set the attribute is silent.
    _silent_on_success_test(
        name = name + "_flag_default_test",
        expect_silent = True,
        target_under_test = ":{}_flag_subject".format(name),
    )

    # With the flag turned off, the same target is not silent.
    _silent_on_success_flag_off_test(
        name = name + "_flag_off_test",
        expect_silent = False,
        target_under_test = ":{}_flag_subject".format(name),
    )

    # An explicit attribute wins over the flag in both directions.
    _silent_on_success_flag_off_test(
        name = name + "_attr_true_beats_flag_test",
        expect_silent = True,
        target_under_test = ":{}_true_subject".format(name),
    )

    _silent_on_success_test(
        name = name + "_attr_false_beats_flag_test",
        expect_silent = False,
        target_under_test = ":{}_false_subject".format(name),
    )

    native.test_suite(
        name = name,
        tests = [
            ":" + name + "_flag_default_test",
            ":" + name + "_flag_off_test",
            ":" + name + "_attr_true_beats_flag_test",
            ":" + name + "_attr_false_beats_flag_test",
        ],
    )
