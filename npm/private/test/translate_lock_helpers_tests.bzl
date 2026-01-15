"""Unit tests for npm_translate_lock
See https://docs.bazel.build/versions/main/skylark/testing.html#for-testing-starlark-utilities
"""

load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")
load("//npm/private:npm_translate_lock_helpers.bzl", "helpers_testonly")

# buildifier: disable=function-docstring
def test_verify_ignores_in_root(ctx):
    env = unittest.begin(ctx)
    root_package = Label("//:pnpm-lock.yaml").package
    actual = helpers_testonly.find_missing_bazel_ignores(
        root_package,
        [
            ".",
            "dir",
        ],
        "# Empty bazelignore",
    )
    expected = [
        "node_modules",
        "dir/node_modules",
    ]
    asserts.equals(env, expected, actual)

    nothing_missing = []
    asserts.equals(env, nothing_missing, helpers_testonly.find_missing_bazel_ignores(
        root_package,
        [
            ".",
            "dir",
        ],
        # Check that we're okay with leading/trailing
        """
./node_modules
dir/node_modules/
""",
    ))

    return unittest.end(env)

# buildifier: disable=function-docstring
def test_verify_ignores_in_subdir(ctx):
    env = unittest.begin(ctx)
    root_package = Label("//some/package:pnpm-lock.yaml").package
    actual = helpers_testonly.find_missing_bazel_ignores(
        root_package,
        [
            ".",
            "../../dir",
            "../other",
            "subdir",
        ],
        "# Empty bazelignore",
    )
    expected = [
        "some/package/node_modules",
        "dir/node_modules",
        "some/other/node_modules",
        "some/package/subdir/node_modules",
    ]
    asserts.equals(env, expected, actual)
    return unittest.end(env)

t0_test = unittest.make(test_verify_ignores_in_root)
t1_test = unittest.make(test_verify_ignores_in_subdir)

# buildifier: disable=function-docstring
def test_verify_gather_package_content_works_with_simple_name(ctx):
    env = unittest.begin(ctx)
    actual = helpers_testonly.gather_package_content_excludes(
        {
            "packageA": struct(patterns = ["pattern1", "pattern2"], presets = []),
        },
        "packageA",
    )
    asserts.equals(env, ["pattern1", "pattern2"], actual.patterns)
    asserts.equals(env, [], actual.presets)
    return unittest.end(env)

# buildifier: disable=function-docstring
def test_verify_gather_package_content_works_with_star_pattern(ctx):
    env = unittest.begin(ctx)
    actual = helpers_testonly.gather_package_content_excludes(
        {
            "*": struct(patterns = ["pattern1", "pattern2"], presets = ["yarn_autoclean"]),
        },
        "packageA",
    )
    asserts.equals(env, ["pattern1", "pattern2"], actual.patterns)
    asserts.equals(env, ["yarn_autoclean"], actual.presets)
    return unittest.end(env)

# buildifier: disable=function-docstring
def test_verify_gather_package_content_works_with_dict_format(ctx):
    env = unittest.begin(ctx)
    actual = helpers_testonly.gather_package_content_excludes(
        {
            "packageA": struct(patterns = ["pattern1", "pattern2"], presets = ["basic", "yarn_autoclean"]),
        },
        "packageA",
    )
    asserts.equals(env, ["pattern1", "pattern2"], actual.patterns)
    asserts.equals(env, ["basic", "yarn_autoclean"], actual.presets)
    return unittest.end(env)

t2_test = unittest.make(test_verify_gather_package_content_works_with_simple_name)
t3_test = unittest.make(test_verify_gather_package_content_works_with_star_pattern)
t4_test = unittest.make(test_verify_gather_package_content_works_with_dict_format)

def translate_lock_helpers_tests(name):
    unittest.suite(name, t0_test, t1_test, t2_test, t3_test, t4_test)
