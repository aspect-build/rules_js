"""**EXPERIMENTAL**: Protobuf and gRPC support for JavaScript and TypeScript.

This API is subject to breaking changes outside our usual semver policy.
In a future release of rules_js this should become stable.

### Typical setup

1. Choose any code generator plugin for protoc.
   In this example we'll show `@bufbuild/protoc-gen-es` that produces both message marshaling and service stubs for JavaScript and TypeScript.
   It should be added as a devDependency in your `package.json`, typically under a `/tools` directory.
   The generator is expected to produce `.js` and `.d.ts` files for each .proto file.
2. Declare a binary target that runs the generator, typically using its package_json.bzl entry point, for example:

```starlark
load("@npm//tools:@bufbuild/protoc-gen-es/package_json.bzl", gen_es = "bin")
gen_es.protoc_gen_es_binary(
    name = "protoc_gen_es",
)
```
3. Define a `js_proto_toolchain` that uses the plugin. See the rule documentation below.
4. Update `MODULE.bazel` to register it, typically with a simple statement like `register_toolchains("//tools/toolchains:all")`

### Usage

Just write `proto_library` targets as usual, or have Gazelle generate them.
Then reference them anywhere a js_library could appear, for example:

```starlark
load("@aspect_rules_js//js:defs.bzl", "js_library")
load("@protobuf//bazel:proto_library.bzl", "proto_library")

proto_library(
    name = "eliza_proto",
    srcs = ["eliza.proto"],
)

js_library(
    name = "proto",
    srcs = ["package.json"],
    deps = [":eliza_proto"],
)
```

The generator you setup earlier will be invoked automatically as an action to generate the .js and .d.ts files.
"""

load("@protobuf//bazel/toolchains:proto_lang_toolchain.bzl", "proto_lang_toolchain")
load("//js/private:proto.bzl", "LANG_PROTO_TOOLCHAIN")

def js_proto_toolchain(name, plugin_name, plugin_options, plugin_bin, runtime, **kwargs):
    """Define a proto_lang_toolchain that uses the plugin.

    Example:

    ```starlark
    js_proto_toolchain(
        name = "gen_es_protoc_plugin",
        plugin_bin = ":protoc_gen_es",
        plugin_name = "es",
        # See https://github.com/bufbuild/protobuf-es/tree/main/packages/protoc-gen-es#plugin-options
        plugin_options = [
            "keep_empty_files=true",
            "target=js+dts",
            "import_extension=js",
        ],
        runtime = "//:node_modules/@bufbuild/protobuf",
    )
    ```

    Args:
        name: The name of the toolchain. A target named [name]_toolchain is also created, which is the one to be used in register_toolchains.
        plugin_name: The `NAME` of the plugin program, used in command-line flags to protoc, as follows:

            > `protoc --plugin=protoc-gen-NAME=path/to/mybinary --NAME_out=OUT_DIR`

            See https://protobuf.dev/reference/cpp/api-docs/google.protobuf.compiler.plugin

        plugin_options: (List of strings) Command line flags used to invoke the plugin, based on documentation for the generator.

            For example, for @bufbuild/protoc-gen-es, reference
            https://github.com/bufbuild/protobuf-es/tree/main/packages/protoc-gen-es#plugin-options

            `["--es_opt=import_extension=js", "--es_out=$(OUT)"]`

        plugin_bin: The plugin to use. This should be a label of a binary target that you declared in step 2 above.
        runtime: The runtime to use, which is imported by the generated code. For example, "//:node_modules/@bufbuild/protobuf".

            Note that node module resolution requires the runtime to be in a parent folder of any package containing generated code.

        **kwargs: Additional arguments to pass to the [proto_lang_toolchain](https://bazel.build/reference/be/protocol-buffer#proto_lang_toolchain) rule.
    """
    command_line_flags = ["--{}_opt=%s".format(plugin_name) % o for o in plugin_options]
    command_line_flags.append("--{}_out=$(OUT)".format(plugin_name))
    proto_lang_toolchain(
        name = name,
        command_line = " ".join(command_line_flags),
        plugin_format_flag = "--plugin=protoc-gen-{}=%s".format(plugin_name),
        toolchain_type = LANG_PROTO_TOOLCHAIN,
        plugin = plugin_bin,
        runtime = runtime,
        **kwargs
    )
