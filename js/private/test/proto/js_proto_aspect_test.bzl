"""Analysis tests for js_proto_aspect.

These tests verify that the JsProtocGenerate action has the expected argument
structure.
"""

load("@bazel_skylib//lib:unittest.bzl", "analysistest", "asserts")
load("@bazel_skylib//rules:write_file.bzl", "write_file")
load("@protobuf//bazel:proto_library.bzl", "proto_library")
load("//js/private:proto.bzl", "js_proto_aspect")

_TestingInfo = provider(doc = "Store Bazel actions so that we can make assertions about them", fields = ["actions"])

def _js_proto_testing_aspect_impl(target, _ctx):
    return [_TestingInfo(actions = target.actions)]

_js_proto_testing_aspect = aspect(
    implementation = _js_proto_testing_aspect_impl,
    # This guarantees that js_proto_aspect runs first; target.actions then
    # includes the JsProtocGenerate action js_proto_aspect registered.
    requires = [js_proto_aspect],
)

def _get_protoc_action(env):
    target = analysistest.target_under_test(env)
    actions = target[_TestingInfo].actions
    matching = [a for a in actions if a.mnemonic == "JsProtocGenerate"]
    asserts.equals(env, 1, len(matching), "Expected exactly 1 JsProtocGenerate action, got %d" % len(matching))
    return matching[0] if len(matching) == 1 else None

# ---------------------------------------------------------------------------
# Test 1: verify basic arg structure for a proto with no virtual import deps.
# ---------------------------------------------------------------------------

def _proto_args_test_impl(ctx):
    env = analysistest.begin(ctx)
    action = _get_protoc_action(env)
    if action != None:
        argv = action.argv

        plugin_flags = [a for a in argv if a.startswith("--plugin=protoc-gen-es=")]
        asserts.equals(env, 1, len(plugin_flags), "Expected exactly 1 --plugin=protoc-gen-es= flag")

        out_flags = [a for a in argv if a.startswith("--es_out=")]
        asserts.equals(env, 1, len(out_flags), "Expected exactly 1 --es_out= flag")

        asserts.true(env, "--descriptor_set_in" in argv, "Expected --descriptor_set_in in argv")

        asserts.true(env, "-I." in argv, "Expected -I. in argv")

        rewrite_flags = [a for a in argv if "--es_opt=rewrite_imports=" in a]
        asserts.equals(env, 0, len(rewrite_flags), "Expected no rewrite_imports flags for a proto with no virtual import deps")

        asserts.true(env, argv[-1].endswith(".proto"), "Expected last arg to be a .proto source file, got: " + argv[-1])

    return analysistest.end(env)

proto_args_test = analysistest.make(
    _proto_args_test_impl,
    extra_target_under_test_aspects = [_js_proto_testing_aspect],
)

# ---------------------------------------------------------------------------
# Test 2: verify rewrite_imports args for a proto with virtual import deps.
# ---------------------------------------------------------------------------

def _proto_rewrite_imports_test_impl(ctx):
    env = analysistest.begin(ctx)
    action = _get_protoc_action(env)
    if action != None:
        argv = action.argv

        rewrite_flags = [a for a in argv if a.startswith("--es_opt=rewrite_imports=")]
        asserts.equals(
            env,
            2,
            len(rewrite_flags),
            "Expected exactly 2 rewrite_imports flags, got: %s" % str(rewrite_flags),
        )

        for flag in rewrite_flags:
            value = flag[len("--es_opt=rewrite_imports="):]
            parts = value.split(":")
            asserts.equals(env, 2, len(parts), "Expected rewrite_imports value to have format 'original:replacement': " + flag)
            if len(parts) == 2:
                original = parts[0]
                replacement = parts[1]
                asserts.true(env, original.startswith("./"), "Expected original import to start with './': " + original)
                asserts.true(env, original.endswith("_pb.js"), "Expected original import to end with '_pb.js': " + original)
                asserts.true(
                    env,
                    "/_virtual_imports/" in replacement,
                    "Expected replacement to contain '/_virtual_imports/': " + replacement,
                )

    return analysistest.end(env)

proto_rewrite_imports_test = analysistest.make(
    _proto_rewrite_imports_test_impl,
    extra_target_under_test_aspects = [_js_proto_testing_aspect],
)

def js_proto_aspect_test_suite(name):
    """Creates a test suite with analysis tests for proto_common.compile().

    Args:
        name: The name of the test_suite target.
    """

    # Target for test 1: a simple proto with no virtual import deps
    write_file(
        name = "simple_proto_src",
        out = "simple.proto",
        content = [
            'syntax = "proto3";',
            "",
            "message SimpleRequest {}",
            "",
            "message SimpleResponse {}",
            "",
            "service SimpleService {",
            "    rpc Simple(SimpleRequest) returns (SimpleResponse) {}",
            "}",
        ],
        tags = ["manual"],
    )
    proto_library(
        name = "simple_proto",
        srcs = [":simple_proto_src"],
        tags = ["manual"],
    )

    # Targets for test 2: a proto with exactly two deps that use import_prefix,
    # which triggers the virtual-import rewrite logic in js_proto_aspect.
    write_file(
        name = "dep_a_proto_src",
        out = "dep_a.proto",
        content = [
            'syntax = "proto3";',
            "",
            "message DepA {}",
        ],
        tags = ["manual"],
    )
    proto_library(
        name = "dep_a_proto",
        srcs = [":dep_a_proto_src"],
        import_prefix = "prefix_a/",
        tags = ["manual"],
    )

    write_file(
        name = "dep_b_proto_src",
        out = "dep_b.proto",
        content = [
            'syntax = "proto3";',
            "",
            "message DepB {}",
        ],
        tags = ["manual"],
    )
    proto_library(
        name = "dep_b_proto",
        srcs = [":dep_b_proto_src"],
        import_prefix = "prefix_b/",
        tags = ["manual"],
    )

    write_file(
        name = "main_proto_src",
        out = "main_with_virtual_deps.proto",
        content = [
            'syntax = "proto3";',
            "",
            'import "prefix_a/dep_a.proto";',
            'import "prefix_b/dep_b.proto";',
            "",
            "message Main {",
            "    DepA dep_a = 1;",
            "    DepB dep_b = 2;",
            "}",
        ],
        tags = ["manual"],
    )
    proto_library(
        name = "main_proto",
        srcs = [":main_proto_src"],
        deps = [":dep_a_proto", ":dep_b_proto"],
        tags = ["manual"],
    )

    proto_args_test(
        name = "proto_args_test",
        target_under_test = ":simple_proto",
    )

    proto_rewrite_imports_test(
        name = "proto_rewrite_imports_test",
        target_under_test = ":main_proto",
    )

    native.test_suite(
        name = name,
        tests = [
            ":proto_args_test",
            ":proto_rewrite_imports_test",
        ],
    )
