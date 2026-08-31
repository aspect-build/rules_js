"""Test-only rule that drives the js_binary launcher's own capture support directly.

`js_run_binary` delegates stdout/stderr/exit_code_out/silent_on_success to bazel-lib's
`run_binary`, so nothing in this repo routes the JS_BINARY__*_OUTPUT_FILE and
JS_BINARY__SILENT_ON_SUCCESS environment variables through the launcher anymore. Code outside
rules_js does invoke the launcher directly and set them (see #2955), so the launcher still honors
them and this rule keeps that path covered.
"""

load("@aspect_rules_js//js:libs.bzl", "js_binary_lib")

def _direct_capture_impl(ctx):
    stdout = ctx.outputs.stdout
    stderr = ctx.outputs.stderr
    exit_code = ctx.outputs.exit_code_out
    outputs = [stdout, stderr, exit_code]

    no_runfiles_env = {}
    execution_requirements = {}
    if ctx.attr.no_runfiles:
        no_runfiles_env["JS_BINARY__NO_RUNFILES"] = "1"

        # Resolving the entry point in the output tree only finds it when the tool's files are laid
        # out at their real paths, which is the case for a local unsandboxed action; a sandboxed or
        # remotely executed one stages them inside the tool's runfiles tree instead. That is no
        # constraint on Windows, the platform that turns JS_BINARY__NO_RUNFILES on, since it has no
        # sandbox, but this action has to ask for those conditions on the platforms that do.
        execution_requirements["no-sandbox"] = "1"
        execution_requirements["no-remote-exec"] = "1"

    js_binary_lib.run_binary_action(
        ctx = ctx,
        executable = ctx.executable.tool,
        outputs = outputs,
        mnemonic = "DirectCapture",
        execution_requirements = execution_requirements,
        env = no_runfiles_env | {
            # short_path is bin-relative and File.path is execroot-relative
            # ("bazel-out/<cfg>/bin/..."), so using a different one per stream covers both in a
            # single action.
            "JS_BINARY__STDOUT_OUTPUT_FILE": stdout.short_path,
            "JS_BINARY__STDERR_OUTPUT_FILE": stderr.path,
            "JS_BINARY__EXIT_CODE_OUTPUT_FILE": exit_code.short_path,
            # Set alongside the capture files, which is the case where the launcher writes each
            # stream straight to its output file rather than buffering it in a temp file.
            "JS_BINARY__SILENT_ON_SUCCESS": "1",
        },
    )

    return [DefaultInfo(files = depset(outputs))]

_direct_capture = rule(
    doc = "Runs a js_binary tool with the launcher's capture environment variables set.",
    implementation = _direct_capture_impl,
    attrs = {
        "tool": attr.label(
            doc = "The js_binary to run.",
            executable = True,
            allow_files = True,
            mandatory = True,
            cfg = "exec",
        ),
        "stdout": attr.output(mandatory = True),
        "stderr": attr.output(mandatory = True),
        "exit_code_out": attr.output(mandatory = True),
        "no_runfiles": attr.bool(
            doc = """Set JS_BINARY__NO_RUNFILES on the action, as the launcher itself does on
Windows when runfiles are disabled. The launcher then resolves its entry point in the output tree
rather than the runfiles tree, which is only exercised on Windows otherwise.""",
        ),
    },
)

def direct_capture(name, tool, **kwargs):
    """Declares a _direct_capture target with conventionally named capture outputs.

    Args:
        name: Target name. The capture outputs are `<name>_stdout.txt`, `<name>_stderr.txt` and
            `<name>_exit_code.txt`.
        tool: The js_binary to run.
        **kwargs: Additional arguments forwarded to the rule.
    """
    _direct_capture(
        name = name,
        tool = tool,
        stdout = "{}_stdout.txt".format(name),
        stderr = "{}_stderr.txt".format(name),
        exit_code_out = "{}_exit_code.txt".format(name),
        **kwargs
    )
