"""Rules for running JavaScript programs under Bazel, as tools or with `bazel run` or `bazel test`.

For example, this binary references the `acorn` npm package which was already linked
using an API like `npm_link_all_packages`.

```starlark
load("@aspect_rules_js//js:defs.bzl", "js_binary", "js_test")

js_binary(
    name = "bin",
    # Reference the location where the acorn npm module was linked in the root Bazel package
    data = ["//:node_modules/acorn"],
    entry_point = "require_acorn.js",
)
```
"""

load("@aspect_tools_telemetry_report//:defs.bzl", "TELEMETRY")  # buildifier: disable=load
load(
    "//js/private:js_binary.bzl",
    _js_binary = "js_binary",
    _js_test = "js_test",
)
load(
    "//js/private:js_image_layer.bzl",
    _js_image_layer = "js_image_layer",
)
load(
    "//js/private:js_info_files.bzl",
    _js_info_files = "js_info_files",
)
load(
    "//js/private:js_library.bzl",
    _js_library = "js_library",
)
load(
    "//js/private:js_run_binary.bzl",
    _js_run_binary = "js_run_binary",
)
load(
    "//js/private:js_run_devserver.bzl",
    _js_run_devserver = "js_run_devserver",
)

def js_binary(**kwargs):
    """Execute a program in the Node.js runtime.

    The version of Node.js is determined by Bazel's toolchain selection. Use the `node` extension
    from `rules_nodejs` to register Node.js toolchains. Then Bazel selects from these options
    based on the requested target platform. Use the
    [`--toolchain_resolution_debug`](https://docs.bazel.build/versions/main/command-line-reference.html#flag--toolchain_resolution_debug)
    Bazel option to see more detail about the selection.

    All [common binary attributes](https://bazel.build/reference/be/common-definitions#common-attributes-binaries) are supported
    including `args` as the list of arguments passed Node.js.

    Node.js execution is performed by a shell script that sets environment variables and runs the Node.js binary with the `entry_point` script.
    The shell script is located relative to the directory containing the `js_binary` at `{name}_/{name}` similar to other rulesets
    such as rules_go. See [PR #1690](https://github.com/aspect-build/rules_js/pull/1690) for more information on this naming scheme.

    The following environment variables are made available to the Node.js runtime based on available Bazel [Make variables](https://bazel.build/reference/be/make-variables#predefined_variables):

    * JS_BINARY__BINDIR: the Bazel bin directory; equivalent to the `$(BINDIR)` Make variable of the `js_binary` target
    * JS_BINARY__COMPILATION_MODE: One of `fastbuild`, `dbg`, or `opt` as set by [`--compilation_mode`](https://bazel.build/docs/user-manual#compilation-mode); equivalent to `$(COMPILATION_MODE)` Make variable of the `js_binary` target
    * JS_BINARY__TARGET_CPU: the target cpu architecture; equivalent to `$(TARGET_CPU)` Make variable of the `js_binary` target

    The following environment variables are made available to the Node.js runtime based on the rule context:

    * JS_BINARY__BUILD_FILE_PATH: the path to the BUILD file of the Bazel target being run; equivalent to `ctx.build_file_path` of the `js_binary` target's rule context
    * JS_BINARY__PACKAGE: the package of the Bazel target being run; equivalent to `ctx.label.package` of the `js_binary` target's rule context
    * JS_BINARY__TARGET: the full label of the Bazel target being run; a stringified version of `ctx.label` of the `js_binary` target's rule context
    * JS_BINARY__TARGET_NAME: the name of the Bazel target being run; equivalent to `ctx.label.name` of the `js_binary` target's rule context
    * JS_BINARY__WORKSPACE: the Bazel repository name; equivalent to `ctx.workspace_name` of the `js_binary` target's rule context

    The following environment variables are made available to the Node.js runtime based the runtime environment:

    * JS_BINARY__NODE_BINARY: the Node.js binary path run by the `js_binary` target
    * JS_BINARY__NPM_BINARY: the npm binary path; this is available when [`include_npm`](https://docs.aspect.build/rules/aspect_rules_js/docs/js_binary#include_npm) is `True` on the `js_binary` target
    * JS_BINARY__NODE_WRAPPER: the Node.js wrapper script used to run Node.js which is available as `node` on the `PATH` at runtime
    * JS_BINARY__RUNFILES: the absolute path to the Bazel runfiles directory
    * JS_BINARY__EXECROOT: the absolute path to the root of the execution root for the action; if in the sandbox, this path absolute path to the root of the execution root within the sandbox

    Args:
        **kwargs: All attributes of the [js_binary](#js_binary) rule.
    """

    # Often a js_binary target will set "chdir = package_name()", and if it is
    # in the top-level directory then this will result in an empty string. That
    # argument may still be significant, though, particularly if the target is
    # in an external repo. We make sure to replace an empty string with "." so
    # that the underlying rule can distinguish this from an unset chdir
    # parameter.
    if kwargs.get("chdir") == "":
        kwargs["chdir"] = "."
    _js_binary(
        enable_runfiles = select({
            Label("@bazel_lib//lib:enable_runfiles"): True,
            "//conditions:default": False,
        }),
        **kwargs
    )

def js_test(**kwargs):
    """Identical to js_binary, but usable under `bazel test`.

    All [common test attributes](https://bazel.build/reference/be/common-definitions#common-attributes-tests) are
    supported including `args` as the list of arguments passed Node.js.

    Bazel will set environment variables when a test target is run under `bazel test` and `bazel run`
    that a test runner can use.

    A runner can write arbitrary outputs files it wants Bazel to pickup and save with the test logs to
    `TEST_UNDECLARED_OUTPUTS_DIR`. These get zipped up and saved along with the test logs.

    JUnit XML reports can be written to `XML_OUTPUT_FILE` for Bazel to consume.

    `TEST_TMPDIR` is an absolute path to a private writeable directory that the test runner can use for
    creating temporary files.

    LCOV coverage reports can be written to `COVERAGE_OUTPUT_FILE` when running under `bazel coverage`
    or if the `--coverage` flag is set.

    See the Bazel [Test encyclopedia](https://bazel.build/reference/test-encyclopedia) for details on
    the contract between Bazel and a test runner.

    Args:
        **kwargs: All attributes of the [js_test](#js_test) rule.
    """
    if kwargs.get("chdir") == "":
        kwargs["chdir"] = "."
    _js_test(
        enable_runfiles = select({
            Label("@bazel_lib//lib:enable_runfiles"): True,
            "//conditions:default": False,
        }),
        **kwargs
    )

js_library = _js_library
js_run_devserver = _js_run_devserver
js_run_binary = _js_run_binary
js_info_files = _js_info_files
js_image_layer = _js_image_layer
