load("@aspect_rules_js//js:proto.bzl", "js_proto_toolchain")
load("@bazel_skylib//rules:common_settings.bzl", "string_flag")
load("@npm//:ts-proto/package_json.bzl", ts_proto = "bin")
load("@npm//tools:@bufbuild/protoc-gen-es/package_json.bzl", gen_es = "bin")
load("@npm//tools:@connectrpc/protoc-gen-connect-query/package_json.bzl", gen_connect_query = "bin")
load("@npm//tools:@protobuf-ts/plugin/package_json.bzl", protobuf_ts = "bin")

# We define a flag here for determinining which JS protobuf implementation
# should be used. The js_proto_transition_library() rule uses a transition to
# set this flag and thereby control the implementation used in each example.
string_flag(
    name = "js_proto_implementation",
    build_setting_default = "protobuf_es",
    values = [
        "protobuf_es",
        "ts_proto",
        "google_protobuf",
        "protobuf_ts",
    ],
)

config_setting(
    name = "protobuf_es",
    flag_values = {
        ":js_proto_implementation": "protobuf_es",
    },
)

config_setting(
    name = "ts_proto",
    flag_values = {
        ":js_proto_implementation": "ts_proto",
    },
)

config_setting(
    name = "google_protobuf",
    flag_values = {
        ":js_proto_implementation": "google_protobuf",
    },
)

config_setting(
    name = "protobuf_ts",
    flag_values = {
        ":js_proto_implementation": "protobuf_ts",
    },
)

gen_es.protoc_gen_es_binary(
    name = "protoc_gen_es",
)

# FIXME: wire this up to another toolchain_type symbol?
gen_connect_query.protoc_gen_connect_query_binary(
    name = "protoc_gen_connect_query",
)

js_proto_toolchain(
    name = "protobuf_es_toolchain",
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
    target_settings = [":protobuf_es"],
)

ts_proto.protoc_gen_ts_proto_binary(
    name = "protoc_gen_ts_proto",
)

js_proto_toolchain(
    name = "ts_proto_toolchain",
    output_file_extensions = [".ts"],
    plugin_bin = ":protoc_gen_ts_proto",
    plugin_name = "ts_proto",
    plugin_options = [],
    runtime = "//:node_modules/@bufbuild/protobuf",
    target_settings = [":ts_proto"],
)

js_proto_toolchain(
    name = "google_protobuf_toolchain",
    output_file_extensions = [
        "_pb.js",
    ],
    plugin_bin = "@protobuf-javascript//:protoc-gen-js",
    plugin_name = "js",
    plugin_options = [
        "import_style=commonjs",
        "binary",
    ],
    runtime = "//:node_modules/google-protobuf",
    target_settings = [":google_protobuf"],
)

protobuf_ts.protoc_gen_ts_binary(
    name = "protoc_gen_ts",
)

js_proto_toolchain(
    name = "protoc_gen_ts_toolchain",
    output_file_extensions = [".ts"],
    plugin_bin = ":protoc_gen_ts",
    plugin_name = "ts",
    plugin_options = [],
    runtime = "//:node_modules/@protobuf-ts/runtime",
    target_settings = [":protobuf_ts"],
)
