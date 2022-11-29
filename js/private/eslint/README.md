# Linting experiment

This shows different ways to run eslint over a codebase.

It can be held in a few ways:

## As a test

This is probably what most users do today.
If you want to enable for a whole repository, you'd write a wrapper macro that stamps out the extra target,
then change all your `load` statements to get js_library/ts_project from that.

The downside is that you're always forced to fix/suppress every lint warning before you can enable it.

The simplest way to write it is next to a js_library/ts_project rule:

```
bin.eslint_test(
    name = "lint_as_test",
    args = [
        "--config",
        ".eslintrc.yml",
        "$(execpath one.js)",
    ],
    data = [
        "one.js",
        "//:.eslintrc",
    ],
)
```

and it looks like this:

```
$ bazel test //examples/js_library/one:lint_as_test
FAIL: //examples/js_library/one:lint_as_test (see /shared/cache/bazel/user_base/581b2ac03dd093577e8a6ba6b6509be5/execroot/aspect_rules_js/bazel-out/k8-fastbuild/testlogs/examples/js_library/one/lint_as_test/test.log)
INFO: From Testing //examples/js_library/one:lint_as_test:
==================== Test output for //examples/js_library/one:lint_as_test:

/shared/cache/bazel/user_base/581b2ac03dd093577e8a6ba6b6509be5/sandbox/linux-sandbox/21/execroot/aspect_rules_js/bazel-out/k8-fastbuild/bin/examples/js_library/one/lint_as_test.sh.runfiles/aspect_rules_js/examples/js_library/one/one.js
  5:7  error  'a' is assigned a value but never used  no-unused-vars

✖ 1 problem (1 error, 0 warnings)

================================================================================
Target //examples/js_library/one:lint_as_test up-to-date:
  bazel-bin/examples/js_library/one/lint_as_test.sh
INFO: Elapsed time: 1.017s, Critical Path: 0.32s
INFO: 4 processes: 2 linux-sandbox, 2 local.
//examples/js_library/one:lint_as_test                                   FAILED in 0.2s
  /shared/cache/bazel/user_base/581b2ac03dd093577e8a6ba6b6509be5/execroot/aspect_rules_js/bazel-out/k8-fastbuild/testlogs/examples/js_library/one/lint_as_test/test.log
```

## As a report-generator target

As above, you'd have a macro stamp out these extra targets next to each js_library/ts_project, but this time they just produce an output.
You'd take that output and run it through some tool like reviewdog to present it to developers.
There's no requirement that the codebase be lint-warning-free.

For example, writing this

```
bin.eslint(
    name = "lint",
    srcs = [
        "one.js",
        "//:.eslintrc",
    ],
    args = [
        "--config",
        ".eslintrc.yml",
        "$(execpath one.js)",
    ],
    exit_code_out = "exit_code",
    stdout = "report",
)
```

And the result looks like

```
$ bazel build //examples/js_library/one:lint
Target //examples/js_library/one:lint up-to-date:
  bazel-bin/examples/js_library/one/report
  bazel-bin/examples/js_library/one/exit_code
INFO: Build completed successfully, 2 total actions

$ cat bazel-bin/examples/js_library/one/report

/shared/cache/bazel/user_base/581b2ac03dd093577e8a6ba6b6509be5/sandbox/linux-sandbox/23/execroot/aspect_rules_js/bazel-out/k8-fastbuild/bin/examples/js_library/one/one.js
  5:7  error  'a' is assigned a value but never used  no-unused-vars

✖ 1 problem (1 error, 0 warnings)
```

## As a report-generator aspect

This one is modeled on https://github.com/thundergolfer/bazel-linting-system/.
The advantage is that no BUILD file changes are needed, you don't even need to write a wrapper macro.

Usage looks like this:

```
$ bazel build //examples/js_library/one --aspects //js/private/eslint:eslint.bzl%eslint --output_groups=report
INFO: Analyzed target //examples/js_library/one:one (0 packages loaded, 0 targets configured).
INFO: Found 1 target...
INFO: From Action examples/js_library/one/report:

/shared/cache/bazel/user_base/581b2ac03dd093577e8a6ba6b6509be5/sandbox/linux-sandbox/25/execroot/aspect_rules_js/bazel-out/k8-fastbuild/bin/examples/js_library/one/one.js
  5:7  error  'a' is assigned a value but never used  no-unused-vars

✖ 1 problem (1 error, 0 warnings)

Aspect //js/private/eslint:eslint.bzl%eslint of //examples/js_library/one:one up-to-date:
  bazel-bin/examples/js_library/one/report
INFO: Build completed successfully, 2 total actions

$ cat bazel-bin/examples/js_library/one/report

/shared/cache/bazel/user_base/581b2ac03dd093577e8a6ba6b6509be5/sandbox/linux-sandbox/25/execroot/aspect_rules_js/bazel-out/k8-fastbuild/bin/examples/js_library/one/one.js
  5:7  error  'a' is assigned a value but never used  no-unused-vars

✖ 1 problem (1 error, 0 warnings)
```
