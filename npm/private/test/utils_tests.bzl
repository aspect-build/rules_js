"""Unit tests for pnpm utils
See https://docs.bazel.build/versions/main/skylark/testing.html#for-testing-starlark-utilities
"""

load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")
load("//npm/private:utils.bzl", "utils", "utils_test")

# buildifier: disable=function-docstring
def test_bazel_name(ctx):
    env = unittest.begin(ctx)
    asserts.equals(
        env,
        "at_scope_pkg_21.1.0_rollup_2.70.2_at_scope_y_1.1.1",
        utils.bazel_name("@scope/pkg@21.1.0_rollup@2.70.2_@scope/y@1.1.1"),
    )
    asserts.equals(
        env,
        "at_scope_pkg_21.1.0",
        utils.bazel_name("@scope/pkg@21.1.0"),
    )
    return unittest.end(env)

# buildifier: disable=function-docstring
def test_pnpm_name(ctx):
    env = unittest.begin(ctx)
    asserts.equals(env, "@scope/y@1.1.1", utils.package_key("@scope/y", "1.1.1"))
    asserts.equals(env, "@scope+y@registry+@scope+y@1.1.1", utils.package_store_name("@scope/y", "registry/@scope/y@1.1.1"))
    asserts.equals(env, "@scope+y@1.1.1", utils.package_store_name("@scope/y", "1.1.1"))
    return unittest.end(env)

# buildifier: disable=function-docstring
def test_link_version(ctx):
    env = unittest.begin(ctx)
    asserts.equals(env, "@scope+y@0.0.0", utils.package_store_name("@scope/y", "link:foo"))
    asserts.equals(env, "@scope+y@file+bar", utils.package_store_name("@scope/y", "file:bar"))
    asserts.equals(env, "@scope+y@file+..+foo+bar", utils.package_store_name("@scope/y", "file:../foo/bar"))
    asserts.equals(env, "@scope+y@file+@foo+bar", utils.package_store_name("@scope/y", "file:@foo/bar"))
    return unittest.end(env)

def test_friendly_name(ctx):
    env = unittest.begin(ctx)
    asserts.equals(env, "@scope/y@2.1.1", utils.friendly_name("@scope/y", "2.1.1"))
    return unittest.end(env)

def test_package_store_name(ctx):
    env = unittest.begin(ctx)
    asserts.equals(env, "@scope+y@2.1.1", utils.package_store_name("@scope/y", "2.1.1"))
    return unittest.end(env)

# buildifier: disable=function-docstring
def test_parse_package_name(ctx):
    env = unittest.begin(ctx)
    asserts.equals(env, ("@scope", "package"), utils_test.parse_package_name("@scope/package"))
    asserts.equals(env, ("@scope", "package/a"), utils_test.parse_package_name("@scope/package/a"))
    asserts.equals(env, ("", "package"), utils_test.parse_package_name("package"))
    asserts.equals(env, ("", "@package"), utils_test.parse_package_name("@package"))
    return unittest.end(env)

# buildifier: disable=function-docstring
def test_npm_registry_url(ctx):
    env = unittest.begin(ctx)
    asserts.equals(
        env,
        "https://default",
        utils.npm_registry_url("a", {}, "https://default"),
    )
    asserts.equals(
        env,
        "http://default",
        utils.npm_registry_url("a", {}, "http://default"),
    )
    asserts.equals(
        env,
        "//default",
        utils.npm_registry_url("a", {}, "//default"),
    )
    asserts.equals(
        env,
        "https://default",
        utils.npm_registry_url("@a/b", {}, "https://default"),
    )
    asserts.equals(
        env,
        "https://default",
        utils.npm_registry_url("@a/b", {"@ab": "not me"}, "https://default"),
    )
    asserts.equals(
        env,
        "https://scoped-registry",
        utils.npm_registry_url("@a/b", {"@a": "https://scoped-registry"}, "https://default"),
    )
    return unittest.end(env)

