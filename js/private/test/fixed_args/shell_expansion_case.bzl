"""Test macro for asserting on how the bash launcher expands `fixed_args`."""

load("@bazel_lib//lib:diff_test.bzl", "diff_test")
load("@bazel_lib//lib:testing.bzl", "assert_contains")
load("@bazel_skylib//rules:write_file.bzl", "write_file")
load("//js:defs.bzl", "js_binary", "js_run_binary")

def shell_expansion_case(
        name,
        fixed_args,
        data = None,
        env = None,
        expand_args = False,
        srcs = None,
        want_argv = None,
        want_exit_code = None,
        want_stderr = None):
    """Runs a js_binary with `fixed_args` and asserts on the argv its program received.

    Args:
        name: Base name for the generated targets.
        fixed_args: Passed through to js_binary verbatim.
        data: Passed through to js_binary.
        env: Passed through to js_binary.
        expand_args: Passed through to js_binary. Defaults to False.
        srcs: Passed through to js_binary.
        want_argv: The exact argv the program must receive, as a list of strings. The empty
            list asserts it received no arguments at all.
        want_exit_code: The exact exit code of the launcher, as a string. Set this for a
            fixed_arg that keeps the launcher from running; it also keeps the action itself
            successful so the failure can be asserted on.
        want_stderr: A substring the launcher must write to stderr. Kept a substring because
            bash's own diagnostics are not worded identically across versions.
    """
    js_binary(
        name = name + "_bin",
        data = data,
        entry_point = "all_args.mjs",
        env = env,
        expand_args = expand_args,
        # The expected values below are compared byte for byte, so nothing may rewrite them.
        expand_env = False,
        fixed_args = fixed_args,
    )

    js_run_binary(
        name = name + "_run",
        srcs = srcs or [],
        exit_code_out = name + "_exit_code.txt" if want_exit_code != None else None,
        silent_on_success = False,
        stderr = name + "_stderr.txt" if want_stderr != None else None,
        stdout = name + "_stdout.txt" if want_argv != None else None,
        tool = ":" + name + "_bin",
    )

    if want_argv != None:
        # write_file joins with the newline and adds none of its own, so the trailing entry is
        # what matches the newline console.log writes after the last argument.
        write_file(
            name = name + "_want_argv",
            out = name + "_want_argv.txt",
            content = ["[%s]" % arg for arg in want_argv] + [""],
            newline = "unix",
        )
        diff_test(
            name = name + "_test",
            file1 = ":" + name + "_want_argv.txt",
            file2 = ":" + name + "_stdout.txt",
        )

    if want_exit_code != None:
        write_file(
            name = name + "_want_exit_code",
            out = name + "_want_exit_code.txt",
            content = [want_exit_code],
            newline = "unix",
        )
        diff_test(
            name = name + "_exit_code_test",
            file1 = ":" + name + "_want_exit_code.txt",
            file2 = ":" + name + "_exit_code.txt",
        )

    if want_stderr != None:
        assert_contains(
            name = name + "_stderr_test",
            actual = ":" + name + "_stderr.txt",
            expected = want_stderr,
        )
