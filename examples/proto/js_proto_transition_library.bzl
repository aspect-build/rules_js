"""A rule for transitioning a js_library() to a different protobuf implementation."""

load("@aspect_rules_js//js/private:js_info.bzl", "JsInfo")

def _js_proto_toolchain_transition_impl(_settings, attr):
    return {"//tools/toolchains:js_proto_implementation": attr.js_proto_implementation}

_js_proto_toolchain_transition = transition(
    implementation = _js_proto_toolchain_transition_impl,
    inputs = [],
    outputs = ["//tools/toolchains:js_proto_implementation"],
)

def _js_proto_transition_library_impl(ctx):
    # Just forward the providers
    return [
        ctx.attr.target[0][DefaultInfo],
        ctx.attr.target[0][JsInfo],
    ]

js_proto_transition_library = rule(
    implementation = _js_proto_transition_library_impl,
    attrs = {
        "target": attr.label(cfg = _js_proto_toolchain_transition),
        "js_proto_implementation": attr.string(mandatory = True),
    },
)
