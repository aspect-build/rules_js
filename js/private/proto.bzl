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

LANG_PROTO_TOOLCHAIN = Label("//js/toolchains:protoc_plugin")
PROTOC_TOOLCHAIN = Label("@protobuf//bazel/private:proto_toolchain_type")

def _original_import(canonical_path, js_extension):
    return "./" + canonical_path.replace(".proto", js_extension)

def _replacement(package, name):
    return ("./" + package if package else ".") + "/_virtual_imports/" + name

def _get_import_rewrites(deps, js_extension):
    rewrites = []
    for dep in deps:
        proto_source_root = dep[ProtoInfo].proto_source_root
        if not proto_source_root.endswith("/"):
            proto_source_root = proto_source_root + "/"
        if proto_source_root.find("/_virtual_imports/") != -1:
            for source in dep[ProtoInfo].direct_sources:
                canonical_path = source.path.removeprefix(proto_source_root)
                rewrites.append(_original_import(canonical_path, js_extension) + ":" + _replacement(dep.label.package, dep.label.name))
    return rewrites

def _js_proto_aspect_impl(target, ctx):
    proto_info = target[ProtoInfo]
    protoc_info = ctx.toolchains[PROTOC_TOOLCHAIN].proto
    proto_lang_toolchain_info = ctx.toolchains[LANG_PROTO_TOOLCHAIN].proto
    js_proto_toolchain_info = ctx.toolchains[LANG_PROTO_TOOLCHAIN].js

    js_outputs = proto_common.declare_generated_files(ctx.actions, proto_info, js_proto_toolchain_info.out_js_extension)
    dts_extension = js_proto_toolchain_info.out_dts_extension
    dts_outputs = proto_common.declare_generated_files(ctx.actions, proto_info, dts_extension) if dts_extension else []

    all_outputs = js_outputs + dts_outputs

    # Tell the plugin how to fix up imports to account for any usage of
    # import_prefix or strip_import_prefix on dependencies. For now we only do
    # this with protoc-gen-es, but ideally we should generalize this logic to
    # accommodate other plugins.
    rewrite_args = None
    if proto_lang_toolchain_info.plugin_format_flag.startswith("--plugin=protoc-gen-es="):
        rewrite_args = [
            "--es_opt=rewrite_imports=" + r
            for r in _get_import_rewrites(ctx.rule.attr.deps, js_proto_toolchain_info.out_js_extension)
        ]

    proto_common.compile(
        actions = ctx.actions,
        proto_lang_toolchain_info = proto_lang_toolchain_info,
        protoc_info = protoc_info,
        generated_files = all_outputs,
        proto_info = proto_info,
        mnemonic = "JsProtocGenerate",
        progress_message = "Generating .js/.d.ts from %{label}",
        host_path_separator = ctx.configuration.host_path_separator,
        additional_args = rewrite_args,
    )

    return [
        js_info(
            target = ctx.label,
            sources = depset(js_outputs),
            types = depset(dts_outputs),
            transitive_sources = gather_transitive_sources(js_outputs, ctx.rule.attr.deps),
            transitive_types = gather_transitive_types(dts_outputs, ctx.rule.attr.deps),
            npm_sources = gather_npm_sources(srcs = [], deps = [proto_lang_toolchain_info.runtime]),
            npm_package_store_infos = gather_npm_package_store_infos([proto_lang_toolchain_info.runtime]),
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
        LANG_PROTO_TOOLCHAIN,
        PROTOC_TOOLCHAIN,
    ],
)
