"""Unit tests for pnpm utils
See https://docs.bazel.build/versions/main/skylark/testing.html#for-testing-starlark-utilities
"""

load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")
load("//npm/private:utils.bzl", "utils", "utils_test")

# buildifier: disable=function-docstring
def test_package_store_and_target_name(ctx):
    env = unittest.begin(ctx)

    # MODIFY CAREFULLY - these are designed to be bazel-compatible while aligning with
    # the pnpm v9/10+ store naming conventions.

    # standard name@version
    asserts.equals(env, "x@1.1.1", utils.package_store_name("x@1.1.1"))
    asserts.equals(env, "y__x__1.1.1", utils.package_repo_name("y", "x@1.1.1"))

    # standard @scoped/name@version
    asserts.equals(env, "@scope+y@1.1.1", utils.package_store_name("@scope/y@1.1.1"))
    asserts.equals(env, "x__at_scope_y__1.1.1", utils.package_repo_name("x", "@scope/y@1.1.1"))

    # peer dependencies
    asserts.equals(env, "@scope+y@1.1.1_x@0.1.0", utils.package_store_name("@scope/y@1.1.1(x@0.1.0)"))
    asserts.equals(env, "x__at_scope_y__1.1.1_x_0.1.0", utils.package_repo_name("x", "@scope/y@1.1.1(x@0.1.0)"))

    asserts.equals(env, "@scope+y@1.1.1_@scope+x@0.1.0", utils.package_store_name("@scope/y@1.1.1(@scope/x@0.1.0)"))
    asserts.equals(env, "x__at_scope_y__1.1.1_at_scope_x_0.1.0", utils.package_repo_name("x", "@scope/y@1.1.1(@scope/x@0.1.0)"))

    asserts.equals(env, "@scope+y@1.1.1_94025728", utils.package_store_name("@scope/y@1.1.1(@scope/w@0.0.10)(@scope/x@0.0.2)"))
    asserts.equals(env, "x__at_scope_y__1.1.1_94025728", utils.package_repo_name("x", "@scope/y@1.1.1(@scope/w@0.0.10)(@scope/x@0.0.2)"))

    asserts.equals(env, "@scope+pkg@21.1.0_rollup@2.70.2_@scope+y@1.1.1", utils.package_store_name("@scope/pkg@21.1.0(rollup@2.70.2)(@scope/y@1.1.1)"))
    asserts.equals(env, "x__at_scope_pkg__21.1.0_rollup_2.70.2_at_scope_y_1.1.1", utils.package_repo_name("x", "@scope/pkg@21.1.0(rollup@2.70.2)(@scope/y@1.1.1)"))

    # v9 patch_hash
    asserts.equals(env, "meaning-of-life@1.0.0_1287509853", utils.package_store_name("meaning-of-life@1.0.0(patch_hash=o3deharooos255qt5xdujc3cuq)"))
    asserts.equals(env, "x__meaning-of-life__1.0.0_1287509853", utils.package_repo_name("x", "meaning-of-life@1.0.0(patch_hash=o3deharooos255qt5xdujc3cuq)"))

    # v10 patch_hash
    asserts.equals(env, "meaning-of-life@1.0.0_124257499", utils.package_store_name("meaning-of-life@1.0.0(patch_hash=33610921243aecf4fa5a23dc8080659f436ccda15f41ce4f53c687039a305ee0)"))
    asserts.equals(env, "x__meaning-of-life__1.0.0_124257499", utils.package_repo_name("x", "meaning-of-life@1.0.0(patch_hash=33610921243aecf4fa5a23dc8080659f436ccda15f41ce4f53c687039a305ee0)"))

    # file:
    asserts.equals(env, "@scope+y@file+bar", utils.package_store_name("@scope/y@file:bar"))
    asserts.equals(env, "x__at_scope_y__file_bar", utils.package_repo_name("x", "@scope/y@file:bar"))

    # file: + @
    asserts.equals(env, "@scope+y@file+@foo+bar", utils.package_store_name("@scope/y@file:@foo/bar"))
    asserts.equals(env, "x__at_scope_y__file__foo_bar", utils.package_repo_name("x", "@scope/y@file:@foo/bar"))

    # file: ../
    asserts.equals(env, "@scope+y@file+..+foo+bar", utils.package_store_name("@scope/y@file:../foo/bar"))
    asserts.equals(env, "x__at_scope_y__file_.._foo_bar", utils.package_repo_name("x", "@scope/y@file:../foo/bar"))

    # file: ../tar
    asserts.equals(env, "lodash@file+..+vendored+lodash-4.17.21.tgz", utils.package_store_name("lodash@file:../vendored/lodash-4.17.21.tgz"))
    asserts.equals(env, "x__lodash__file_.._vendored_lodash-4.17.21.tgz", utils.package_repo_name("x", "lodash@file:../vendored/lodash-4.17.21.tgz"))

    # file: .. (peers)
    asserts.equals(env, "@scoped+c@file+..+projects+c_@scoped+b@projects+b", utils.package_store_name("@scoped/c@file:../projects/c(@scoped/b@projects+b)"))
    asserts.equals(env, "x__at_scoped_c__file_.._projects_c_at_scoped_b_projects_b", utils.package_repo_name("x", "@scoped/c@file:../projects/c(@scoped/b@projects+b)"))

    # URL
    asserts.equals(env, "diff@https+++github.com+kpdecker+jsdiff+archive+refs+tags+v5.2.0.tar.gz", utils.package_store_name("diff@https://github.com/kpdecker/jsdiff/archive/refs/tags/v5.2.0.tar.gz"))
    asserts.equals(env, "x__diff__https___github.com_kpdecker_jsdiff_archive_refs_tags_v5.2.0.tar.gz", utils.package_repo_name("x", "diff@https://github.com/kpdecker/jsdiff/archive/refs/tags/v5.2.0.tar.gz"))

    # @ and 0.0.0 in a URL
    asserts.equals(env, "@foo+jsonify@https+++github.com+aspect-build+test-packages+releases+download+0.0.0+@foo-jsonify-0.0.0.tgz", utils.package_store_name("@foo/jsonify@https://github.com/aspect-build/test-packages/releases/download/0.0.0/@foo-jsonify-0.0.0.tgz"))
    asserts.equals(env, "x__at_foo_jsonify__https___github.com_aspect-build_test-packages_releases_download_0.0.0__foo-jsonify-0.0.0.tgz", utils.package_repo_name("x", "@foo/jsonify@https://github.com/aspect-build/test-packages/releases/download/0.0.0/@foo-jsonify-0.0.0.tgz"))

    # URLs with commit hashes
    asserts.equals(env, "jquery@https+++codeload.github.com+jquery+jquery+tar.gz+399b201bb3143a3952894cf3489b4848fc003967", utils.package_store_name("jquery@https://codeload.github.com/jquery/jquery/tar.gz/399b201bb3143a3952894cf3489b4848fc003967"))
    asserts.equals(env, "x__jquery__https___codeload.github.com_jquery_jquery_tar.gz_399b201bb3143a3952894cf3489b4848fc003967", utils.package_repo_name("x", "jquery@https://codeload.github.com/jquery/jquery/tar.gz/399b201bb3143a3952894cf3489b4848fc003967"))

    return unittest.end(env)

