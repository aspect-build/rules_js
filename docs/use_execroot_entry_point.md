# use_execroot_entry_point

This page describes the `use_execroot_entry_point` option on `js_run_binary`
and provides guidance on when to use each value.

## Background

When a `js_binary` is used as a tool in `js_run_binary`, Bazel runs it as a
build action on the exec platform. The execroot is the root of the build
sandbox; beneath it sits `bazel-out/`, which contains output directories for
both the exec and target configurations. The tool's sources can therefore appear
in up to three places:

- **Exec-platform bin** (`bazel-out/<exec-cfg>/bin/`): where build artifacts for
  the exec platform land.
- **Runfiles tree** (`bazel-out/<exec-cfg>/bin/path/to/my_binary.runfiles/`):
  where the tool's runtime dependencies (including `node_modules`) are
  symlinked and made available to the build action.
- **Target-platform bin** (`bazel-out/<target-cfg>/bin/`): where the `srcs` of
  the `js_run_binary` action land.

When Node.js resolves `require()`, it walks up the directory tree looking for
`node_modules`. If the working directory is somewhere that can see
`node_modules` from both the exec output tree and the runfiles tree, the same
package can resolve from two different paths, which can cause subtle bugs.

## What `use_execroot_entry_point` does

**`use_execroot_entry_point = True` (the current default):**
The tool's runfiles are hoisted into `srcs`, which causes them to be rebuilt in
the target configuration and land in the target-platform bin directory. The
entry point used is the one in that output tree (the "execroot entry point"),
rather than the copy inside the runfiles symlink tree. With everything
consolidated in `bazel-out/<target-cfg>/bin/`, Node.js sees a single
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
`js_run_binary`. Config files in the `js_run_binary`'s `srcs` will land in the
target-platform bin directory and will therefore not be visible to the tool's
runfiles resolution.

## Recommendation

We recommend setting `use_execroot_entry_point = False` wherever possible and
ensuring that all code executed during the build is declared as a dependency of
the `js_binary`. The main exception is Next.js and similar frameworks that
expect inputs and outputs in the same directory tree or that execute
target-platform code during the build, in which case `True` is required.

To disable `use_execroot_entry_point` globally, pass the build flag:

```
--@aspect_rules_js//js:use_execroot_entry_point=False
```

Individual targets can still override the flag by explicitly setting
`use_execroot_entry_point = True` or `use_execroot_entry_point = False`.

In a future major version, we will likely disable the `use_execroot_entry_point`
behavior by default.
