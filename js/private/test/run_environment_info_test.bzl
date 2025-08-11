"""Tests for RunEnvironmentInfo provider in js_binary and js_test rules."""

load("@bazel_skylib//lib:unittest.bzl", "analysistest", "asserts")
load("//js:defs.bzl", "js_binary", "js_test")

def _run_environment_info_test_impl(ctx):
    env = analysistest.begin(ctx)
    target_under_test = analysistest.target_under_test(env)

    if ctx.attr.expect_no_provider:
        asserts.false(
            env,
            RunEnvironmentInfo in target_under_test,
            "RunEnvironmentInfo provider should NOT be present when no env vars are set",
        )
        return analysistest.end(env)

    asserts.true(
        env,
        RunEnvironmentInfo in target_under_test,
        "RunEnvironmentInfo provider should be present",
    )

    run_env_info = target_under_test[RunEnvironmentInfo]

    if ctx.attr.expect_environment:
        asserts.true(
            env,
            hasattr(run_env_info, "environment"),
            "environment field should exist in RunEnvironmentInfo",
        )

        for key, expected in ctx.attr.expect_environment.items():
            actual = run_env_info.environment.get(key)
            asserts.true(
                env,
                actual != None,
                "Key '{}' should exist in environment".format(key),
            )

            if "$(location" in expected:
                asserts.true(
                    env,
                    "data.json" in actual,
                    "Location should have been expanded for '{}'".format(key),
                )
            else:
                asserts.equals(env, expected, actual)

    if ctx.attr.expect_inherited:
        asserts.true(
            env,
            hasattr(run_env_info, "inherited_environment"),
            "inherited_environment field should exist in RunEnvironmentInfo",
        )
        asserts.equals(
            env,
            sorted(ctx.attr.expect_inherited),
            sorted(run_env_info.inherited_environment),
        )

    return analysistest.end(env)

run_environment_info_test = analysistest.make(
    _run_environment_info_test_impl,
    attrs = {
        "expect_environment": attr.string_dict(
            doc = "Expected environment variables and their values",
        ),
        "expect_inherited": attr.string_list(
            doc = "Expected inherited environment variable names",
        ),
        "expect_no_provider": attr.bool(
            default = False,
            doc = "If true, expect that RunEnvironmentInfo provider is NOT present",
        ),
    },
)

def run_environment_info_test_suite(name):
    """Test suite for RunEnvironmentInfo provider.

    Args:
        name: Name of the test suite
    """

    js_binary(
        name = name + "_binary_env_subject",
        entry_point = "test_env.js",
        env = {
            "BINARY_VAR": "binary_value",
            "ANOTHER_VAR": "another_value",
            "LOCATION_VAR": "$(location :data.json)",
        },
        data = [":data.json"],
        tags = ["manual"],
    )

    run_environment_info_test(
        name = name + "_binary_env_test",
        target_under_test = ":" + name + "_binary_env_subject",
        expect_environment = {
            "BINARY_VAR": "binary_value",
            "ANOTHER_VAR": "another_value",
            "LOCATION_VAR": "$(location :data.json)",
        },
        tags = ["manual"],
    )

    js_test(
        name = name + "_test_both_subject",
        entry_point = "test_env.js",
        env = {
            "TEST_VAR": "test_value",
            "EXPANDED_PATH": "$(location :data.json)",
        },
        env_inherit = ["PATH", "HOME"],
        data = [":data.json"],
        tags = ["manual"],
    )

    run_environment_info_test(
        name = name + "_test_both_test",
        target_under_test = ":" + name + "_test_both_subject",
        expect_environment = {
            "TEST_VAR": "test_value",
            "EXPANDED_PATH": "$(location :data.json)",
        },
        expect_inherited = ["PATH", "HOME"],
        tags = ["manual"],
    )

    js_test(
        name = name + "_test_inherit_only_subject",
        entry_point = "test_env.js",
        env_inherit = ["USER", "SHELL"],
        tags = ["manual"],
    )

    run_environment_info_test(
        name = name + "_test_inherit_only_test",
        target_under_test = ":" + name + "_test_inherit_only_subject",
        expect_inherited = ["USER", "SHELL"],
        tags = ["manual"],
    )

    js_binary(
        name = name + "_binary_no_env_subject",
        entry_point = "test_env.js",
        tags = ["manual"],
    )

    run_environment_info_test(
        name = name + "_binary_no_env_test",
        target_under_test = ":" + name + "_binary_no_env_subject",
        expect_no_provider = True,
        tags = ["manual"],
    )

    native.test_suite(
        name = name,
        tests = [
            ":" + name + "_binary_env_test",
            ":" + name + "_test_both_test",
            ":" + name + "_test_inherit_only_test",
            ":" + name + "_binary_no_env_test",
        ],
        tags = ["manual"],
    )