# buildifier: disable=function-docstring
def test_npm_registry_download_url(ctx):
    env = unittest.begin(ctx)
    asserts.equals(
        env,
        "https://registry.npmjs.org/y/-/y-1.2.3.tgz",
        utils.npm_registry_download_url("y", "1.2.3", {}, "https://registry.npmjs.org/"),
    )
    asserts.equals(
        env,
        "http://registry.npmjs.org/y/-/y-1.2.3.tgz",
        utils.npm_registry_download_url("y", "1.2.3", {}, "http://registry.npmjs.org/"),
    )
    asserts.equals(
        env,
        "https://registry.npmjs.org/@scope/y/-/y-1.2.3.tgz",
        utils.npm_registry_download_url("@scope/y", "1.2.3", {}, "https://registry.npmjs.org/"),
    )
    asserts.equals(
        env,
        "https://registry.npmjs.org/@scope/y/-/y-1.2.3.tgz",
        utils.npm_registry_download_url("@scope/y", "1.2.3", {"@scopyy": "foobar"}, "https://registry.npmjs.org/"),
    )
    asserts.equals(
        env,
        "https://npm.pkg.github.com/@scope/y/-/y-1.2.3.tgz",
        utils.npm_registry_download_url("@scope/y", "1.2.3", {"@scope": "https://npm.pkg.github.com/"}, "https://registry.npmjs.org/"),
    )
    asserts.equals(
        env,
        "https://npm.pkg.github.com/@scope/y/-/y-1.2.3.tgz",
        utils.npm_registry_download_url("@scope/y", "1.2.3", {}, "https://npm.pkg.github.com/"),
    )
    return unittest.end(env)

# buildifier: disable=function-docstring
def test_hex_to_base64(ctx):
    given_expected = {
        "382877d089ed5e47e31d364e0dc88c163e8a8e5e8e6aeb6b537e9f77931394d89fb142f1d1d18d32536e3added79d98241048a700b1cfbce9d7167777fa8c502": "OCh30IntXkfjHTZODciMFj6Kjl6OautrU36fd5MTlNifsULx0dGNMlNuOt3tedmCQQSKcAsc+86dcWd3f6jFAg==",
        "cf78dac1faa7faafffb89023bdf584c5cc4e219db349c376a7afc93f1dc00a08fa365732dae800646f8d99aeaa665ae85596d721c424efface8d25889f07c870": "z3jawfqn+q//uJAjvfWExcxOIZ2zScN2p6/JPx3ACgj6Nlcy2ugAZG+Nma6qZlroVZbXIcQk7/rOjSWInwfIcA==",
        "bf28e5b00a825846c3b50e57ca6468d2a0f86ba9703be0193898d15ad5807203b7982408861e1f80275325dc6aa40bd06a7889c8b71166a072fc0e5fe0e5db29": "vyjlsAqCWEbDtQ5XymRo0qD4a6lwO+AZOJjRWtWAcgO3mCQIhh4fgCdTJdxqpAvQaniJyLcRZqBy/A5f4OXbKQ==",
        "a3aeb971bcc746dd0c2c9b2050745833ee09c2c7d173f1d8e357b37239db2faf59deb5bab122754d874bd54a31c473c5af1b4096375de5501bc11e3f86e14392": "o665cbzHRt0MLJsgUHRYM+4JwsfRc/HY41ezcjnbL69Z3rW6sSJ1TYdL1UoxxHPFrxtAljdd5VAbwR4/huFDkg==",
        "0f3707ebd2828c3e96e492629d6b3efcb4c03f71cb662fe4db432170a6fb622e14fb0647f5e1db307a282482ded220a2ccdfda92d6a652269e207e72c45ea5d6": "DzcH69KCjD6W5JJinWs+/LTAP3HLZi/k20MhcKb7Yi4U+wZH9eHbMHooJILe0iCizN/aktamUiaeIH5yxF6l1g==",
    }
    env = unittest.begin(ctx)
    for given, expected in given_expected.items():
        asserts.equals(
            env,
            expected,
            utils.hex_to_base64(given),
        )
    return unittest.end(env)

t1_test = unittest.make(test_bazel_name)
t2_test = unittest.make(test_pnpm_name)
t3_test = unittest.make(test_friendly_name)
t4_test = unittest.make(test_package_store_name)
t6_test = unittest.make(test_parse_package_name)
t7_test = unittest.make(test_npm_registry_download_url)
t8_test = unittest.make(test_npm_registry_url)
t9_test = unittest.make(test_link_version)
t10_test = unittest.make(test_hex_to_base64)

def utils_tests(name):
    unittest.suite(
        name,
        t1_test,
        t2_test,
        t3_test,
        t4_test,
        t6_test,
        t7_test,
        t8_test,
        t9_test,
        t10_test,
    )
