"""Protobuf and gRPC support for JavaScript and TypeScript.

See
- https://connectrpc.com/docs/web/getting-started
- https://connectrpc.com/docs/node/getting-started
"""

load("@protobuf//bazel/toolchains:proto_lang_toolchain.bzl", "proto_lang_toolchain")
load("//js/private:proto.bzl", "GEN_ES_PLUGIN_TOOLCHAIN")

def js_proto_toolchain(name, protoc_plugin, runtime, command_line = ""):
    """Declare a toolchain for the TypeScript gRPC protoc plugin.

    NB: the toolchain produced by this macro is actually named [name]_toolchain, so THAT is what you must register.
    Even better, make a dedicated 'toolchains' directory and put all your toolchains in there, then register them all with 'register_toolchains("//path/to/toolchains:all")'.
    name: any distinct target name, not used
    plugin: the protoc plugin to use, typically @bufbuild/protoc-gen-es:

        load("@npm//tools:@bufbuild/protoc-gen-es/package_json.bzl", gen_es = "bin")
        gen_es.protoc_gen_es_binary(
            name = "protoc_gen_es",
        )

    runtime: dependency that the generated stub code takes, e.g. "//:node_modules/@bufbuild/protobuf"
    command_line: command line arguments to pass to the protoc compiler, like "--es_opt=keep_empty_files=true --es_opt=target=js+dts --es_opt=import_extension=js"
    """
    proto_lang_toolchain(
        name = name,
        plugin = protoc_plugin,
        toolchain_type = GEN_ES_PLUGIN_TOOLCHAIN,
        command_line = command_line,
        runtime = runtime,
    )
