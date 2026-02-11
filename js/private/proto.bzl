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

GEN_ES_PLUGIN_TOOLCHAIN = Label("//js/toolchains:protoc_plugin")
PROTOC_TOOLCHAIN = Label("@protobuf//bazel/private:proto_toolchain_type")
GEN_ES_OUTPUT_FILE = "{proto_file_basename}_pb.js"
GEN_ES_TYPINGS_OUTPUT_FILE = "{proto_file_basename}_pb.d.ts"

# FIXME: support stripping import prefixes
def _js_proto_aspect_impl(target, ctx):
    # Skip generation for well-known-types (is this the right way??)
    # if target.label.workspace_root.startswith("external/protobuf"):
    #     return js_info(target = target.label)

    protoc_info = ctx.toolchains[PROTOC_TOOLCHAIN].proto
    gen_es_info = ctx.toolchains[GEN_ES_PLUGIN_TOOLCHAIN].proto
    deps = [gen_es_info.runtime]
    js_outputs = []
    dts_outputs = []

    for src in target[ProtoInfo].direct_sources:
        proto_file_basename = src.basename.replace(".proto", "")
        js_output = ctx.actions.declare_file(
            GEN_ES_OUTPUT_FILE.format(proto_file_basename = proto_file_basename),
            sibling = src,
        )
        dts_output = ctx.actions.declare_file(
            GEN_ES_TYPINGS_OUTPUT_FILE.format(proto_file_basename = proto_file_basename),
            sibling = src,
        )
        js_outputs.append(js_output)
        dts_outputs.append(dts_output)

    # Follow https://www.npmjs.com/package/@bufbuild/protoc-gen-es
    # Create an action like
    #     bazel-out/k8-opt-exec-2B5CBBC6/bin/external/com_google_protobuf/protoc $@' '' \
    #       '--plugin=protoc-gen-es=bazel-out/k8-opt-exec-2B5CBBC6/bin/plugin/bufbuild/protoc-gen-es.sh' \
    #       '--es_opt=keep_empty_files=true' '--es_opt=target=ts' \
    #       '--es_out=bazel-out/k8-fastbuild/bin' \
    #       '--descriptor_set_in=bazel-out/k8-fastbuild/bin/external/com_google_protobuf/timestamp_proto-descriptor-set.proto.bin:bazel-out/k8-fastbuild/bin/example/thing/thing_proto-descriptor-set.proto.bin:bazel-out/k8-fastbuild/bin/example/place/place_proto-descriptor-set.proto.bin:bazel-out/k8-fastbuild/bin/example/person/person_proto-descriptor-set.proto.bin' \
    #       example/person/person.proto
    args = ctx.actions.args()
    args.add(gen_es_info.plugin.executable, format = "--plugin=protoc-gen-es=%s")

    # args.add_joined(["--es_out", ctx.bin_dir.path], join_with = "=")
    args.add_joined(["--es_out", js_outputs[0].dirname], join_with = "=")
    args.add_all(gen_es_info.out_replacement_format_flag.split(" "))
    args.add("--descriptor_set_in")
    args.add_joined(target[ProtoInfo].transitive_descriptor_sets, join_with = ctx.configuration.host_path_separator)
    args.add_all(target[ProtoInfo].direct_sources)
    ctx.actions.run(
        executable = protoc_info.proto_compiler.executable,
        arguments = [args],
        progress_message = "Generating .js/.d.ts from %{label}",
        mnemonic = "ProtocGenEs",
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
