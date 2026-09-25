"""Test macro for asserting that a `fixed_arg` is rejected at analysis time."""

load("@bazel_skylib//lib:unittest.bzl", "analysistest", "asserts")
load("//js:defs.bzl", "js_binary")

def _rejected_case_impl(ctx):
    env = analysistest.begin(ctx)
    asserts.expect_failure(env, ctx.attr.want_error)
    return analysistest.end(env)

_rejected_case_test = analysistest.make(
    _rejected_case_impl,
    expect_failure = True,
    attrs = {
        "want_error": attr.string(mandatory = True),
    },
)

def rejected_case(name, fixed_args, want_error):
    """Asserts that a js_binary with these `fixed_args` fails to analyze.

    Args:
        name: Base name for the generated targets.
        fixed_args: Passed through to js_binary verbatim.
        want_error: A substring the analysis failure must contain.
    """
    js_binary(
        name = name + "_subject",
        entry_point = "all_args.mjs",
        expand_args = False,
        expand_env = False,
        fixed_args = fixed_args,
        tags = ["manual"],
    )

    _rejected_case_test(
        name = name + "_test",
        target_under_test = ":" + name + "_subject",
        want_error = want_error,
    )
