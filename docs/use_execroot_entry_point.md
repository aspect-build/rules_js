# use_execroot_entry_point

This page describes the `use_execroot_entry_point` option on `js_run_binary`
and provides guidance on when to use each value. The short version is that
`use_execroot_entry_point=True` sets up a directory layout that is more
friendly to some JavaScript tools, but at the expense of causing problems for
cross-platform builds.

## Background

When a `js_binary` is used as a tool in `js_run_binary`, Bazel runs it as a
build action on the exec platform. The execroot is the root of the build
sandbox; beneath it sits `bazel-out/`, which contains output directories for
both the exec and target configurations. The tool's sources can therefore
potentially appear in up to three places:

- **Exec-platform bin** (`bazel-out/<exec-cfg>/bin/`): where build artifacts for
  the exec platform land.
- **Runfiles tree** (`bazel-out/<exec-cfg>/bin/path/to/my_binary.runfiles/`):
  where the tool's runtime dependencies (including `node_modules`) are
  symlinked and made available to the build action.
- **Target-platform bin** (`bazel-out/<target-cfg>/bin/`): where the `srcs` of
  the `js_run_binary` action land. This is also the default working directory
  for the build action, though it can be adjusted via the `chdir` attribute.

Resolving the same package in more than one location can result in subtle bugs,
so this is a potential danger here given that the same sources can appear in up
to three places. As described below, `use_execroot_entry_point = True`
addresses the problem by keeping all sources in the target-platform bin
directory, but this has downsides.

## What `use_execroot_entry_point` does

**`use_execroot_entry_point = True` (the current default):**
The entry point used is the one in the target-platform bin
directory--confusingly called the "execroot entry point" even though the
execroot encompasses the whole sandbox. In order for the tool's sources to land
in that directory, they end up being rebuilt for the target platform. With
everything consolidated in `bazel-out/<target-cfg>/bin/`, Node.js sees a single
`node_modules` tree. This can be the right choice for some frameworks such as
Next.js, which expects inputs and outputs to be in the same directory tree.

The tradeoff is that if the exec platform differs from the target platform (for
example, cross-compiling from macOS to Linux), target-platform artifacts such as
native Node.js addons are rebuilt for the target and may fail to run on the exec
platform.

**`use_execroot_entry_point = False`:**
The entry point used is the one from the runfiles tree. All code executed during
the build action runs from the runfiles tree, which avoids cross-platform
issues. However, you must ensure that any code executed during the build (for
example, JavaScript config files for tools like Webpack or Rspack) is a declared
dependency of the `js_binary` tool, not merely a source file passed to
`js_run_binary`. Source files in the `js_run_binary`'s `srcs` will land in the
target-platform bin directory and will therefore not be visible to the tool's
runfiles resolution.

## Recommendation

We recommend setting `use_execroot_entry_point = False`, unless your tool
requires its config and outputs to be adjacent to each other in the same
directory (such as Next.js for example). If you do this and ensure that all
code executed during the build is declared as a dependency of the `js_binary`,
then your build will work reliably even in cross-platform situations.

To disable `use_execroot_entry_point` by default, pass the build flag:

```
--@aspect_rules_js//js:use_execroot_entry_point=False
```

You may want to set it in your `.bazelrc` as follows:
```
common --@aspect_rules_js//js:use_execroot_entry_point=False
```

Individual targets can still override the flag by explicitly setting
`use_execroot_entry_point = True` or `use_execroot_entry_point = False`.

In a future major version, we will likely disable the `use_execroot_entry_point`
behavior by default.

### Example

A simple example of the recommended way to set up a `js_run_binary` target is
[here](../examples/rspack/BUILD.bazel). This particular case *requires*
`use_execroot_entry_point = False`, because otherwise the cross-platform build
in that file would fail as a result of Bazel trying to use the wrong Rspack
binary. Below is the key part, edited slightly for brevity:

```
js_library(
    name = "rspack_config",
    srcs = ["rspack.config.cjs"],
    deps = [":node_modules/@rspack/cli"],
)

bin.rspack(
    name = "rspack_build",
    srcs = ["rspack_entry.js"],
    outs = ["rspack/main.bundle.js"],
    chdir = package_name(),
    data = [":rspack_config"],
    fixed_args = [
        "build",
        "--config",
        "$$RUNFILES_DIR/$(rlocationpath :rspack_config)",
    ],
    use_execroot_entry_point = False,
)
```

Note that in this case `bin.rspack()` is a generated macro that creates both
the `js_binary` for Rspack *and* the `js_run_binary` target that runs it.

Key points:
- The `rspack.config.cjs` file is wrapped in a `js_library` and taken as a
  `data` dependency of the `js_binary`. This ensures that the config file and
   its dependencies are built for the exec platform, which is appropriate
   since they will run during the build action. They will land in the runfiles
   directory adjacent to the other exec-platform sources, which will allow
   module resolution to proceed correctly.
- `chdir = package_name()` causes the working directory to be
  `bazel-out/<target-cfg>/bin/examples/rspack`. This is not strictly
   necessary, but it is convenient to have the outputs go directly in the
   build action's current directory.
- The config file (`rspack.config.cjs`) refers to `process.cwd()`, not
  `__dirname`, for specifying the output path. This is key, because the config
  file will be in the runfiles directory and thus `__dirname` will not be
  anywhere near the output tree.
- We refer to `"$$RUNFILES_DIR/$(rlocationpath :rspack_config)"` in
  `fixed_args`. This slightly convoluted syntax is necessary to determine an
  absolute path to the config file in the runfiles directory. This must go in
  `fixed_args` rather than `args`, to allow `$RUNFILES_DIR` to be evaluated at
  run time.
