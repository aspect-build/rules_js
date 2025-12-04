"""Unit tests for npm_import dynamic auth"""

load("@bazel_skylib//lib:partial.bzl", "partial")
load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")

def _get_auth_from_url(url, npm_auth_dict):
    for registry, auth_info in npm_auth_dict.items():
        if registry in url:
            if "bearer" in auth_info:
                return {
                    url: {
                        "type": "pattern",
                        "pattern": "Bearer <password>",
                        "password": auth_info["bearer"],
                    },
                }
            elif "basic" in auth_info:
                return {
                    url: {
                        "type": "pattern",
                        "pattern": "Basic <password>",
                        "password": auth_info["basic"],
                    },
                }
            elif "username" in auth_info and "password" in auth_info:
                return {
                    url: {
                        "type": "basic",
                        "login": auth_info["username"],
                        "password": auth_info["password"],
                    },
                }
    return {}

def _no_auth_test_impl(ctx):
    env = unittest.begin(ctx)

    asserts.equals(
        env,
        {},
        _get_auth_from_url(
            "https://registry.npmjs.org/foo/-/foo-1.0.0.tgz",
            {},
        ),
    )

    return unittest.end(env)

def _bearer_token_test_impl(ctx):
    env = unittest.begin(ctx)

    url = "https://example.codeartifact.us-east-1.amazonaws.com/npm/repo/foo/-/foo-1.0.0.tgz"
    npm_auth = {
        "example.codeartifact.us-east-1.amazonaws.com": {
            "bearer": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9",
        },
    }

    asserts.equals(
        env,
        {
            url: {
                "type": "pattern",
                "pattern": "Bearer <password>",
                "password": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9",
            },
        },
        _get_auth_from_url(url, npm_auth),
    )

    return unittest.end(env)

def _basic_auth_test_impl(ctx):
    env = unittest.begin(ctx)

    url = "https://npm.pkg.github.com/@scope/package/-/package-1.0.0.tgz"
    npm_auth = {
        "npm.pkg.github.com": {
            "basic": "dXNlcm5hbWU6cGFzc3dvcmQ=",
        },
    }

    asserts.equals(
        env,
        {
            url: {
                "type": "pattern",
                "pattern": "Basic <password>",
                "password": "dXNlcm5hbWU6cGFzc3dvcmQ=",
            },
        },
        _get_auth_from_url(url, npm_auth),
    )

    return unittest.end(env)

def _username_password_test_impl(ctx):
    env = unittest.begin(ctx)

    url = "https://registry.example.com/foo/-/foo-1.0.0.tgz"
    npm_auth = {
        "registry.example.com": {
            "username": "testuser",
            "password": "testpass",
        },
    }

    asserts.equals(
        env,
        {
            url: {
                "type": "basic",
                "login": "testuser",
                "password": "testpass",
            },
        },
        _get_auth_from_url(url, npm_auth),
    )

    return unittest.end(env)

def _multiple_registries_test_impl(ctx):
    env = unittest.begin(ctx)

    npm_auth = {
        "registry1.com": {
            "bearer": "token1",
        },
        "registry2.com": {
            "bearer": "token2",
        },
    }

    url1 = "https://registry1.com/foo/-/foo-1.0.0.tgz"
    asserts.equals(
        env,
        {
            url1: {
                "type": "pattern",
                "pattern": "Bearer <password>",
                "password": "token1",
            },
        },
        _get_auth_from_url(url1, npm_auth),
    )

    url2 = "https://registry2.com/bar/-/bar-2.0.0.tgz"
    asserts.equals(
        env,
        {
            url2: {
                "type": "pattern",
                "pattern": "Bearer <password>",
                "password": "token2",
            },
        },
        _get_auth_from_url(url2, npm_auth),
    )

    url3 = "https://registry3.com/baz/-/baz-3.0.0.tgz"
    asserts.equals(
        env,
        {},
        _get_auth_from_url(url3, npm_auth),
    )

    return unittest.end(env)

no_auth_test = unittest.make(_no_auth_test_impl)
bearer_token_test = unittest.make(_bearer_token_test_impl)
basic_auth_test = unittest.make(_basic_auth_test_impl)
username_password_test = unittest.make(_username_password_test_impl)
multiple_registries_test = unittest.make(_multiple_registries_test_impl)

def npm_import_auth_test_suite():
    unittest.suite(
        "npm_import_auth_tests",
        partial.make(no_auth_test, timeout = "short"),
        partial.make(bearer_token_test, timeout = "short"),
        partial.make(basic_auth_test, timeout = "short"),
        partial.make(username_password_test, timeout = "short"),
        partial.make(multiple_registries_test, timeout = "short"),
    )
