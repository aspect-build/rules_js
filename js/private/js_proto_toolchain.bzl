"""Implementation of js_proto_toolchain().

The contents of this file are largely a fork of the proto_lang_toolchain()
rule:
https://github.com/protocolbuffers/protobuf/blob/1115c9e52f96b6549e0ae0f627eb864f569755a8/bazel/private/proto_lang_toolchain_rule.bzl
Copyright 2024 Google Inc.  All rights reserved.

We need our own copy of the rule so that we can have it produce the
JsProtoToolchainInfo provider with additional information specific to
JavaScript or TypeScript code generators.
"""

load("@protobuf//bazel/common:proto_info.bzl", "ProtoInfo")
load("@protobuf//bazel/common:proto_lang_toolchain_info.bzl", "ProtoLangToolchainInfo")
load("//js/private:proto.bzl", "PROTOC_TOOLCHAIN")

JsProtoToolchainInfo = provider(
    doc = "Information on how to invoke the JavaScript or TypeScript protoc plugin.",
    fields = ["output_file_extensions"],
)

def _js_proto_toolchain_impl(ctx):
    denylisted_protos = ctx.attr.denylisted_protos
    provided_proto_sources = depset(transitive = [bp[ProtoInfo].transitive_sources for bp in denylisted_protos]).to_list()

    flag = ctx.attr.command_line
    if flag.find("$(PLUGIN_OUT)") > -1:
        fail("in attribute 'command_line': Placeholder '$(PLUGIN_OUT)' is not supported.")
    flag = flag.replace("$(OUT)", "%s")

    plugin = None
    if ctx.attr.plugin != None:
        plugin = ctx.attr.plugin[DefaultInfo].files_to_run

    proto_compiler = ctx.toolchains[PROTOC_TOOLCHAIN].proto.proto_compiler
    protoc_opts = ctx.toolchains[PROTOC_TOOLCHAIN].proto.protoc_opts

    proto_lang_toolchain_info = ProtoLangToolchainInfo(
        out_replacement_format_flag = flag,
        output_files = ctx.attr.output_files,
        plugin_format_flag = ctx.attr.plugin_format_flag,
        plugin = plugin,
        runtime = ctx.attr.runtime,
        provided_proto_sources = provided_proto_sources,
        proto_compiler = proto_compiler,
        protoc_opts = protoc_opts,
        progress_message = ctx.attr.progress_message,
        mnemonic = ctx.attr.mnemonic,
        allowlist_different_package = None,
        toolchain_type = ctx.attr.toolchain_type.label if ctx.attr.toolchain_type else None,
    )
    return [
        DefaultInfo(files = depset(), runfiles = ctx.runfiles()),
        platform_common.ToolchainInfo(proto = proto_lang_toolchain_info, js = JsProtoToolchainInfo(output_file_extensions = ctx.attr.output_file_extensions)),
    ]

js_proto_toolchain = rule(
    _js_proto_toolchain_impl,
    doc = """
This rule performs the same role as the proto_lang_toolchain() rule, but
additionally produces a JsProtoToolchainInfo() provider that contains
information specifically about how to invoke a JavaScript or TypeScript protoc
plugin.
    """,
    attrs = {
        "progress_message": attr.string(default = "Generating proto_library %{label}", doc = """
This value will be set as the progress message on protoc action."""),
        "mnemonic": attr.string(default = "GenProto", doc = """
This value will be set as the mnemonic on protoc action."""),
        "command_line": attr.string(mandatory = True, doc = """
This value will be passed to proto-compiler to generate the code. Only include the parts
specific to this code-generator/plugin (e.g., do not include -I parameters)
<ul>
  <li><code>$(OUT)</code> is LANG_proto_library-specific. The rules are expected to define
      how they interpret this variable. For Java, for example, $(OUT) will be replaced with
      the src-jar filename to create.</li>
</ul>"""),
        "output_files": attr.string(values = ["single", "multiple", "legacy"], default = "legacy", doc = """
Controls how <code>$(OUT)</code> in <code>command_line</code> is formatted, either by
a path to a single file or output directory in case of multiple files.
Possible values are: "single", "multiple"."""),
        "plugin_format_flag": attr.string(doc = """
If provided, this value will be passed to proto-compiler to use the plugin.
The value must contain a single %s which is replaced with plugin executable.
<code>--plugin=protoc-gen-PLUGIN=&lt;executable&gt;.</code>"""),
        "plugin": attr.label(
            executable = True,
            cfg = "exec",
            doc = """
If provided, will be made available to the action that calls the proto-compiler, and will be
passed to the proto-compiler:
<code>--plugin=protoc-gen-PLUGIN=&lt;executable&gt;.</code>""",
        ),
        "runtime": attr.label(doc = """
A language-specific library that the generated code is compiled against.
The exact behavior is LANG_proto_library-specific.
Java, for example, should compile against the runtime."""),
        "denylisted_protos": attr.label_list(
            providers = [ProtoInfo],
            doc = """
No code will be generated for files in the <code>srcs</code> attribute of
<code>denylisted_protos</code>.
This is used for .proto files that are already linked into proto runtimes, such as
<code>any.proto</code>.""",
        ),
        "toolchain_type": attr.label(),
        "output_file_extensions": attr.string_list(
            doc = """
Indicates the file extensions that the plugin is expected to produce. These are
interpreted as the suffix that should replace ".proto" from the input file
name.
""",
        ),
    },
    toolchains = [PROTOC_TOOLCHAIN],
)
