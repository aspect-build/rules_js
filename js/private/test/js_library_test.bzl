"UnitTests for js_library"

load("@bazel_skylib//lib:unittest.bzl", "analysistest", "asserts")
load("@bazel_skylib//rules:write_file.bzl", "write_file")
load("//js/private:js_info.bzl", "JsInfo")
load("//js/private:js_library.bzl", "js_library")

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
    write_file(
        name = "data_json",
        out = "data.json",
        content = ["{\"name\": \"data\"}"],
        tags = ["manual"],
    )

# Tests
def _types_test_impl(ctx):
    env = analysistest.begin(ctx)
    target_under_test = analysistest.target_under_test(env)

    # types should only have the source types
    types = target_under_test[JsInfo].types.to_list()
    asserts.equals(env, 2, len(types))
    asserts.true(env, types[0].path.find("/importing.d.ts") != -1)
    asserts.true(env, types[1].path.find("/data.json") != -1)

    # transitive_types should have the source types and transitive types
    transitive_types = target_under_test[JsInfo].transitive_types.to_list()
    asserts.true(env, len(transitive_types) == 2)
    asserts.true(env, transitive_types[0].path.find("/importing.d.ts") != -1)
    asserts.true(env, transitive_types[1].path.find("/data.json") != -1)

    # types OutputGroupInfo should be the same as direct types
    asserts.equals(env, types, target_under_test[OutputGroupInfo].types.to_list())

    return analysistest.end(env)

def _explicit_types_test_impl(ctx):
    env = analysistest.begin(ctx)
    target_under_test = analysistest.target_under_test(env)

    # types should only have the source types
    types = target_under_test[JsInfo].types.to_list()
    asserts.equals(env, 2, len(types))
    asserts.true(env, types[0].path.find("/data.json") != -1)
    asserts.true(env, types[1].path.find("/index.js") != -1)

    # transitive_types should have the source types and transitive types
    transitive_types = target_under_test[JsInfo].transitive_types.to_list()
    asserts.true(env, len(transitive_types) == 2)
    asserts.true(env, transitive_types[0].path.find("/data.json") != -1)
    asserts.true(env, transitive_types[1].path.find("/index.js") != -1)

    # types OutputGroupInfo should be the same as direct types
    asserts.equals(env, types, target_under_test[OutputGroupInfo].types.to_list())

    return analysistest.end(env)

def _types_empty_srcs_test_impl(ctx):
    env = analysistest.begin(ctx)
    target_under_test = analysistest.target_under_test(env)

    # types should only have the source types, in this case 0
    types = target_under_test[JsInfo].types.to_list()
    asserts.equals(env, 0, len(types))

    # transitive_types should contain additional indirect deps
    transitive_types = target_under_test[JsInfo].transitive_types.to_list()
    asserts.true(env, len(transitive_types) > len(types))

    # types OutputGroupInfo should be the same as direct types
    asserts.equals(env, types, target_under_test[OutputGroupInfo].types.to_list())

    return analysistest.end(env)

# Test types
_types_test = analysistest.make(_types_test_impl)
_explicit_types_test = analysistest.make(_explicit_types_test_impl)
_types_empty_srcs_test = analysistest.make(_types_empty_srcs_test_impl)

def js_library_test_suite(name):
    """Test suite including all tests and data

    Args:
        name: Target name of the test_suite target.
    """
    _js_library_test_suite_data()

    # Declarations in srcs + deps
    js_library(
        name = "transitive_type_deps",
        srcs = ["importing.js", "importing.d.ts", "data.json"],
        deps = [
            "//:node_modules/@types/node",
        ],
        tags = ["manual"],
    )
    _types_test(
        name = "transitive_type_deps_test",
        target_under_test = "transitive_type_deps",
    )

    # Explicit types
    js_library(
        name = "explicit_types",
        srcs = ["data.json"],
        types = ["index.js"],
        deps = [
            "//:node_modules/@types/node",
        ],
        tags = ["manual"],
    )
    _explicit_types_test(
        name = "explicit_types_test",
        target_under_test = "explicit_types",
    )

    # Empty srcs, types in deps
    js_library(
        name = "transitive_type_deps_empty_srcs",
        deps = [":transitive_type_deps"],
        tags = ["manual"],
    )
    _types_empty_srcs_test(
        name = "transitive_type_deps_empty_srcs_test",
        target_under_test = "transitive_type_deps_empty_srcs",
    )

    native.test_suite(
        name = name,
        tests = [
            ":transitive_type_deps_test",
            ":explicit_types_test",
            ":transitive_type_deps_empty_srcs_test",
        ],
    )
