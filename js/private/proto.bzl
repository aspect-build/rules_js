"""An aspect that generates JavaScript and TypeScript code from .proto files.

This Bazel integration follows the "Local Generation" mechanism described at
https://connectrpc.com/docs/web/generating-code#local-generation,
using packages such as `@bufbuild/protoc-gen-es` and `@connectrpc/protoc-gen-connect-query`
as plugins to protoc.

The aspect converts a ProtoInfo provider into a JsInfo provider so that proto_library may be a dep to JS rules.
"""

load("@protobuf//bazel/common:proto_info.bzl", "ProtoInfo")
load("//js:providers.bzl", "JsInfo", "js_info")
load(
    "//js/private:js_helpers.bzl",
    "gather_npm_package_store_infos",
    "gather_npm_sources",
    "gather_transitive_sources",
    "gather_transitive_types",
)
load(":proto_common.bzl", "proto_common")

GEN_ES_PLUGIN_TOOLCHAIN = Label("//js/toolchains:protoc_plugin")
PROTOC_TOOLCHAIN = Label("@protobuf//bazel/private:proto_toolchain_type")

def _js_proto_aspect_impl(target, ctx):
    protoc_info = ctx.toolchains[PROTOC_TOOLCHAIN].proto
    gen_es_info = ctx.toolchains[GEN_ES_PLUGIN_TOOLCHAIN].proto
    deps = [gen_es_info.runtime]
    js_outputs = proto_common.declare_generated_files(ctx.actions, target[ProtoInfo], "_pb.js")
    dts_outputs = proto_common.declare_generated_files(ctx.actions, target[ProtoInfo], "_pb.d.ts")

    args = ctx.actions.args()
    args.add(gen_es_info.plugin.executable, format = gen_es_info.plugin_format_flag)
    proto_outdir = proto_common.output_directory(target[ProtoInfo], js_outputs[0].root)
    args.add_all((gen_es_info.out_replacement_format_flag % proto_outdir).split(" "))
    args.add("--descriptor_set_in")
    args.add_joined(target[ProtoInfo].transitive_descriptor_sets, join_with = ctx.configuration.host_path_separator)

    # Vendored: https://github.com/protocolbuffers/protobuf/blob/v31.1/bazel/common/proto_common.bzl#L193-L204
    # Protoc searches for .protos -I paths in order they are given and then
    # uses the path within the directory as the package.
    # This requires ordering the paths from most specific (longest) to least
    # specific ones, so that no path in the list is a prefix of any of the
    # following paths in the list.
    # For example: 'bazel-out/k8-fastbuild/bin/external/foo' needs to be listed
    # before 'bazel-out/k8-fastbuild/bin'. If not, protoc will discover file under
    # the shorter path and use 'external/foo/...' as its package path.
    args.add_all(target[ProtoInfo].transitive_proto_path, map_each = proto_common.import_virtual_proto_path)
    args.add_all(target[ProtoInfo].transitive_proto_path, map_each = proto_common.import_repo_proto_path)
    args.add_all(target[ProtoInfo].transitive_proto_path, map_each = proto_common.import_main_output_proto_path)
    args.add("-I.")  # Needs to come last

    args.add_all(target[ProtoInfo].direct_sources)
    ctx.actions.run(
        executable = protoc_info.proto_compiler.executable,
        arguments = [args],
        progress_message = "Generating .js/.d.ts from %{label}",
        mnemonic = "JsProtocGenerate",
        env = {"BAZEL_BINDIR": ctx.bin_dir.path},
        tools = [gen_es_info.plugin, protoc_info.proto_compiler],
        inputs = depset(target[ProtoInfo].direct_sources, transitive = [target[ProtoInfo].transitive_descriptor_sets]),
        outputs = js_outputs + dts_outputs,
        use_default_shell_env = True,
    )

    return [
        js_info(
            target = ctx.label,
            sources = depset(js_outputs),
            types = depset(dts_outputs),
            transitive_sources = gather_transitive_sources(js_outputs, ctx.rule.attr.deps),
            transitive_types = gather_transitive_types(dts_outputs, ctx.rule.attr.deps),
            npm_sources = gather_npm_sources(srcs = [], deps = deps),
            npm_package_store_infos = gather_npm_package_store_infos(deps),
        ),
    ]

js_proto_aspect = aspect(
    implementation = _js_proto_aspect_impl,
    # Traverse the "deps" graph edges starting from the target
    attr_aspects = ["deps"],
    # Only visit nodes that produce a ProtoInfo provider
    required_providers = [ProtoInfo],
    # Be a valid dependency of a ts_project rule
    provides = [JsInfo],
    toolchains = [
        GEN_ES_PLUGIN_TOOLCHAIN,
        PROTOC_TOOLCHAIN,
    ],
)
