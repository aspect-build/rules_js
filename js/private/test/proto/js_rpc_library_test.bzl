"""Analysis tests for js_rpc_library."""

load("@bazel_skylib//lib:unittest.bzl", "analysistest", "asserts")
load("//js:rpc.bzl", "js_rpc_library")

def _cross_package_dep_fail_impl(ctx):
    env = analysistest.begin(ctx)
    asserts.expect_failure(env, "may only depend on a proto_library in the same package")
    return analysistest.end(env)

_cross_package_dep_fail_test = analysistest.make(
    _cross_package_dep_fail_impl,
    expect_failure = True,
)

def js_rpc_library_test_suite(name):
    """Creates a test suite with analysis tests for js_rpc_library.

    Args:
        name: The name of the test_suite target.
    """
    js_rpc_library(
        name = "cross_package_subject",
        deps = ["//js/private/test/proto/other_pkg:other_proto"],
        outs = ["other.js"],
        tags = ["manual"],
    )

    _cross_package_dep_fail_test(
        name = "cross_package_dep_fail_test",
        target_under_test = ":cross_package_subject",
    )

    native.test_suite(
        name = name,
        tests = [":cross_package_dep_fail_test"],
    )
