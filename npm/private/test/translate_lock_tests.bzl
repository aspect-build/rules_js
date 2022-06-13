"""Unit tests for npm_translate_lock
See https://docs.bazel.build/versions/main/skylark/testing.html#for-testing-starlark-utilities
"""

load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")
load("//npm/private:npm_translate_lock.bzl", t = "npm_translate_lock_testonly")

# buildifier: disable=function-docstring
def test_verify_ignores_in_root(ctx):
    env = unittest.begin(ctx)
    rctx = struct(attr = struct(pnpm_lock = Label("//:pnpm-lock.yaml")))
    actual = t.verify_node_modules_ignored(
        rctx,
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
    asserts.equals(env, nothing_missing, t.verify_node_modules_ignored(
        rctx,
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
    rctx = struct(attr = struct(pnpm_lock = Label("//some/package:pnpm-lock.yaml")))
    actual = t.verify_node_modules_ignored(
        rctx,
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

def translate_lock_tests(name):
    unittest.suite(name, t0_test, t1_test)
