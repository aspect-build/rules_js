"""Unit tests for npm auth
See https://docs.bazel.build/versions/main/skylark/testing.html#for-testing-starlark-utilities
"""

load("@bazel_skylib//lib:partial.bzl", "partial")
load("@bazel_skylib//lib:unittest.bzl", "analysistest", "asserts", "unittest")
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

def _fake_auth_rctx(stdout = "HELPER_TOKEN\n", stderr = "", return_code = 0, env = {}, executed = None):
    def _execute(args, **_kwargs):
        if executed != None:
            executed.append(args)
        return struct(return_code = return_code, stdout = stdout, stderr = stderr)

    def _path(p):
        # Only `.dirname` is exercised, and it is immediately str()'d, so a plain string works.
        return struct(dirname = p.rpartition("/")[0])

    return struct(
        getenv = env.get,
        execute = _execute,
        path = _path,
    )

# Resolves the bearer token an npmrc grants for `url`, the way get_npm_imports does.
def _bearer_for(npmrc, url, rctx, npmrc_path = "/work/.npmrc"):
    (_, auth) = helpers.get_npm_auth(npmrc, npmrc_path, rctx)
    return helpers_testonly.select_npm_auth(url, auth, rctx)[0]

def _is_absolute_path_test_impl(ctx):
    env = unittest.begin(ctx)

    for path in ["/abs/token-helper", "C:\\helper", "C:/helper", "\\\\net\\share\\helper"]:
        asserts.true(env, helpers_testonly.is_absolute_path(path), msg = "expected %r to be absolute" % path)

    for path in ["./relative", "relative/path", "token-helper", ""]:
        asserts.false(env, helpers_testonly.is_absolute_path(path), msg = "expected %r to be relative" % path)

    return unittest.end(env)

def _token_helper_global_test_impl(ctx):
    env = unittest.begin(ctx)

    asserts.equals(
        env,
        "HELPER_TOKEN",
        _bearer_for(
            {"tokenHelper": "/abs/token-helper"},
            "https://registry1/pkg/-/pkg-1.0.0.tgz",
            _fake_auth_rctx(),
        ),
    )

    return unittest.end(env)

def _token_helper_registry_test_impl(ctx):
    env = unittest.begin(ctx)

    asserts.equals(
        env,
        "HELPER_TOKEN",
        _bearer_for(
            {"//registry1/:tokenHelper": "/abs/token-helper"},
            "https://registry1/pkg/-/pkg-1.0.0.tgz",
            _fake_auth_rctx(),
        ),
    )

    return unittest.end(env)

def _token_helper_env_path_test_impl(ctx):
    env = unittest.begin(ctx)

    asserts.equals(
        env,
        "HELPER_TOKEN",
        _bearer_for(
            {"//registry1/:tokenHelper": "${HELPER}"},
            "https://registry1/pkg/-/pkg-1.0.0.tgz",
            _fake_auth_rctx(env = {"HELPER": "/abs/token-helper"}),
        ),
    )

    return unittest.end(env)

def _token_helper_relative_path_test_impl(ctx):
    env = unittest.begin(ctx)

    executed = []
    asserts.equals(
        env,
        "HELPER_TOKEN",
        _bearer_for(
            {"//registry1/:tokenHelper": "token-helper.sh"},
            "https://registry1/pkg/-/pkg-1.0.0.tgz",
            _fake_auth_rctx(executed = executed),
            npmrc_path = "/work/nested/.npmrc",
        ),
    )

    # A relative helper resolves against the directory of the declaring `.npmrc`
    asserts.equals(env, [["/work/nested/token-helper.sh"]], executed)

    return unittest.end(env)

def _token_helper_not_run_when_unused_test_impl(ctx):
    env = unittest.begin(ctx)

    executed = []
    rctx = _fake_auth_rctx(executed = executed)
    (_, auth) = helpers.get_npm_auth(
        {
            "//registry1/:tokenHelper": "/abs/token-helper",
            "//registry2/:_authToken": "STATIC",
        },
        "/work/.npmrc",
        rctx,
    )

    # Parsing alone must not run anything
    asserts.equals(env, [], executed)

    # Nor must picking auth for a registry the helper does not cover
    asserts.equals(
        env,
        "STATIC",
        helpers_testonly.select_npm_auth("https://registry2/pkg/-/pkg-1.0.0.tgz", auth, rctx)[0],
    )
    asserts.equals(env, [], executed)

    return unittest.end(env)

def _token_helper_memoized_test_impl(ctx):
    env = unittest.begin(ctx)

    executed = []
    rctx = _fake_auth_rctx(executed = executed)
    (_, auth) = helpers.get_npm_auth({"//registry1/:tokenHelper": "/abs/token-helper"}, "/work/.npmrc", rctx)

    for _ in range(3):
        asserts.equals(
            env,
            "HELPER_TOKEN",
            helpers_testonly.select_npm_auth("https://registry1/pkg/-/pkg-1.0.0.tgz", auth, rctx)[0],
        )

    # One run per registry, not one per package
    asserts.equals(env, 1, len(executed))

    return unittest.end(env)

