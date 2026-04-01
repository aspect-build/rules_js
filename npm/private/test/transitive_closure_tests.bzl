"""Unit tests for pnpm utils
See https://docs.bazel.build/versions/main/skylark/testing.html#for-testing-starlark-utilities
"""

load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")
load("//npm/private:transitive_closure.bzl", "gather_transitive_closure")

TEST_PACKAGES = {
    "@aspect-test/a@5.0.0": {
        "name": "@aspect-test/a",
        "version": "5.0.0",
        "integrity": "sha512-t/lwpVXG/jmxTotGEsmjwuihC2Lvz/Iqt63o78SI3O5XallxtFp5j2WM2M6HwkFiii9I42KdlAF8B3plZMz0Fw==",
        "dependencies": {
            "@aspect-test/b": "@aspect-test/b@5.0.0",
            "@aspect-test/c": "@aspect-test/c@1.0.0",
            "@aspect-test/d": "@aspect-test/d@2.0.0(@aspect-test/c@1.0.0)",
        },
        "optional_dependencies": {},
    },
    "@aspect-test/b@5.0.0": {
        "dependencies": {},
        "optional_dependencies": {
            "@aspect-test/c": "@aspect-test/c@2.0.0",
        },
    },
    "@aspect-test/c@1.0.0": {
        "dependencies": {},
        "optional_dependencies": {},
    },
    "@aspect-test/c@2.0.0": {
        "dependencies": {},
        "optional_dependencies": {},
    },
    "@aspect-test/d@2.0.0(@aspect-test/c@1.0.0)": {
        "dependencies": {},
        "optional_dependencies": {},
    },
}

# buildifier: disable=function-docstring
def test_walk_deps(ctx):
    env = unittest.begin(ctx)

    # Walk the example tree above
    is_circular, closure, optional_closure = gather_transitive_closure(TEST_PACKAGES, "@aspect-test/a@5.0.0")
    expected = {
        "@aspect-test/a@5.0.0": ["@aspect-test/a"],
        "@aspect-test/b@5.0.0": ["@aspect-test/b"],
        "@aspect-test/c@1.0.0": ["@aspect-test/c"],
        "@aspect-test/d@2.0.0(@aspect-test/c@1.0.0)": ["@aspect-test/d"],
    }
    asserts.equals(env, False, is_circular)
    asserts.equals(env, expected, closure)
    asserts.equals(env, {"@aspect-test/c@2.0.0": ["@aspect-test/c"]}, optional_closure)

    return unittest.end(env)

TEST_CIRCULAR_PACKAGES = {
    "@aspect-test/a@5.0.0": {
        "name": "@aspect-test/a",
        "dependencies": {
            "@aspect-test/b": "@aspect-test/b@5.0.0",
        },
        "optional_dependencies": {},
    },
    "@aspect-test/b@5.0.0": {
        "name": "@aspect-test/b",
        "dependencies": {},
        "optional_dependencies": {
            "@aspect-test/c": "@aspect-test/c@2.0.0",
        },
    },
    "@aspect-test/c@2.0.0": {
        "name": "@aspect-test/c",
        "dependencies": {
            "@aspect-test/a": "@aspect-test/a@5.0.0",  # circle via optional_dep
            "@aspect-test/d": "@aspect-test/d@2.0.0",
        },
        "optional_dependencies": {},
    },
    "@aspect-test/d@2.0.0": {
        "name": "@aspect-test/d",
        "dependencies": {
            "@aspect-test/c": "@aspect-test/c@2.0.0",  # circle via dep
        },
        "optional_dependencies": {},
    },
}

# buildifier: disable=function-docstring
def test_walk_circular_deps(ctx):
    env = unittest.begin(ctx)

    all_packages = {
        "@aspect-test/a@5.0.0": ["@aspect-test/a"],
        "@aspect-test/b@5.0.0": ["@aspect-test/b"],
        "@aspect-test/d@2.0.0": ["@aspect-test/d"],
        "@aspect-test/c@2.0.0": ["@aspect-test/c"],
    }

    # Walk the example tree above
    is_circular, closure, optional_closure = gather_transitive_closure(TEST_CIRCULAR_PACKAGES, "@aspect-test/a@5.0.0")
    asserts.equals(env, True, is_circular)
    asserts.equals(env, {"@aspect-test/a@5.0.0": ["@aspect-test/a"], "@aspect-test/b@5.0.0": ["@aspect-test/b"]}, closure)
    asserts.equals(env, {"@aspect-test/c@2.0.0": ["@aspect-test/c"], "@aspect-test/d@2.0.0": ["@aspect-test/d"]}, optional_closure)

    is_circular, closure, optional_closure = gather_transitive_closure(TEST_CIRCULAR_PACKAGES, "@aspect-test/b@5.0.0")
    asserts.equals(env, True, is_circular)
    asserts.equals(env, {"@aspect-test/b@5.0.0": ["@aspect-test/b"]}, closure)
    asserts.equals(env, {"@aspect-test/a@5.0.0": ["@aspect-test/a"], "@aspect-test/c@2.0.0": ["@aspect-test/c"], "@aspect-test/d@2.0.0": ["@aspect-test/d"]}, optional_closure)

    is_circular, closure, optional_closure = gather_transitive_closure(TEST_CIRCULAR_PACKAGES, "@aspect-test/c@2.0.0")
    asserts.equals(env, True, is_circular)
    asserts.equals(env, all_packages, closure)
    asserts.equals(env, {}, optional_closure)

    return unittest.end(env)

t0_test = unittest.make(test_walk_deps)
t1_test = unittest.make(test_walk_circular_deps)

def transitive_closure_tests(name):
    unittest.suite(name, t0_test, t1_test)
