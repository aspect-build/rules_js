"""Asserts that js_image_layer rejects a binary it cannot classify.

js_image_layer has to rewrite the launcher for hermeticity, and which file that is depends
on whether the js_binary was built with the bash launcher or the hermetic one. The
`launcher_js` output group is what tells them apart. A binary that does not publish it was
not built on js_binary_lib.create_launcher (or forgot to republish it), and guessing would
mean rewriting a native stub as if it were a shell script -- so it has to fail instead.
"""

load("@bazel_skylib//lib:unittest.bzl", "analysistest", "asserts")

def _fake_binary_impl(ctx):
    executable = ctx.actions.declare_file("{}.sh".format(ctx.label.name))
    ctx.actions.write(executable, "#!/bin/sh\nexit 0\n", is_executable = True)
    return [DefaultInfo(executable = executable)]

# An executable that is not a js_binary, written here rather than taken from sh_binary so
# that the test does not depend on which of native and rules_shell the Bazel under test
# resolves that to.
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
