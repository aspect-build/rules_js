"""Protobuf and gRPC support for JavaScript and TypeScript.

See
- https://connectrpc.com/docs/web/getting-started
- https://connectrpc.com/docs/node/getting-started
"""

load("@protobuf//bazel/toolchains:proto_lang_toolchain.bzl", "proto_lang_toolchain")
load("//js/private:proto.bzl", "LANG_PROTO_TOOLCHAIN")

def js_proto_toolchain(name, **kwargs):
    proto_lang_toolchain(
        name = name,
        toolchain_type = LANG_PROTO_TOOLCHAIN,
        **kwargs
    )
