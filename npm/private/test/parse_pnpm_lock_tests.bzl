"Unit tests for pnpm lock file parsing logic"

load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")
load("//npm/private:pnpm.bzl", "pnpm", "pnpm_test")

def _parse_empty_lock_test_impl(ctx):
    env = unittest.begin(ctx)

    parsed_json_a = pnpm.parse_pnpm_lock_json("")
    parsed_json_b = pnpm.parse_pnpm_lock_json("{}")
    expected = ({}, {}, {}, None)

    asserts.equals(env, expected, parsed_json_a)
    asserts.equals(env, expected, parsed_json_b)

    return unittest.end(env)

# buildifier: disable=function-docstring
def _test_strip_peer_dep_or_patched_version(ctx):
    env = unittest.begin(ctx)
    asserts.equals(
        env,
        "21.1.0",
        pnpm_test.v5_strip_peer_dep_or_patched_version("21.1.0_rollup@2.70.2_x@1.1.1"),
    )
    asserts.equals(env, "1.0.0", pnpm_test.v5_strip_peer_dep_or_patched_version("1.0.0_o3deharooos255qt5xdujc3cuq"))
    asserts.equals(env, "21.1.0", pnpm_test.v5_strip_peer_dep_or_patched_version("21.1.0"))
    return unittest.end(env)

# buildifier: disable=function-docstring
def _test_version_supported(ctx):
    env = unittest.begin(ctx)

    # Unsupported versions + msgs
    msg = pnpm.assert_lockfile_version(5.3, testonly = True)
    asserts.equals(env, "npm_translate_lock requires lock_version at least 5.4, but found 5.3. Please upgrade to pnpm v7 or greater.", msg)
    msg = pnpm.assert_lockfile_version(1.2, testonly = True)
    asserts.equals(env, "npm_translate_lock requires lock_version at least 5.4, but found 1.2. Please upgrade to pnpm v7 or greater.", msg)
    msg = pnpm.assert_lockfile_version(99.99, testonly = True)
    asserts.equals(env, "npm_translate_lock currently supports a maximum lock_version of 9.0, but found 99.99. Please file an issue on rules_js", msg)

    # supported versions
    pnpm.assert_lockfile_version(5.4)
    pnpm.assert_lockfile_version(6.0)
    pnpm.assert_lockfile_version(6.1)
    pnpm.assert_lockfile_version(9.0)

    return unittest.end(env)

def _test_v5_package_key_to_name_version(ctx):
    env = unittest.begin(ctx)

    n, v = pnpm_test.v5_package_key_to_name_version("/@aspect-test/a/5.0.0")
    asserts.equals(env, "@aspect-test/a", n)
    asserts.equals(env, "5.0.0", v)

    n, v = pnpm_test.v5_package_key_to_name_version("/@aspect-test/a/5.0.0_@aspect-test/c@1.0.0")
    asserts.equals(env, "@aspect-test/a", n)
    asserts.equals(env, "5.0.0", v)

    return unittest.end(env)

def _test_v6_package_key_to_name_version(ctx):
    env = unittest.begin(ctx)

    n, v = pnpm_test.v6_package_key_to_name_version("/@aspect-test/a@5.0.0")
    asserts.equals(env, "@aspect-test/a", n)
    asserts.equals(env, "5.0.0", v)

    n, v = pnpm_test.v6_package_key_to_name_version("/@aspect-test/a@5.0.0(@aspect-test/c@1.0.0)")
    asserts.equals(env, "@aspect-test/a", n)
    asserts.equals(env, "5.0.0", v)

    return unittest.end(env)

a_test = unittest.make(_parse_empty_lock_test_impl, attrs = {})
e_test = unittest.make(_test_version_supported, attrs = {})
f_test = unittest.make(_test_strip_peer_dep_or_patched_version, attrs = {})
g_test = unittest.make(_test_v5_package_key_to_name_version, attrs = {})
h_test = unittest.make(_test_v6_package_key_to_name_version, attrs = {})

TESTS = [
    a_test,
    e_test,
    f_test,
    g_test,
    h_test,
]

def parse_pnpm_lock_tests(name):
    for index, test_rule in enumerate(TESTS):
        test_rule(name = "{}_test_{}".format(name, index))
