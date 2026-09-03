"""Asserts that js_image_layer rejects a binary it cannot classify.

js_image_layer has to rewrite the launcher for hermeticity, and which file that is depends
on whether the js_binary was built with the bash launcher or the hermetic one. The
`launcher_js` output group is what tells them apart, so if this is missing then
js_image_layer should fail.
"""

load("@bazel_skylib//lib:unittest.bzl", "analysistest", "asserts")

def _fake_binary_impl(ctx):
    executable = ctx.actions.declare_file("{}.sh".format(ctx.label.name))
    ctx.actions.write(executable, "#!/bin/sh\nexit 0\n", is_executable = True)
    return [DefaultInfo(executable = executable)]

fake_binary = rule(
    implementation = _fake_binary_impl,
    executable = True,
)

def _not_js_binary_test_impl(ctx):
    env = analysistest.begin(ctx)
    asserts.expect_failure(env, "not a js_binary")
    return analysistest.end(env)

not_js_binary_test = analysistest.make(
    _not_js_binary_test_impl,
    expect_failure = True,
)
