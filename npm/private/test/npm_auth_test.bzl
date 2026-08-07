"""Unit tests for npm auth
See https://docs.bazel.build/versions/main/skylark/testing.html#for-testing-starlark-utilities
"""

load("@bazel_skylib//lib:partial.bzl", "partial")
load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")
load("//npm/private:npm_translate_lock_helpers.bzl", "helpers", "helpers_testonly")

def _no_npmrc_test_impl(ctx):
    env = unittest.begin(ctx)

    asserts.equals(
        env,
        ({}, {}),
        helpers.get_npm_auth(
            {},
            "",
            {},
        ),
    )

    return unittest.end(env)

def _plain_text_token_test_impl(ctx):
    env = unittest.begin(ctx)

    asserts.equals(
        env,
        (
            {},
            {
                "registry1": {
                    "bearer": "TOKEN1",
                },
            },
        ),
        helpers.get_npm_auth(
            {
                "//registry1/:_authToken": "TOKEN1",
            },
            "",
            {},
        ),
    )

    asserts.equals(
        env,
        (
            {},
            {
                "registry1": {
                    "bearer": "TOKEN1",
                },
                "registry2": {
                    "bearer": "TOKEN2",
                },
            },
        ),
        helpers.get_npm_auth(
            {
                "//registry1/:_authToken": "TOKEN1",
                "//registry2/:_authToken": "TOKEN2",
            },
            "",
            {},
        ),
    )

    asserts.equals(
        env,
        (
            {},
            {
                "registry1": {
                    "basic": "TOKEN1",
                },
            },
        ),
        helpers.get_npm_auth(
            {
                "//registry1/:_auth": "TOKEN1",
            },
            "",
            {},
        ),
    )

    asserts.equals(
        env,
        (
            {},
            {
                "registry1": {
                    "basic": "TOKEN1",
                },
                "registry2": {
                    "basic": "TOKEN2",
                },
            },
        ),
        helpers.get_npm_auth(
            {
                "//registry1/:_auth": "TOKEN1",
                "//registry2/:_auth": "TOKEN2",
            },
            "",
            {},
        ),
    )

    return unittest.end(env)

def _plain_basic_auth_test_impl(ctx):
    env = unittest.begin(ctx)

    asserts.equals(
        env,
        (
            {},
            {
                "registry1": {
                    "basic": "dXNlcm5hbWU6aHVudGVyMg==",
                },
                "registry2": {
                    "basic": "c29tZW9uZTpwYXNzd29yZA==",
                },
            },
        ),
        helpers.get_npm_auth(
            {
                "//registry1/:_auth": "dXNlcm5hbWU6aHVudGVyMg==",
                "//registry2/:_auth": "c29tZW9uZTpwYXNzd29yZA==",
            },
            "",
            {},
        ),
    )

    return unittest.end(env)

def _plain_username_password_test_impl(ctx):
    env = unittest.begin(ctx)

    asserts.equals(
        env,
        (
            {},
            {
                "registry1": {
                    "username": "username",
                    "password": "hunter2",
                },
                "registry2": {
                    "username": "someone",
                    "password": "password",
                },
            },
        ),
        helpers.get_npm_auth(
            {
                "//registry1/:username": "username",
                "//registry1/:_password": "aHVudGVyMg==",
                "//registry2/:username": "someone",
                "//registry2/:_password": "cGFzc3dvcmQ=",
            },
            "",
            {},
        ),
    )

    return unittest.end(env)

def _fake_auth_rctx(stdout = "HELPER_TOKEN\n", return_code = 0, env = {}, fail_on_execute = False):
    def _execute(_args, **_kwargs):
        if fail_on_execute:
            fail("rctx.execute should not be called")
        return struct(return_code = return_code, stdout = stdout, stderr = "")

    return struct(
        getenv = env.get,
        execute = _execute,
    )

def _is_absolute_path_test_impl(ctx):
    env = unittest.begin(ctx)

    for path in ["/abs/token-helper", "C:\\helper", "C:/helper", "\\\\net\\share\\helper"]:
        asserts.true(env, helpers.is_absolute_path(path), msg = "expected %r to be absolute" % path)

    for path in ["./relative", "relative/path", "token-helper", ""]:
        asserts.false(env, helpers.is_absolute_path(path), msg = "expected %r to be relative" % path)

    return unittest.end(env)

def _token_helper_global_test_impl(ctx):
    env = unittest.begin(ctx)

    asserts.equals(
        env,
        (
            {},
            {
                "": {
                    "bearer": "HELPER_TOKEN",
                },
            },
        ),
        helpers.get_npm_auth(
            {
                "tokenHelper": "/abs/token-helper",
            },
            "",
            _fake_auth_rctx(),
            allow_token_helper = True,
        ),
    )

    return unittest.end(env)

