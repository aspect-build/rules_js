# The hermetic launcher

A `js_binary` is normally invoked through a generated bash script
(`js/private/js_binary.sh.tpl`), which works out where node, the fs patches and
the entry point are, exports a set of `JS_BINARY__*` variables, changes into the
root of the output tree, and finally execs node. That is a shell process and a
few hundred lines of path resolution on every invocation, and it cannot run at
all where there is no bash.

The hermetic launcher is an experimental alternative, off by default:

```sh
bazel build //... --@aspect_rules_js//js:use_hermetic_launcher
```

With the flag on, a `js_binary`'s executable is a small native binary stamped by
[hermetic_launcher](https://github.com/hermeticbuild/hermetic-launcher) which
does nothing but resolve its runfiles and `execve` node on a generated
JavaScript file, `<name>_/<name>.cjs`.

## One node process

The stub starts node with the options that have to be in place before it boots --
`--preserve-symlinks-main`, when `preserve_symlinks_main` is set. node is then
already configured the way the program needs it, so the launcher requires the
node patches and runs the entry point as the main module in that same process,
rather than starting a second node. That saves a whole node runtime bootstrap,
which is most of what a short `js_binary` invocation costs.

The program cannot tell the difference: it is the main module, so
`require.main === module` holds; `process.argv` and `process.execArgv` read as
they do under the bash launcher; and node reports an uncaught exception itself,
with the program's own stack.

The launcher falls back to starting node a second time when it has to, which is
when either:

-   the target sets `node_options`, or a `--node_options=` is passed at run time.
    Those cannot be applied to a node that is already running, and they are not
    baked into the stub: an entry may name a `--require` that has to run after
    the launcher has set up the environment, or reference a variable only known
    at run time.
-   `expected_exit_code` is set, so the launcher has to outlive the program to
    compare against its status.

## Unsupported deprecated features

The hermetic launcher does not implement stdout capture, stderr capture, exit
code capture, or `silent_on_success`. It ignores `JS_BINARY__STDOUT_OUTPUT_FILE`,
`JS_BINARY__STDERR_OUTPUT_FILE`, `JS_BINARY__EXIT_CODE_OUTPUT_FILE` and
`JS_BINARY__SILENT_ON_SUCCESS`.

These features are also deprecated on the bash launcher. They were originally
necessary for implementing the corresponding functionality on `js_run_binary`,
but that functionality has now moved into the underlying `run_binary` macro.
