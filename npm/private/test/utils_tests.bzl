"""Unit tests for pnpm utils
See https://docs.bazel.build/versions/main/skylark/testing.html#for-testing-starlark-utilities
"""

load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")
load("//npm/private:utils.bzl", "utils")

def test_strip_peer_dep_version(ctx):
    env = unittest.begin(ctx)
    asserts.equals(
        env,
        "21.1.0",
        utils.strip_peer_dep_version("21.1.0_rollup@2.70.2_x@1.1.1"),
    )
    asserts.equals(env, "21.1.0", utils.strip_peer_dep_version("21.1.0"))
    return unittest.end(env)

def test_bazel_name(ctx):
    env = unittest.begin(ctx)
    asserts.equals(
        env,
        "at_scope_pkgat_21.1.0_rollupat_2.70.2_at_scope_yat_1.1.1",
        utils.bazel_name("@scope/pkg@21.1.0_rollup@2.70.2_@scope/y@1.1.1"),
    )
    asserts.equals(
        env,
        "at_scope_pkgat_21.1.0",
        utils.bazel_name("@scope/pkg@21.1.0"),
    )
    return unittest.end(env)

def test_pnpm_name(ctx):
    env = unittest.begin(ctx)
    asserts.equals(env, "@scope/y/1.1.1", utils.pnpm_name("@scope/y", "1.1.1"))
    asserts.equals(env, ("@scope/y", "1.1.1"), utils.parse_pnpm_name("@scope/y/1.1.1"))
    return unittest.end(env)

def test_friendly_name(ctx):
    env = unittest.begin(ctx)
    asserts.equals(env, "@scope/y@2.1.1", utils.friendly_name("@scope/y", "2.1.1"))
    return unittest.end(env)

def test_virtual_store_name(ctx):
    env = unittest.begin(ctx)
    asserts.equals(env, "@scope+y@2.1.1", utils.virtual_store_name("@scope/y", "2.1.1"))
    return unittest.end(env)

# buildifier: disable=function-docstring
def test_version_supported(ctx):
    env = unittest.begin(ctx)
    utils.assert_lockfile_version(5.3)
    utils.assert_lockfile_version(5.4)
    msg = utils.assert_lockfile_version(1.2, testonly = True)
    asserts.equals(env, "npm_translate_lock requires lock_version at least 5.3, but found 1.2. Please upgrade to pnpm v6 or greater.", msg)
    msg = utils.assert_lockfile_version(99.99, testonly = True)
    asserts.equals(env, "npm_translate_lock currently supports a maximum lock_version of 5.4, but found 99.99. Please file an issue on rules_js", msg)
    return unittest.end(env)

t0_test = unittest.make(test_strip_peer_dep_version)
t1_test = unittest.make(test_bazel_name)
t2_test = unittest.make(test_pnpm_name)
t3_test = unittest.make(test_friendly_name)
t4_test = unittest.make(test_virtual_store_name)
t5_test = unittest.make(test_version_supported)

def utils_tests(name):
    unittest.suite(name, t0_test, t1_test, t2_test, t3_test, t4_test, t5_test)
