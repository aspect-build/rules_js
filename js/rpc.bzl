"""**EXPERIMENTAL**: RPC support for JavaScript and TypeScript.

Note that if you are using Connect, you do not need any additional setup beyond
registering protoc-gen-es with a js_proto_toolchain. As of v2, protoc-gen-es
generates code for Connect right alongside the protobuf-es code, in the same
file.

This API is subject to breaking changes outside our usual semver policy.
In a future release of rules_js this should become stable.

### Typical setup

1. Choose a protoc plugin that generates RPC client code.
   A common choice is `@connectrpc/protoc-gen-connect-query`, which generates
   TanStack Query hooks for services defined in your proto files.
   Add it as a devDependency in `package.json` under a `/tools` directory.

2. Declare a binary target that runs the generator, in `tools/toolchains/BUILD`:

```starlark
load("@npm//tools:@connectrpc/protoc-gen-connect-query/package_json.bzl", connect_query = "bin")
connect_query.protoc_gen_connect_query_binary(name = "protoc_gen_connect_query")
```

3. Define a `js_rpc_toolchain` that uses the plugin. See the rule documentation below.

4. Update `MODULE.bazel` to register it:
```starlark
register_toolchains("//tools/toolchains:all")
```

### Usage

Write `proto_library` targets with `service` definitions as usual. Use `js_library`
with proto deps to generate message serialization code, and `js_rpc_library` to generate
the RPC client stubs:

```starlark
load("@aspect_rules_js//js:defs.bzl", "js_library")
load("@aspect_rules_js//js:rpc.bzl", "js_rpc_library")
load("@protobuf//bazel:proto_library.bzl", "proto_library")

proto_library(
    name = "eliza_proto",
    srcs = ["eliza.proto"],
)

# Generates message serialization code (eliza_pb.js) via js_proto_aspect
js_library(
    name = "eliza_js",
    deps = [":eliza_proto"],
)

# Generates one file per service via protoc-gen-connect-query
js_rpc_library(
    name = "eliza_rpc",
    deps = [":eliza_proto"],
    outs = [
        "eliza-ElizaService_connectquery.js",
        "eliza-ElizaService_connectquery.d.ts",
    ],
)
```

See the e2e/protobuf-es example for a ConnectQuery setup, or e2e/protobuf-google for a grpc-js setup.
"""

load("//js/private:js_proto_toolchain.bzl", _js_proto_toolchain = "js_proto_toolchain")
load("//js/private:rpc.bzl", "LANG_RPC_TOOLCHAIN", _js_rpc_library = "js_rpc_library")

js_rpc_library = _js_rpc_library

def js_rpc_toolchain(name, plugin_name, plugin_options, plugin_bin, runtime, out_dts_extension = None, out_js_extension = None, target_settings = [], exec_compatible_with = [], target_compatible_with = [], **kwargs):
    """Define a toolchain for a protoc plugin that generates RPC client code.

    Example:

    ```starlark
    js_rpc_toolchain(
        name = "connect_query_toolchain",
        plugin_bin = ":protoc_gen_connect_query",
        plugin_name = "connect-query",
        plugin_options = [
            "target=js+dts",
            "import_extension=js",
        ],
        runtime = "//:node_modules/@connectrpc/connect-query-core",
    )
    ```

    Args:
        name: The name of the toolchain. A target named [name]_toolchain is also created, which is the one to use in register_toolchains.
        plugin_name: The `NAME` of the plugin program, used in command-line flags to protoc, as follows:

            > `protoc --plugin=protoc-gen-NAME=path/to/mybinary --NAME_out=OUT_DIR`

            See https://protobuf.dev/reference/cpp/api-docs/google.protobuf.compiler.plugin

        plugin_options: (List of strings) Option strings passed to the plugin via --NAME_opt=.

        plugin_bin: The plugin binary. This should be the label of a binary target declared using the plugin's package_json.bzl entry point.
        runtime: The npm package that the generated code imports from at runtime.

            Note that node module resolution requires the runtime to be in a parent folder of any package containing generated code.

        out_dts_extension: The suffix that should replace ".proto" in determining the .d.ts output file name, or None if the plugin does not produce a type declaration file.
        out_js_extension: The suffix that should replace ".proto" in determining the .js output file name.

            If neither of the two above parameters are set, then each js_rpc_library target must indicate its expected outputs via the outs parameter.

        target_settings: List of target config settings the toolchain is compatible with.
        exec_compatible_with: List of constraint_values that the execution platform must be compatible with.
        target_compatible_with: List of constraint values that the target platform must be compatible with.

        **kwargs: Additional arguments to pass to the underlying rule.
    """
    command_line_flags = ["--{}_opt={}".format(plugin_name, o) for o in plugin_options]
    command_line_flags.append("--{}_out=$(OUT)".format(plugin_name))
    _js_proto_toolchain(
        name = name,
        command_line = " ".join(command_line_flags),
        plugin_format_flag = "--plugin=protoc-gen-{}=%s".format(plugin_name),
        toolchain_type = LANG_RPC_TOOLCHAIN,
        plugin = plugin_bin,
        out_dts_extension = out_dts_extension,
        out_js_extension = out_js_extension,
        runtime = runtime,
        **kwargs
    )
    native.toolchain(
        name = name + "_toolchain",
        toolchain_type = LANG_RPC_TOOLCHAIN,
        toolchain = name,
        target_settings = target_settings,
        exec_compatible_with = exec_compatible_with,
        target_compatible_with = target_compatible_with,
    )
