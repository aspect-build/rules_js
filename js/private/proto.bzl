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
PROTOC_TOOLCHAIN = "@protobuf//bazel/private:proto_toolchain_type"
GEN_ES_OUTPUT_FILE = "{proto_file_basename}_pb.js"
GEN_ES_TYPINGS_OUTPUT_FILE = "{proto_file_basename}_pb.d.ts"

# FIXME: support stripping import prefixes
def _js_proto_aspect_impl(target, ctx):
    if not ProtoInfo in target:
        # Should not be possible, since our aspect declaration has required_providers = [ProtoInfo]
        fail("ts_proto_aspect_impl: target %s does not provide ProtoInfo" % target.label)

    # Skip generation for well-known-types (is this the right way??)
    if target.label.workspace_root.startswith("external/protobuf"):
        return js_info(target = target.label)

    protoc_info = ctx.toolchains[PROTOC_TOOLCHAIN].proto
    gen_es_info = ctx.toolchains[GEN_ES_PLUGIN_TOOLCHAIN].proto
    deps = [gen_es_info.runtime]
    js_outputs = []
    dts_outputs = []

    for src in target[ProtoInfo].direct_sources:
        proto_file_basename = src.basename.replace(".proto", "")
        js_output = ctx.actions.declare_file(GEN_ES_OUTPUT_FILE.format(proto_file_basename = proto_file_basename))
        dts_output = ctx.actions.declare_file(GEN_ES_TYPINGS_OUTPUT_FILE.format(proto_file_basename = proto_file_basename))

        # Follow https://www.npmjs.com/package/@bufbuild/protoc-gen-es
        # Create an action like
        #     bazel-out/k8-opt-exec-2B5CBBC6/bin/external/com_google_protobuf/protoc $@' '' \
        #       '--plugin=protoc-gen-es=bazel-out/k8-opt-exec-2B5CBBC6/bin/plugin/bufbuild/protoc-gen-es.sh' \
        #       '--es_opt=keep_empty_files=true' '--es_opt=target=ts' \
        #       '--es_out=bazel-out/k8-fastbuild/bin' \
        #       '--descriptor_set_in=bazel-out/k8-fastbuild/bin/external/com_google_protobuf/timestamp_proto-descriptor-set.proto.bin:bazel-out/k8-fastbuild/bin/example/thing/thing_proto-descriptor-set.proto.bin:bazel-out/k8-fastbuild/bin/example/place/place_proto-descriptor-set.proto.bin:bazel-out/k8-fastbuild/bin/example/person/person_proto-descriptor-set.proto.bin' \
        #       example/person/person.proto
        args = ctx.actions.args()
        args.add_joined(["--plugin", "protoc-gen-es", gen_es_info.plugin.executable], join_with = "=")
        args.add_joined(["--es_out", ctx.bin_dir.path], join_with = "=")
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
            outputs = [js_output, dts_output],
            use_default_shell_env = True,
        )
        js_outputs.append(js_output)
        dts_outputs.append(dts_output)

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

# def _windows_path_normalize(path):
#     """Changes forward slashs to backslashs for Windows paths."""
#     host_is_windows = platform_utils.host_platform_is_windows()
#     if host_is_windows:
#         return path.replace("/", "\\")
#     return path

# # Vendored: https://github.com/protocolbuffers/protobuf/blob/v31.1/bazel/common/proto_common.bzl#L15-L23
# def _import_virtual_proto_path(path):
#     """Imports all paths for virtual imports.

#       They're of the form:
#       'bazel-out/k8-fastbuild/bin/external/foo/e/_virtual_imports/e' or
#       'bazel-out/foo/k8-fastbuild/bin/e/_virtual_imports/e'"""
#     if path.count("/") > 4:
#         return "-I%s" % path
#     return None

# # Vendored: https://github.com/protocolbuffers/protobuf/blob/v31.1/bazel/common/proto_common.bzl#L25-L34
# def _import_repo_proto_path(path):
#     """Imports all paths for generated files in external repositories.

#       They are of the form:
#       'bazel-out/k8-fastbuild/bin/external/foo' or
#       'bazel-out/foo/k8-fastbuild/bin'"""
#     path_count = path.count("/")
#     if path_count > 2 and path_count <= 4:
#         return "-I%s" % path
#     return None

# # Vendored: https://github.com/protocolbuffers/protobuf/blob/v31.1/bazel/common/proto_common.bzl#L36-L46
# def _import_main_output_proto_path(path):
#     """Imports all paths for generated files or source files in external repositories.

#       They're of the form:
#       'bazel-out/k8-fastbuild/bin'
#       'external/foo'
#       '../foo'
#     """
#     if path.count("/") <= 2 and path != ".":
#         return "-I%s" % path
#     return None

# # buildifier: disable=function-docstring-header
# def _protoc_action(ctx, proto_info, outputs):
#

#     # ensure that bin_dir doesn't get duplicated in the path
#     # e.g. by proto_library(strip_import_prefix=...)
#     proto_root = proto_info.proto_source_root
#     if proto_root.startswith(ctx.bin_dir.path):
#         proto_root = proto_root[len(ctx.bin_dir.path) + 1:]
#     plugin_output = ctx.bin_dir.path + "/" + proto_root

#     # Vendored: https://github.com/protocolbuffers/protobuf/blob/v31.1/bazel/common/proto_common.bzl#L193-L204
#     # Protoc searches for .protos -I paths in order they are given and then
#     # uses the path within the directory as the package.
#     # This requires ordering the paths from most specific (longest) to least
#     # specific ones, so that no path in the list is a prefix of any of the
#     # following paths in the list.
#     # For example: 'bazel-out/k8-fastbuild/bin/external/foo' needs to be listed
#     # before 'bazel-out/k8-fastbuild/bin'. If not, protoc will discover file under
#     # the shorter path and use 'external/foo/...' as its package path.
#     args.add_all(proto_info.transitive_proto_path, map_each = _import_virtual_proto_path)
#     args.add_all(proto_info.transitive_proto_path, map_each = _import_repo_proto_path)
#     args.add_all(proto_info.transitive_proto_path, map_each = _import_main_output_proto_path)
#     args.add("-I.")  # Needs to come last

# def _declare_outs(ctx, info, ext):
#     outs = proto_common.declare_generated_files(ctx.actions, info, "_pb" + ext)
#     if ctx.attr.gen_connect_es:
#         outs.extend(proto_common.declare_generated_files(ctx.actions, info, "_connect" + ext))
#     if ctx.attr.gen_connect_query:
#         proto_sources = info.direct_sources
#         proto_source_map = {src.basename: src for src in proto_sources}

#         # FIXME: we should refer to source files via labels instead of filenames
#         for proto, services in ctx.attr.gen_connect_query_service_mapping.items():
#             if not proto in proto_source_map:
#                 fail("{} is not provided by proto_srcs".format(proto))
#             src = proto_source_map.get(proto)
#             prefix = proto.replace(".proto", "")
#             for service in services:
#                 outs.append(ctx.actions.declare_file("{}-{}_connectquery{}".format(prefix, service, ext), sibling = src))

#     return outs
