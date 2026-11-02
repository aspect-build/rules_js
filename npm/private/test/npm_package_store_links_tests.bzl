"Analysis tests for package store dependency symlinks shared across circular dependency terminals"

load("@bazel_skylib//lib:unittest.bzl", "analysistest", "asserts")
load("//npm/private:npm_package_store_info.bzl", "NpmPackageStoreInfo")

def _store_symlinks_test_impl(ctx):
    env = analysistest.begin(ctx)
    target = analysistest.target_under_test(env)

    owned = [
        output.short_path
        for action in analysistest.target_actions(env)
        if action.mnemonic == "UnresolvedSymlink"
        for output in action.outputs.to_list()
    ]
    asserts.equals(env, sorted(ctx.attr.expect_owned_symlinks), sorted(owned))

    files = [f.short_path for f in target[NpmPackageStoreInfo].files.to_list()]
    for expected in ctx.attr.expect_files:
        asserts.true(env, expected in files, "expected {} in package store files".format(expected))

    return analysistest.end(env)

store_symlinks_test = analysistest.make(
    _store_symlinks_test_impl,
    attrs = {
        "expect_owned_symlinks": attr.string_list(doc = "Symlinks this target creates itself"),
        "expect_files": attr.string_list(doc = "Paths expected in NpmPackageStoreInfo.files"),
    },
)

def npm_package_store_links_tests(name):
    """Checks that terminals of circular dependencies take dependency symlinks from shared links targets.

    Args:
        name: test suite name
    """
    es5_ext = "node_modules/.aspect_rules_js/es5-ext@0.10.64/node_modules/"
    d = "node_modules/.aspect_rules_js/d@1.0.2/node_modules/"
    ext = "node_modules/.aspect_rules_js/ext@1.7.0/node_modules/"

    # terminal of a circular package creates none of its closure's symlinks itself but still provides them
    store_symlinks_test(
        name = name + "_circular_terminal",
        target_under_test = "//:.aspect_rules_js/node_modules/es5-ext@0.10.64",
        expect_owned_symlinks = [],
        expect_files = [
            es5_ext + "es6-iterator",
            es5_ext + "es6-symbol",
            es5_ext + "esniff",
            es5_ext + "next-tick",
            d + "es5-ext",
            d + "type",
            ext + "type",
        ],
    )

    # main store of a non-circular closure member is unchanged and creates its own symlinks
    store_symlinks_test(
        name = name + "_member_store",
        target_under_test = "//:.aspect_rules_js/node_modules/ext@1.7.0",
        expect_owned_symlinks = [ext + "type"],
        expect_files = [ext + "type"],
    )

    native.test_suite(
        name = name,
        tests = [
            ":" + name + "_circular_terminal",
            ":" + name + "_member_store",
        ],
    )
