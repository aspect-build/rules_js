"""Wrapper macro that passes Label values for the capture attributes.

The capture attributes feed an attr.output_list, which accepts Label values as
well as strings, so a wrapper macro is free to pass Label(":out").
"""

load("//js:defs.bzl", "js_run_binary")

def label_capture(name, tool):
    js_run_binary(
        name = name,
        tool = tool,
        silent_on_success = False,
        stdout = Label(":{}_stdout.txt".format(name)),
        stderr = Label(":{}_stderr.txt".format(name)),
        exit_code_out = Label(":{}_exit_code.txt".format(name)),
        use_execroot_entry_point = False,
    )