def _token_helper_registry_test_impl(ctx):
    env = unittest.begin(ctx)

    asserts.equals(
        env,
        (
            {},
            {
                "registry1": {
                    "bearer": "HELPER_TOKEN",
                },
            },
        ),
        helpers.get_npm_auth(
            {
                "//registry1/:tokenHelper": "/abs/token-helper",
            },
            "",
            _fake_auth_rctx(),
            allow_token_helper = True,
        ),
    )

    return unittest.end(env)

def _token_helper_env_path_test_impl(ctx):
    env = unittest.begin(ctx)

    asserts.equals(
        env,
        (
            {},
            {
                "registry1": {
                    "bearer": "HELPER_TOKEN",
                },
            },
        ),
        helpers.get_npm_auth(
            {
                "//registry1/:tokenHelper": "${HELPER}",
            },
            "",
            _fake_auth_rctx(env = {"HELPER": "/abs/token-helper"}),
            allow_token_helper = True,
        ),
    )

    return unittest.end(env)

def _token_helper_disallowed_test_impl(ctx):
    env = unittest.begin(ctx)

    asserts.equals(
        env,
        ({}, {}),
        helpers.get_npm_auth(
            {
                "//registry1/:tokenHelper": "/abs/token-helper",
            },
            "",
            _fake_auth_rctx(fail_on_execute = True),
            allow_token_helper = False,
        ),
    )

    return unittest.end(env)

def _token_helper_precedence_test_impl(ctx):
    env = unittest.begin(ctx)

    asserts.equals(
        env,
        (
            {},
            {
                "registry1": {
                    "bearer": "HELPER_TOKEN",
                },
            },
        ),
        helpers.get_npm_auth(
            {
                "//registry1/:_authToken": "STATIC",
                "//registry1/:tokenHelper": "/abs/token-helper",
            },
            "",
            _fake_auth_rctx(),
            allow_token_helper = True,
        ),
    )

    return unittest.end(env)

def _env_var_token_test_impl(ctx):
    env = unittest.begin(ctx)

    renv = {}
    rctx = struct(
        getenv = renv.get,
    )

    asserts.equals(
        env,
        (
            {},
            {
                "registry1": {
                    "bearer": "TOKEN1",
                },
            },
        ),
        helpers.get_npm_auth(
            {
                "//registry1/:_authToken": "$TOKEN1",
            },
            "",
            rctx,
        ),
    )

    renv["TOKEN1"] = "1234"
    asserts.equals(
        env,
        (
            {},
            {
                "registry1": {
                    "bearer": "1234",
                },
            },
        ),
        helpers.get_npm_auth(
            {
                "//registry1/:_authToken": "$TOKEN1",
            },
            "",
            rctx,
        ),
    )

    asserts.equals(
        env,
        (
            {},
            {
                "registry1": {
                    "bearer": "1234",
                },
            },
        ),
        helpers.get_npm_auth(
            {
                "//registry1/:_authToken": "${%s}" % "TOKEN1",
            },
            "",
            rctx,
        ),
    )

    renv["TOKEN2"] = "5678"
    asserts.equals(
        env,
        (
            {},
            {
                "registry1": {
                    "bearer": "1234",
                },
                "registry2": {
                    "bearer": "5678",
                },
            },
        ),
        helpers.get_npm_auth(
            {
                "//registry1/:_authToken": "${%s}" % "TOKEN1",
                "//registry2/:_authToken": "${%s}" % "TOKEN2",
            },
            "",
            rctx,
        ),
    )
    return unittest.end(env)

def _mixed_token_test_impl(ctx):
    env = unittest.begin(ctx)
    rctx = struct(
        getenv = lambda key: ("5678" if key == "TOKEN2" else None),
    )

    asserts.equals(
        env,
        (
            {},
            {
                "registry1": {
                    "bearer": "TOKEN1",
                },
                "registry2": {
                    "bearer": "5678",
                },
                "registry3": {
                    "username": "username",
                    "password": "hunter2",
                },
                "registry4": {
                    "basic": "c29tZW9uZTpwYXNzd29yZA==",
                },
            },
        ),
        helpers.get_npm_auth(
            {
                "//registry1/:_authToken": "TOKEN1",
                "//registry2/:_authToken": "${%s}" % "TOKEN2",
                "//registry3/:username": "username",
                "//registry3/:_password": "aHVudGVyMg==",
                "//registry4/:_auth": "c29tZW9uZTpwYXNzd29yZA==",
            },
            "",
            rctx,
        ),
    )

    return unittest.end(env)