def _token_helper_precedence_test_impl(ctx):
    env = unittest.begin(ctx)

    asserts.equals(
        env,
        "HELPER_TOKEN",
        _bearer_for(
            {
                "//registry1/:_authToken": "STATIC",
                "//registry1/:tokenHelper": "/abs/token-helper",
            },
            "https://registry1/pkg/-/pkg-1.0.0.tgz",
            _fake_auth_rctx(),
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

    # A broad registry token and a narrower one for a path below it, in the insertion order that
    # makes the broad entry match first. Selection must still return the narrower match.
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

def _select_npm_auth_boundary_test_impl(ctx):
    env = unittest.begin(ctx)

    npm_auth = {"registry.corp.com": {"bearer": "TOKEN"}}

    # "registry.corp.company.com" starts with "registry.corp.com", but is a different host and
    # must not be handed the token.
    asserts.equals(
        env,
        (None, None, None, None),
        helpers_testonly.select_npm_auth("https://registry.corp.company.com/pkg/-/pkg-1.0.0.tgz", npm_auth),
    )

    # The host itself, with and without a port, still matches.
    asserts.equals(
        env,
        ("TOKEN", None, None, None),
        helpers_testonly.select_npm_auth("https://registry.corp.com/pkg/-/pkg-1.0.0.tgz", npm_auth),
    )
    asserts.equals(
        env,
        ("TOKEN", None, None, None),
        helpers_testonly.select_npm_auth("https://registry.corp.com:8443/pkg/-/pkg-1.0.0.tgz", npm_auth),
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
token_helper_relative_path_test = unittest.make(_token_helper_relative_path_test_impl)
token_helper_not_run_when_unused_test = unittest.make(_token_helper_not_run_when_unused_test_impl)
token_helper_memoized_test = unittest.make(_token_helper_memoized_test_impl)
token_helper_precedence_test = unittest.make(_token_helper_precedence_test_impl)
select_npm_auth_longest_prefix_test = unittest.make(_select_npm_auth_longest_prefix_test_impl)
select_npm_auth_boundary_test = unittest.make(_select_npm_auth_boundary_test_impl)

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
        partial.make(token_helper_relative_path_test, timeout = "short"),
        partial.make(token_helper_not_run_when_unused_test, timeout = "short"),
        partial.make(token_helper_memoized_test, timeout = "short"),
        partial.make(token_helper_precedence_test, timeout = "short"),
        partial.make(select_npm_auth_longest_prefix_test, timeout = "short"),
        partial.make(select_npm_auth_boundary_test, timeout = "short"),
    )

# A failing tokenHelper aborts analysis, which unittest.make cannot observe, so these drive the
# same code from a rule implementation and let analysistest assert on the failure message.
# `want` must all appear in it; `unwanted`, if set, must not.
_TOKEN_HELPER_FAILURES = {
    "empty_helper_fails_test": struct(
        helper = "",
        rctx = _fake_auth_rctx(),
        want = ["tokenHelper in \"/work/.npmrc\" is empty; it must name an executable"],
        unwanted = "",
    ),
    # stderr diagnoses the failure so it is reported, but stdout carries the token and must never
    # reach the terminal or CI logs
    "helper_failure_does_not_leak_token_test": struct(
        helper = "/abs/token-helper",
        rctx = _fake_auth_rctx(stdout = "SECRET_TOKEN\n", stderr = "helper could not reach the STS", return_code = 3),
        want = ["exited with 3", "helper could not reach the STS"],
        unwanted = "SECRET_TOKEN",
    ),
    "helper_without_output_fails_test": struct(
        helper = "/abs/token-helper",
        rctx = _fake_auth_rctx(stdout = "  \n"),
        want = ["produced no output"],
        unwanted = "",
    ),
}

def _token_helper_failure_subject_impl(ctx):
    case = _TOKEN_HELPER_FAILURES[ctx.attr.case]
    (_, auth) = helpers.get_npm_auth({"//registry1/:tokenHelper": case.helper}, "/work/.npmrc", case.rctx)
    helpers_testonly.select_npm_auth("https://registry1/pkg/-/pkg-1.0.0.tgz", auth, case.rctx)
    return [DefaultInfo()]

_token_helper_failure_subject = rule(
    implementation = _token_helper_failure_subject_impl,
    attrs = {"case": attr.string(mandatory = True, values = _TOKEN_HELPER_FAILURES.keys())},
)

def _token_helper_failure_test_impl(ctx):
    env = analysistest.begin(ctx)
    case = _TOKEN_HELPER_FAILURES[ctx.attr.case]

    for want in case.want:
        asserts.expect_failure(env, want)

    if case.unwanted:
        # expect_failure can only assert presence, so read the failure message to assert absence
        causes = analysistest.target_under_test(env)[AnalysisFailureInfo].causes.to_list()
        message = "\n".join([cause.message for cause in causes])
        asserts.true(
            env,
            message.find(case.unwanted) < 0,
            msg = "%r leaked into the failure message: %s" % (case.unwanted, message),
        )

    return analysistest.end(env)

_token_helper_failure_test = analysistest.make(
    _token_helper_failure_test_impl,
    expect_failure = True,
    attrs = {"case": attr.string(mandatory = True, values = _TOKEN_HELPER_FAILURES.keys())},
)

def npm_auth_failure_test_suite(name):
    """Analysis tests for `tokenHelper` invocations that must abort the build.

    Args:
        name: The name of the test_suite target.
    """
    for case in _TOKEN_HELPER_FAILURES.keys():
        _token_helper_failure_subject(name = case + "_subject", case = case, tags = ["manual"])
        _token_helper_failure_test(name = case, case = case, target_under_test = ":" + case + "_subject")

    native.test_suite(
        name = name,
        tests = [":" + case for case in _TOKEN_HELPER_FAILURES.keys()],
    )
