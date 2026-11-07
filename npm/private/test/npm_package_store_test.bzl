"""Analysis tests for npm_package_store"""

load("@bazel_skylib//lib:unittest.bzl", "analysistest", "asserts")
load("//js:providers.bzl", "JsInfo")
load("//npm/private:npm_package_store_info.bzl", "NpmPackageStoreInfo")

def _transitive_files_test_impl(ctx):
    env = analysistest.begin(ctx)
    target = analysistest.target_under_test(env)

    transitive_files = [f.short_path for f in target[NpmPackageStoreInfo].transitive_files.to_list()]

    indirect_dep_store_directory = ctx.attr.indirect_dep[NpmPackageStoreInfo].package_store_directory
    asserts.true(
        env,
        indirect_dep_store_directory.short_path in transitive_files,
        "expected transitive_files to contain {}".format(indirect_dep_store_directory.short_path),
    )

    # npm_sources of a third-party package store already covers its whole closure
    asserts.equals(
        env,
        sorted([f.short_path for f in target[JsInfo].npm_sources.to_list()]),
        sorted(transitive_files),
    )
    return analysistest.end(env)

_transitive_files_test = analysistest.make(
    _transitive_files_test_impl,
    attrs = {
        "indirect_dep": attr.label(
            doc = "Store target of a dep that the target under test only reaches through another dep",
            mandatory = True,
            providers = [NpmPackageStoreInfo],
        ),
    },
)

def npm_package_store_test_suite(name):
    """Test suite for npm_package_store

    Args:
        name: Target name of the test_suite target.
    """

    # chalk depends on has-flag through supports-color
    _transitive_files_test(
        name = "basic_transitive_files_test",
        target_under_test = "//:.aspect_rules_js/node_modules/chalk@4.1.2",
        indirect_dep = "//:.aspect_rules_js/node_modules/has-flag@4.0.0",
    )

    # segfault-handler has a lifecycle build target. It depends on file-uri-to-path through bindings
    _transitive_files_test(
        name = "lifecycle_transitive_files_test",
        target_under_test = "//:.aspect_rules_js/node_modules/segfault-handler@1.3.0",
        indirect_dep = "//:.aspect_rules_js/node_modules/file-uri-to-path@1.0.0",
    )

    # es5-ext is in a dependency cycle. It depends on type through esniff
    _transitive_files_test(
        name = "circular_transitive_files_test",
        target_under_test = "//:.aspect_rules_js/node_modules/es5-ext@0.10.64",
        indirect_dep = "//:.aspect_rules_js/node_modules/type@2.7.3",
    )

    native.test_suite(
        name = name,
        tests = [
            ":basic_transitive_files_test",
            ":lifecycle_transitive_files_test",
            ":circular_transitive_files_test",
        ],
    )
