"""A macro for running a JS or TS test using a specific protobuf implementation."""

load("@aspect_rules_js//js:defs.bzl", "js_test")

def _js_proto_toolchain_transition_impl(_settings, attr):
    return {"//tools/toolchains:js_proto_implementation": attr.js_proto_implementation}

_js_proto_toolchain_transition = transition(
    implementation = _js_proto_toolchain_transition_impl,
    inputs = [],
    outputs = ["//tools/toolchains:js_proto_implementation"],
)

def _js_proto_test_impl(ctx):
    # Bazel does not allow one rule to forward an executable from another rule,
    # so we need to create a new executable that just invokes the original one.
    actual_exe = ctx.attr.actual[0][DefaultInfo].files_to_run.executable
    out_exe = ctx.actions.declare_file(ctx.label.name)
    ctx.actions.write(
        output = out_exe,
        content = "#!/bin/bash\nexec ./%s \"$@\"\n" % actual_exe.short_path,
        is_executable = True,
    )

    return [
        DefaultInfo(
            executable = out_exe,
            runfiles = ctx.runfiles(files = [actual_exe]).merge(
                ctx.attr.actual[0][DefaultInfo].default_runfiles,
            ),
        ),
    ]

_js_proto_test = rule(
    implementation = _js_proto_test_impl,
    attrs = {
        "actual": attr.label(cfg = _js_proto_toolchain_transition),
        "js_proto_implementation": attr.string(),
    },
    test = True,
)

def js_proto_test(name, js_proto_implementation, **kwargs):
    """Define a js_test() using a specific protobuf implementation.

    This macro provides a thin wrapper around js_test(), and uses a transition
    to select a specific protobuf implementation for the test.

    Args:
        name: The name of the test target.
        js_proto_implementation: The name of the JavaScript or TypeScript
            protobuf implementation to use. This can be any of the values of the flag
            //tools/toolchains:js_proto_implementation.
        **kwargs: Arguments to pass to js_test().
    """
    js_test(
        name = name + "_wrapped",
        tags = ["manual"],
        **kwargs
    )
    _js_proto_test(
        name = name,
        testonly = True,
        actual = name + "_wrapped",
        js_proto_implementation = js_proto_implementation,
    )
