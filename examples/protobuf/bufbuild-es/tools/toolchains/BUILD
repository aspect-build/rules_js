load("@aspect_rules_js//js:proto.bzl", "js_proto_toolchain")
load("@npm//tools:@bufbuild/protoc-gen-es/package_json.bzl", gen_es = "bin")

gen_es.protoc_gen_es_binary(
    name = "protoc_gen_es",
)

js_proto_toolchain(
    name = "protobuf_es_toolchain",
    output_file_extensions = [
        "_pb.js",
        "_pb.d.ts",
    ],
    plugin_bin = ":protoc_gen_es",
    plugin_name = "es",
    # See https://github.com/connectrpc/connect-es/blob/main/MIGRATING.md#update-plugin-options
    # and https://github.com/bufbuild/protobuf-es/tree/main/packages/protoc-gen-es#plugin-options
    plugin_options = [
        "keep_empty_files=true",
        "target=js+dts",
        "import_extension=js",
    ],
    # NB: this must be a parent folder of any package that use the toolchain
    # Otherwise typescript won't resolve a dep from the generated code in that package to the @bufbuild/protobuf package
    runtime = "//:node_modules/@bufbuild/protobuf",
)
