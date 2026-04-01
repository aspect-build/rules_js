"""Unit tests for npm_package_visibility
See https://docs.bazel.build/versions/main/skylark/testing.html#for-testing-starlark-utilities
"""

load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")
load("//npm/private:npm_package_visibility.bzl", "check_package_visibility")

# Test: Default behavior - no visibility config should allow access
def test_default_allows_access(ctx):
    env = unittest.begin(ctx)
    result = check_package_visibility(
        accessing_package = "packages/app",
        package_name = "lodash",
        visibility_config = {},
    )
    asserts.equals(env, True, result)
    return unittest.end(env)

# Test: Public visibility allows all access
def test_public_visibility(ctx):
    env = unittest.begin(ctx)
    result = check_package_visibility(
        accessing_package = "packages/app",
        package_name = "lodash",
        visibility_config = {
            "lodash": ["//visibility:public"],
        },
    )
    asserts.equals(env, True, result)
    return unittest.end(env)

# Test: Package-specific visibility - matching package
def test_pkg_visibility_match(ctx):
    env = unittest.begin(ctx)
    result = check_package_visibility(
        accessing_package = "packages/app",
        package_name = "lodash",
        visibility_config = {
            "lodash": ["//packages/app:__pkg__"],
        },
    )
    asserts.equals(env, True, result)
    return unittest.end(env)

# Test: Package-specific visibility - non-matching package
def test_pkg_visibility_no_match(ctx):
    env = unittest.begin(ctx)
    result = check_package_visibility(
        accessing_package = "packages/lib",
        package_name = "lodash",
        visibility_config = {
            "lodash": ["//packages/app:__pkg__"],
        },
    )
    asserts.equals(env, False, result)
    return unittest.end(env)

# Test: Subpackage visibility - exact match
def test_subpackages_visibility_exact_match(ctx):
    env = unittest.begin(ctx)
    result = check_package_visibility(
        accessing_package = "packages/app",
        package_name = "lodash",
        visibility_config = {
            "lodash": ["//packages/app:__subpackages__"],
        },
    )
    asserts.equals(env, True, result)
    return unittest.end(env)

# Test: Subpackage visibility - subpackage match
def test_subpackages_visibility_subpackage_match(ctx):
    env = unittest.begin(ctx)
    result = check_package_visibility(
        accessing_package = "packages/app/components",
        package_name = "lodash",
        visibility_config = {
            "lodash": ["//packages/app:__subpackages__"],
        },
    )
    asserts.equals(env, True, result)
    return unittest.end(env)

# Test: Subpackage visibility - non-matching package
def test_subpackages_visibility_no_match(ctx):
    env = unittest.begin(ctx)
    result = check_package_visibility(
        accessing_package = "packages/lib",
        package_name = "lodash",
        visibility_config = {
            "lodash": ["//packages/app:__subpackages__"],
        },
    )
    asserts.equals(env, False, result)
    return unittest.end(env)

# Test: Target-specific visibility - matching package
def test_target_visibility_match(ctx):
    env = unittest.begin(ctx)
    result = check_package_visibility(
        accessing_package = "packages/app",
        package_name = "lodash",
        visibility_config = {
            "lodash": ["//packages/app:target"],
        },
    )
    asserts.equals(env, True, result)
    return unittest.end(env)

# Test: Target-specific visibility - non-matching package
def test_target_visibility_no_match(ctx):
    env = unittest.begin(ctx)
    result = check_package_visibility(
        accessing_package = "packages/lib",
        package_name = "lodash",
        visibility_config = {
            "lodash": ["//packages/app:target"],
        },
    )
    asserts.equals(env, False, result)
    return unittest.end(env)

# Test: Wildcard configuration - applies to all packages
def test_wildcard_visibility(ctx):
    env = unittest.begin(ctx)
    result = check_package_visibility(
        accessing_package = "packages/app",
        package_name = "any-package",
        visibility_config = {
            "*": ["//packages/app:__subpackages__"],
        },
    )
    asserts.equals(env, True, result)
    return unittest.end(env)

# Test: Package-specific overrides wildcard
def test_package_overrides_wildcard(ctx):
    env = unittest.begin(ctx)

    # Wildcard would deny, but specific package allows
    result = check_package_visibility(
        accessing_package = "packages/lib",
        package_name = "lodash",
        visibility_config = {
            "*": ["//packages/app:__subpackages__"],
            "lodash": ["//visibility:public"],
        },
    )
    asserts.equals(env, True, result)
    return unittest.end(env)

# Test: Multiple visibility rules - first match wins
def test_multiple_rules_first_match(ctx):
    env = unittest.begin(ctx)
    result = check_package_visibility(
        accessing_package = "packages/app",
        package_name = "lodash",
        visibility_config = {
            "lodash": [
                "//packages/lib:__pkg__",
                "//packages/app:__subpackages__",
            ],
        },
    )
    asserts.equals(env, True, result)
    return unittest.end(env)

# Test: No matching rules denies access
def test_no_matching_rules_denies(ctx):
    env = unittest.begin(ctx)
    result = check_package_visibility(
        accessing_package = "packages/other",
        package_name = "lodash",
        visibility_config = {
            "lodash": [
                "//packages/app:__pkg__",
                "//packages/lib:__pkg__",
            ],
        },
    )
    asserts.equals(env, False, result)
    return unittest.end(env)

# Test: Edge case - root package
def test_root_package_access(ctx):
    env = unittest.begin(ctx)
    result = check_package_visibility(
        accessing_package = "",
        package_name = "lodash",
        visibility_config = {
            "lodash": ["//:__subpackages__"],
        },
    )
    asserts.equals(env, True, result)
    return unittest.end(env)

# Test: Edge case - deeply nested subpackage
def test_deeply_nested_subpackage(ctx):
    env = unittest.begin(ctx)
    result = check_package_visibility(
        accessing_package = "packages/app/components/ui/button",
        package_name = "lodash",
        visibility_config = {
            "lodash": ["//packages/app:__subpackages__"],
        },
    )
    asserts.equals(env, True, result)
    return unittest.end(env)

# Create test instances
t1_test = unittest.make(test_default_allows_access)
t2_test = unittest.make(test_public_visibility)
t3_test = unittest.make(test_pkg_visibility_match)
t4_test = unittest.make(test_pkg_visibility_no_match)
t5_test = unittest.make(test_subpackages_visibility_exact_match)
t6_test = unittest.make(test_subpackages_visibility_subpackage_match)
t7_test = unittest.make(test_subpackages_visibility_no_match)
t8_test = unittest.make(test_target_visibility_match)
t9_test = unittest.make(test_target_visibility_no_match)
t10_test = unittest.make(test_wildcard_visibility)
t11_test = unittest.make(test_package_overrides_wildcard)
t12_test = unittest.make(test_multiple_rules_first_match)
t13_test = unittest.make(test_no_matching_rules_denies)
t14_test = unittest.make(test_root_package_access)
t15_test = unittest.make(test_deeply_nested_subpackage)

def npm_package_visibility_tests(name):
    unittest.suite(
        name,
        t1_test,
        t2_test,
        t3_test,
        t4_test,
        t5_test,
        t6_test,
        t7_test,
        t8_test,
        t9_test,
        t10_test,
        t11_test,
        t12_test,
        t13_test,
        t14_test,
        t15_test,
    )
