"""Analysis tests for the coverage merger launcher."""

load("@bazel_skylib//lib:unittest.bzl", "analysistest", "asserts")
load("//js/private/coverage:merger.bzl", "coverage_merger")

def _launcher_test_impl(ctx):
    env = analysistest.begin(ctx)
    target_under_test = analysistest.target_under_test(env)

    executable = target_under_test[DefaultInfo].files_to_run.executable
    runfiles = [
        f.short_path
        for f in target_under_test[DefaultInfo].default_runfiles.files.to_list()
    ]

    if not ctx.attr.is_windows:
        asserts.false(
            env,
            executable.short_path.endswith(".bat"),
            "Expected the bash launcher to be the executable, got {}".format(executable.short_path),
        )
        return analysistest.end(env)

    asserts.true(
        env,
        executable.short_path.endswith(".bat"),
        "Expected a .bat launcher on Windows but got {}".format(executable.short_path),
    )

    # The .bat launcher rlocation()s the bash script it wraps, so that script
    # must be in the runfiles or the launcher fails with
    # "ERROR: <path> not found in runfiles manifest".
    bash_launcher = executable.short_path[:-len(".bat")]
    asserts.true(
        env,
        bash_launcher in runfiles,
        "Expected {} in the runfiles of the .bat launcher, got {}".format(bash_launcher, runfiles),
    )

    return analysistest.end(env)

_launcher_test = analysistest.make(
    _launcher_test_impl,
    attrs = {
        "is_windows": attr.bool(
            doc = "Whether the target platform is Windows, where the bash script is wrapped in a .bat launcher.",
        ),
    },
)

def merger_test_suite(name):
    """Tests for the coverage_merger launcher.

    Args:
        name: Name of the test suite
    """

    coverage_merger(
        name = name + "_subject",
        tags = ["manual"],
    )

    _launcher_test(
        name = name + "_launcher_test",
        target_under_test = ":" + name + "_subject",
        is_windows = select({
            "@platforms//os:windows": True,
            "//conditions:default": False,
        }),
    )

    native.test_suite(
        name = name,
        tests = [":" + name + "_launcher_test"],
    )
