"UnitTests for js_library"

load("@bazel_skylib//lib:unittest.bzl", "analysistest", "asserts")
load("@bazel_skylib//rules:write_file.bzl", "write_file")
load("//js/private:js_library.bzl", "js_library")
load("//js/private:js_info.bzl", "JsInfo")

# Files + targets generated for use in tests
def _js_library_test_suite_data():
    write_file(
        name = "importing_js",
        out = "importing.js",
        content = ["import { dirname } from 'path'; export const dir = dirname(__filename);"],
        tags = ["manual"],
    )
    write_file(
        name = "importing_dts",
        out = "importing.d.ts",
        content = ["export const dir: string;"],
        tags = ["manual"],
    )

# Tests
def _declarations_test_impl(ctx):
    env = analysistest.begin(ctx)
    target_under_test = analysistest.target_under_test(env)

    # declarations should only have the source declarations
    declarations = target_under_test[JsInfo].declarations
    asserts.equals(env, 1, len(declarations))
    asserts.true(env, declarations[0].path.find("/importing.d.ts") != -1)

    # declarations should only have the source declarations
    transitive_declarations = target_under_test[JsInfo].transitive_declarations
    asserts.equals(env, 1, len(transitive_declarations))
    asserts.true(env, transitive_declarations[0].path.find("/importing.d.ts") != -1)

    # types OutputGroupInfo should be the same as direct declarations
    asserts.equals(env, declarations, target_under_test[OutputGroupInfo].types.to_list())

    return analysistest.end(env)

def _declarations_empty_srcs_test_impl(ctx):
    env = analysistest.begin(ctx)
    target_under_test = analysistest.target_under_test(env)

    # declarations should only have the source declarations, in this case 0
    declarations = target_under_test[JsInfo].declarations
    asserts.equals(env, 0, len(declarations))

    # transitive_declarations should contain additional indirect deps
    transitive_declarations = target_under_test[JsInfo].transitive_declarations
    asserts.true(env, len(transitive_declarations) > len(declarations))

    # types OutputGroupInfo should be the same as direct declarations
    asserts.equals(env, declarations, target_under_test[OutputGroupInfo].types.to_list())

    return analysistest.end(env)

# Test declarations
_declarations_test = analysistest.make(_declarations_test_impl)
_declarations_empty_srcs_test = analysistest.make(_declarations_empty_srcs_test_impl)

def js_library_test_suite(name):
    """Test suite including all tests and data

    Args:
        name: Target name of the test_suite target.
    """
    _js_library_test_suite_data()

    # Declarations in srcs + deps
    js_library(
        name = "transitive_type_deps",
        srcs = ["importing.js", "importing.d.ts"],
        deps = [
            "//:node_modules/@types/node",
        ],
        tags = ["manual"],
    )
    _declarations_test(
        name = "transitive_type_deps_test",
        target_under_test = "transitive_type_deps",
    )

    # Empty srcs, declarations in deps
    js_library(
        name = "transitive_type_deps_empty_srcs",
        deps = [":transitive_type_deps"],
        tags = ["manual"],
    )
    _declarations_empty_srcs_test(
        name = "transitive_type_deps_empty_srcs_test",
        target_under_test = "transitive_type_deps_empty_srcs",
    )

    native.test_suite(
        name = name,
        tests = [
            ":transitive_type_deps_test",
            ":transitive_type_deps_empty_srcs_test",
        ],
    )