# buildifier: disable=function-docstring
def test_package_store_name_link_versions(ctx):
    env = unittest.begin(ctx)
    asserts.equals(env, "x@0.0.0", utils.package_store_name("link:x|foo/@bar/baz"))
    asserts.equals(env, "@scope+y@0.0.0", utils.package_store_name("link:@scope/y|foo/bar"))
    return unittest.end(env)

def test_friendly_name(ctx):
    env = unittest.begin(ctx)
    asserts.equals(env, "@scope/y@2.1.1", utils.friendly_name("@scope/y", "2.1.1"))
    return unittest.end(env)

# buildifier: disable=function-docstring
def test_parse_package_name(ctx):
    env = unittest.begin(ctx)
    asserts.equals(env, ("@scope", "package"), utils_test.parse_package_name("@scope/package"))
    asserts.equals(env, ("@scope", "package/a"), utils_test.parse_package_name("@scope/package/a"))
    asserts.equals(env, ("", "package"), utils_test.parse_package_name("package"))
    asserts.equals(env, ("", "@package"), utils_test.parse_package_name("@package"))
    return unittest.end(env)

# buildifier: disable=function-docstring
def test_npm_registry_url(ctx):
    env = unittest.begin(ctx)
    asserts.equals(
        env,
        "https://default",
        utils.npm_registry_url("a", {}, "https://default"),
    )
    asserts.equals(
        env,
        "http://default",
        utils.npm_registry_url("a", {}, "http://default"),
    )
    asserts.equals(
        env,
        "//default",
        utils.npm_registry_url("a", {}, "//default"),
    )
    asserts.equals(
        env,
        "https://default",
        utils.npm_registry_url("@a/b", {}, "https://default"),
    )
    asserts.equals(
        env,
        "https://default",
        utils.npm_registry_url("@a/b", {"@ab": "not me"}, "https://default"),
    )
    asserts.equals(
        env,
        "https://scoped-registry",
        utils.npm_registry_url("@a/b", {"@a": "https://scoped-registry"}, "https://default"),
    )
    return unittest.end(env)

# buildifier: disable=function-docstring
def test_npm_registry_download_url(ctx):
    env = unittest.begin(ctx)
    asserts.equals(
        env,
        "https://registry.npmjs.org/y/-/y-1.2.3.tgz",
        utils.npm_registry_download_url("y", "1.2.3", {}, "https://registry.npmjs.org/"),
    )
    asserts.equals(
        env,
        "http://registry.npmjs.org/y/-/y-1.2.3.tgz",
        utils.npm_registry_download_url("y", "1.2.3", {}, "http://registry.npmjs.org/"),
    )
    asserts.equals(
        env,
        "https://registry.npmjs.org/@scope/y/-/y-1.2.3.tgz",
        utils.npm_registry_download_url("@scope/y", "1.2.3", {}, "https://registry.npmjs.org/"),
    )
    asserts.equals(
        env,
        "https://registry.npmjs.org/@scope/y/-/y-1.2.3.tgz",
        utils.npm_registry_download_url("@scope/y", "1.2.3", {"@scopyy": "foobar"}, "https://registry.npmjs.org/"),
    )
    asserts.equals(
        env,
        "https://npm.pkg.github.com/@scope/y/-/y-1.2.3.tgz",
        utils.npm_registry_download_url("@scope/y", "1.2.3", {"@scope": "https://npm.pkg.github.com/"}, "https://registry.npmjs.org/"),
    )
    asserts.equals(
        env,
        "https://npm.pkg.github.com/@scope/y/-/y-1.2.3.tgz",
        utils.npm_registry_download_url("@scope/y", "1.2.3", {}, "https://npm.pkg.github.com/"),
    )
    return unittest.end(env)

t2_test = unittest.make(test_package_store_and_target_name)
t3_test = unittest.make(test_friendly_name)
t6_test = unittest.make(test_parse_package_name)
t7_test = unittest.make(test_npm_registry_download_url)
t8_test = unittest.make(test_npm_registry_url)
t9_test = unittest.make(test_package_store_name_link_versions)

def utils_tests(name):
    unittest.suite(
        name,
        t2_test,
        t3_test,
        t6_test,
        t7_test,
        t8_test,
        t9_test,
    )
