"""Tests for js_helpers utility functions"""

load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")
load("//js/private:js_helpers.bzl", "expand_rlocation_refs")

def _no_rlocation_refs_test(ctx):
    env = unittest.begin(ctx)
    asserts.equals(env, "build", expand_rlocation_refs("build"))
    return unittest.end(env)

def _single_rlocation_ref_test(ctx):
    env = unittest.begin(ctx)
    asserts.equals(
        env,
        "$$RUNFILES_DIR/$(rlocationpath :rspack_config)",
        expand_rlocation_refs("$(rlocation :rspack_config)"),
    )
    return unittest.end(env)

def _rlocation_ref_with_surrounding_text_test(ctx):
    env = unittest.begin(ctx)
    asserts.equals(
        env,
        "--config=$$RUNFILES_DIR/$(rlocationpath :my_config)",
        expand_rlocation_refs("--config=$(rlocation :my_config)"),
    )
    return unittest.end(env)

def _multiple_rlocation_refs_test(ctx):
    env = unittest.begin(ctx)
    asserts.equals(
        env,
        "$$RUNFILES_DIR/$(rlocationpath :foo):$$RUNFILES_DIR/$(rlocationpath :bar)",
        expand_rlocation_refs("$(rlocation :foo):$(rlocation :bar)"),
    )
    return unittest.end(env)

def _absolute_label_rlocation_ref_test(ctx):
    env = unittest.begin(ctx)
    asserts.equals(
        env,
        "$$RUNFILES_DIR/$(rlocationpath //some/pkg:target)",
        expand_rlocation_refs("$(rlocation //some/pkg:target)"),
    )
    return unittest.end(env)

no_rlocation_refs_test = unittest.make(_no_rlocation_refs_test)
single_rlocation_ref_test = unittest.make(_single_rlocation_ref_test)
rlocation_ref_with_surrounding_text_test = unittest.make(_rlocation_ref_with_surrounding_text_test)
multiple_rlocation_refs_test = unittest.make(_multiple_rlocation_refs_test)
absolute_label_rlocation_ref_test = unittest.make(_absolute_label_rlocation_ref_test)

def js_helpers_test_suite(name):
    unittest.suite(
        name,
        no_rlocation_refs_test,
        single_rlocation_ref_test,
        rlocation_ref_with_surrounding_text_test,
        multiple_rlocation_refs_test,
        absolute_label_rlocation_ref_test,
    )
