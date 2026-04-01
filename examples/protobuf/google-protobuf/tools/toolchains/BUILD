load("@aspect_rules_js//js:proto.bzl", "js_proto_toolchain")

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
)
