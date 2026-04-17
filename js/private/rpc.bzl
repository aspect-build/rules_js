"""Rule for generating JavaScript and TypeScript RPC stubs from proto_library targets.

This integrates protoc RPC plugins (such as protoc-gen-connect-query) with Bazel,
following the "Local Generation" mechanism described at
https://connectrpc.com/docs/web/generating-code#local-generation.
"""

load("@protobuf//bazel/common:proto_info.bzl", "ProtoInfo")
load("//js:providers.bzl", "js_info")
load(
    "//js/private:js_helpers.bzl",
    "gather_npm_package_store_infos",
    "gather_npm_sources",
)
load(":proto.bzl", "PROTOC_TOOLCHAIN")
load(":proto_common.bzl", "proto_common")

LANG_RPC_TOOLCHAIN = Label("//js/toolchains:protoc_rpc_plugin")

def _js_rpc_library_impl(ctx):
    protoc_info = ctx.toolchains[PROTOC_TOOLCHAIN].proto
    proto_lang_toolchain_info = ctx.toolchains[LANG_RPC_TOOLCHAIN].proto
    js_proto_toolchain_info = ctx.toolchains[LANG_RPC_TOOLCHAIN].js

    if len(ctx.attr.deps) != 1:
        fail("There must be exactly one dependency in deps.")
    dep_label = ctx.attr.deps[0].label
    if dep_label.package != ctx.label.package:
        fail("js_rpc_library '%s' may only depend on a proto_library in the same package, and '%s' is in a different package." % (ctx.label, dep_label))
    proto_info = ctx.attr.deps[0][ProtoInfo]

    js_extension = js_proto_toolchain_info.out_js_extension
    dts_extension = js_proto_toolchain_info.out_dts_extension

    if not ctx.attr.outs and not js_extension and not dts_extension:
        fail("No outputs were specified.")
    if ctx.attr.outs and (js_extension or dts_extension):
        fail("Outputs can be specified on the js_rpc_library or js_rpc_toolchain, but not both.")

    if not proto_info.direct_sources:
        fail("The proto_library must have at least one .proto file source.")

    output_files = []
    if ctx.attr.outs:
        output_files.extend([ctx.actions.declare_file(f, sibling = proto_info.direct_sources[0]) for f in ctx.attr.outs])
    if js_proto_toolchain_info.out_js_extension:
        output_files.extend(proto_common.declare_generated_files(ctx.actions, proto_info, js_proto_toolchain_info.out_js_extension))
    if js_proto_toolchain_info.out_dts_extension:
        output_files.extend(proto_common.declare_generated_files(ctx.actions, proto_info, js_proto_toolchain_info.out_dts_extension))

    proto_common.compile(
        actions = ctx.actions,
        proto_lang_toolchain_info = proto_lang_toolchain_info,
        protoc_info = protoc_info,
        generated_files = output_files,
        proto_info = proto_info,
        mnemonic = "JsRpcProtocGenerate",
        progress_message = "Generating RPC stubs from %{label}",
        host_path_separator = ctx.configuration.host_path_separator,
    )

    js_outputs = depset([f for f in output_files if not f.path.endswith(".d.ts")])
    dts_outputs = depset([f for f in output_files if f.path.endswith(".d.ts")])

    return [
        js_info(
            target = ctx.label,
            sources = js_outputs,
            types = dts_outputs,
            transitive_sources = js_outputs,
            transitive_types = dts_outputs,
            npm_sources = gather_npm_sources(srcs = [], deps = [proto_lang_toolchain_info.runtime]),
            npm_package_store_infos = gather_npm_package_store_infos([proto_lang_toolchain_info.runtime]),
        ),
        DefaultInfo(
            files = js_outputs,
        ),
    ]

js_rpc_library = rule(
    implementation = _js_rpc_library_impl,
    doc = """Generates RPC client stubs from `proto_library` targets using a configurable protoc plugin.

Runs a protoc plugin (such as `protoc-gen-connect-query`) on the specified `proto_library`
targets and provides the generated files as `JsInfo`, allowing them to be used as deps
in any rule that accepts `JsInfo` (`js_library`, `js_binary`, `js_test`, etc.).

Unlike `js_library` with proto deps (which uses `js_proto_aspect` to generate message
serialization code), `js_rpc_library` operates only on its immediate deps and generates
RPC-specific output such as TanStack Query hooks. The expected output filenames must
be declared explicitly in the `outs` attribute; this is required because some plugins
(like `protoc-gen-connect-query`) generate a variable number of files depending on the
number of service definitions in the proto file.

Note that targets using `js_rpc_library` also need access to the message types from
the same proto files, which are provided by a `js_library` that lists the same
`proto_library` targets in its deps.

Example:

```starlark
load("@aspect_rules_js//js:defs.bzl", "js_library", "js_test")
load("@aspect_rules_js//js:rpc.bzl", "js_rpc_library")
load("@protobuf//bazel:proto_library.bzl", "proto_library")

proto_library(
    name = "eliza_proto",
    srcs = ["eliza.proto"],
)

# Generates message serialization code (eliza_pb.js) via js_proto_aspect
js_library(
    name = "eliza_js",
    deps = [":eliza_proto"],
)

# Generates one file per service definition in eliza.proto
js_rpc_library(
    name = "eliza_rpc",
    deps = [":eliza_proto"],
    outs = [
        "eliza-ElizaService_connectquery.js",
        "eliza-ElizaService_connectquery.d.ts",
    ],
)

js_test(
    name = "test",
    entry_point = "test.js",
    data = [":eliza_js", ":eliza_rpc"],
)
```
""",
    attrs = {
        "deps": attr.label_list(
            doc = """`proto_library` targets whose sources will be passed to the RPC plugin.

There must be exactly one target in this list.""",
            providers = [ProtoInfo],
        ),
        "outs": attr.string_list(
            doc = """Explicit list of files the plugin will generate, relative to the package directory.

This parameter must be specified if and only if the registered `js_rpc_toolchain`
does not specify `out_js_extension` or `out_dts_extension`.

These must match exactly the files that the plugin will emit. For `protoc-gen-connect-query`,
one file per service is generated with the naming pattern:
  `{proto_name}-{ServiceName}_connectquery.{js,d.ts}`

For example, for `eliza.proto` containing `service ElizaService`:
  `outs = ["eliza-ElizaService_connectquery.js", "eliza-ElizaService_connectquery.d.ts"]`
""",
        ),
    },
    toolchains = [
        LANG_RPC_TOOLCHAIN,
        PROTOC_TOOLCHAIN,
    ],
)
