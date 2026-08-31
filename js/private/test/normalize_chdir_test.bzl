"""Tests for the normalize_chdir utility function"""

load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")
load("//js/private:js_helpers.bzl", "normalize_chdir")

def _main_repo(ctx):
    env = unittest.begin(ctx)
    asserts.equals(env, "foo/bar", normalize_chdir("foo/bar", ""))

    # package_name() is empty in the root package
    asserts.equals(env, ".", normalize_chdir("", ""))
    asserts.equals(env, ".", normalize_chdir(".", ""))
    return unittest.end(env)

def _external_repo(ctx):
    env = unittest.begin(ctx)
    asserts.equals(env, "external/myrepo/foo/bar", normalize_chdir("foo/bar", "myrepo"))

    # The root package of an external repository is the repository directory itself, with no
    # trailing slash, whether it arrives as "" or as "."
    asserts.equals(env, "external/myrepo", normalize_chdir("", "myrepo"))
    asserts.equals(env, "external/myrepo", normalize_chdir(".", "myrepo"))
    return unittest.end(env)

def _left_alone(ctx):
    env = unittest.begin(ctx)

    # Already prefixed, absolute, or naming a repository
    asserts.equals(env, "external/other/foo", normalize_chdir("external/other/foo", "myrepo"))
    asserts.equals(env, "/abs/path", normalize_chdir("/abs/path", "myrepo"))
    asserts.equals(env, "@other//foo", normalize_chdir("@other//foo", "myrepo"))
    return unittest.end(env)

main_repo_test = unittest.make(_main_repo)
external_repo_test = unittest.make(_external_repo)
left_alone_test = unittest.make(_left_alone)

def normalize_chdir_tests(name):
    unittest.suite(
        name,
        main_repo_test,
        external_repo_test,
        left_alone_test,
    )