def _pkg_scope_test_impl(ctx):
    env = unittest.begin(ctx)

    asserts.equals(
        env,
        (
            {
                "@scope1": "https://registry1",
            },
            {},
        ),
        helpers.get_npm_auth(
            {
                "@scope1:registry": "https://registry1",
            },
            "",
            {},
        ),
    )

    asserts.equals(
        env,
        (
            {
                "@scope1": "https://registry1",
                "@scope2": "https://registry2",
            },
            {},
        ),
        helpers.get_npm_auth(
            {
                "@scope1:registry": "https://registry1",
                "@scope2:registry": "https://registry2",
            },
            "",
            {},
        ),
    )

    asserts.equals(
        env,
        (
            {
                "@scope1": "https://registry/scope1",
                "@scope2": "https://registry/scope2",
            },
            {},
        ),
        helpers.get_npm_auth(
            {
                "@scope1:registry": "https://registry/scope1",
                "@scope2:registry": "https://registry/scope2",
            },
            "",
            {},
        ),
    )

    asserts.equals(
        env,
        (
            {
                "@scope1": "http://registry/scope1",
                "@scope2": "https://registry/scope2",
                "@scope3": "//registry/scope3",
                "@scope4": "https://registry4.com",
            },
            {},
        ),
        helpers.get_npm_auth(
            {
                "@scope1:registry": "http://registry/scope1",
                "@scope2:registry": "https://registry/scope2",
                "@scope3:registry": "//registry/scope3",
                "@scope4:registry": "registry4.com",
            },
            "",
            {},
        ),
    )

    asserts.equals(
        env,
        (
            {
                "@scope1": "https://registry/scope1",
                "@scope2": "https://registry/scope2",
            },
            {},
        ),
        helpers.get_npm_auth(
            {
                "@scope1:registry": "https://registry/scope1",
                "@scope2:registry": "https://registry/scope2",
            },
            "",
            {},
        ),
    )

    return unittest.end(env)

def _select_npm_auth_longest_prefix_test_impl(ctx):
    env = unittest.begin(ctx)

    # A broad registry token and a narrower one for a path below it. Selection must return
    # the narrower match regardless of dict order, not the first one that happens to match.
    npm_auth = {
        "registry.corp.com": {"bearer": "BROAD"},
        "registry.corp.com/private": {"bearer": "NARROW"},
    }

    asserts.equals(
        env,
        ("NARROW", None, None, None),
        helpers_testonly.select_npm_auth("https://registry.corp.com/private/pkg/-/pkg-1.0.0.tgz", npm_auth),
    )

    # A URL that only matches the broad entry still gets the broad token.
    asserts.equals(
        env,
        ("BROAD", None, None, None),
        helpers_testonly.select_npm_auth("https://registry.corp.com/public/pkg/-/pkg-1.0.0.tgz", npm_auth),
    )

    return unittest.end(env)

no_npmrc_test = unittest.make(_no_npmrc_test_impl)
plain_basic_auth_test = unittest.make(_plain_basic_auth_test_impl)
plain_username_password_test = unittest.make(_plain_username_password_test_impl)
plain_text_token_test = unittest.make(_plain_text_token_test_impl)
env_var_token_test = unittest.make(_env_var_token_test_impl)
mixed_token_test = unittest.make(_mixed_token_test_impl)
pkg_scope_test = unittest.make(_pkg_scope_test_impl)
is_absolute_path_test = unittest.make(_is_absolute_path_test_impl)
token_helper_global_test = unittest.make(_token_helper_global_test_impl)
token_helper_registry_test = unittest.make(_token_helper_registry_test_impl)
token_helper_env_path_test = unittest.make(_token_helper_env_path_test_impl)
token_helper_disallowed_test = unittest.make(_token_helper_disallowed_test_impl)
token_helper_precedence_test = unittest.make(_token_helper_precedence_test_impl)
select_npm_auth_longest_prefix_test = unittest.make(_select_npm_auth_longest_prefix_test_impl)

def npm_auth_test_suite():
    unittest.suite(
        "npm_auth_tests",
        partial.make(no_npmrc_test, timeout = "short"),
        partial.make(plain_text_token_test, timeout = "short"),
        partial.make(plain_basic_auth_test, timeout = "short"),
        partial.make(plain_username_password_test, timeout = "short"),
        partial.make(env_var_token_test, timeout = "short"),
        partial.make(mixed_token_test, timeout = "short"),
        partial.make(pkg_scope_test, timeout = "short"),
        partial.make(is_absolute_path_test, timeout = "short"),
        partial.make(token_helper_global_test, timeout = "short"),
        partial.make(token_helper_registry_test, timeout = "short"),
        partial.make(token_helper_env_path_test, timeout = "short"),
        partial.make(token_helper_disallowed_test, timeout = "short"),
        partial.make(token_helper_precedence_test, timeout = "short"),
        partial.make(select_npm_auth_longest_prefix_test, timeout = "short"),
    )
