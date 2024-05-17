"""
Test utils for lockfiles
"""

load("@aspect_bazel_lib//lib:copy_file.bzl", "copy_file")
load("@aspect_rules_js//js:defs.bzl", "js_test")
load("@bazel_skylib//rules:build_test.bzl", "build_test")

def lockfile_test(name = "lockfile", node_modules = "node_modules"):
    """
    A test that verifies the `node_modules` target generated is correct.

    Args:
        name: name of the test
        node_modules: name of the tested 'node_modules' directory
    """

    copy_file(
        name = "copy-tests",
        src = "//:base/patched-dependencies-test.js",
        out = "patched-dependencies-test.js",
    )

    js_test(
        name = "patch-test",
        data = [
            ":%s/meaning-of-life" % node_modules,
        ],
        entry_point = "patched-dependencies-test.js",
    )

    build_test(
        name = name,
        targets = [
            # The full node_modules target
            ":%s" % node_modules,

            # Direct 'dependencies'
            ":%s/@aspect-test/a" % node_modules,

            # Direct 'devDependencies'
            ":%s/@aspect-test/b" % node_modules,

            # Direct 'optionalDependencies'
            ":%s/@aspect-test/c" % node_modules,

            # rollup has a 'optionalDependency' (fsevents)
            ":%s/rollup" % node_modules,

            # uuv 'hasBin'
            ":%s/uvu" % node_modules,

            # link:, workspace:, file:, ./rel/path
            ":%s/@scoped/a" % node_modules,
            ":%s/@scoped/b" % node_modules,
            # ":%s/@scoped/c" % node_modules, TODO: see README
            ":%s/@scoped/d" % node_modules,

            # npm:
            # ":%s/@aspect-test/c2" % node_modules,

            # Targets within the virtual store...
            # Direct dep targets
            ":.aspect_rules_js/node_modules/@aspect-test+a@5.0.2",
            ":.aspect_rules_js/node_modules/@aspect-test+a@5.0.2/dir",
            ":.aspect_rules_js/node_modules/@aspect-test+a@5.0.2/pkg",
            ":.aspect_rules_js/node_modules/@aspect-test+a@5.0.2/ref",

            # Direct deps with lifecycles
            ":.aspect_rules_js/node_modules/@aspect-test+c@2.0.2/lc",
            ":.aspect_rules_js/node_modules/@aspect-test+c@2.0.2/pkg_lc",

            # Patched dependencies
            ":.aspect_rules_js/node_modules/meaning-of-life@1.0.0_o3deharooos255qt5xdujc3cuq",

            # TODO: differs across lockfile versions
            # Direct deps from custom registry
            # ":.aspect_rules_js/node_modules/@types+node@registry.npmjs.org+@types+node@16.18.11",

            # TODO: differs across lockfile versions
            # Direct deps with peers differ across lockfile versions
            # ":.aspect_rules_js/node_modules/@aspect-test+d@2.0.0_@aspect-test+c@2.0.2",
        ],
    )
