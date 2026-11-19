"""Unit tests for starlark_codegen_utils"""

load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")
load("//npm/private:starlark_codegen_utils.bzl", "starlark_codegen_utils")

# buildifier: disable=function-docstring
def test_identifier(ctx):
    env = unittest.begin(ctx)

    asserts.equals(env, "", starlark_codegen_utils.identifier(""))
    asserts.equals(env, "lib_sb", starlark_codegen_utils.identifier("lib/b"))
    asserts.equals(env, "at__scope__pkg____1_p2_p3", starlark_codegen_utils.identifier("at_scope_pkg__1.2.3"))
    asserts.equals(env, "_ascope_sc_afile_c_p_p_sc_o_ascope_sb_a1_p0_p0_r", starlark_codegen_utils.identifier("@scope/c@file:../c(@scope/b@1.0.0)"))

    # names that only differ in punctuation stay distinct
    ids = [starlark_codegen_utils.identifier(n) for n in ["a-b", "a_b", "a.b", "a_db", "a__b", "ab"]]
    asserts.equals(env, ["a_db", "a__b", "a_pb", "a__db", "a____b", "ab"], ids)
    asserts.equals(env, len(ids), len({id: None for id in ids}))

    return unittest.end(env)

identifier_test = unittest.make(test_identifier)

def starlark_codegen_utils_tests(name):
    unittest.suite(
        name,
        identifier_test,
    )
