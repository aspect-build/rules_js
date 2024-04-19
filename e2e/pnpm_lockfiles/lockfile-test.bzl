"""
Test utils for lockfiles
"""

load("@bazel_skylib//rules:build_test.bzl", "build_test")

def lockfile_test(name = "lockfile", node_modules = "node_modules"):
    """
    A test that verifies the `node_modules` target generated is correct.
    """

    build_test(
        name = name,
        targets = [
            ":%s" % node_modules,
            ":%s/@aspect-test/a" % node_modules,
            ":%s/@aspect-test/b" % node_modules,
            ":%s/@aspect-test/c" % node_modules,
            ":%s/sharp" % node_modules,
            ":%s/uvu" % node_modules,
        ],
    )
