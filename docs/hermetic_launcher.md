# The hermetic launcher

A `js_binary` is normally invoked through a generated bash script
(`js/private/js_binary.sh.tpl`), which works out where node, the fs patches and
the entry point are, exports a set of `JS_BINARY__*` variables, changes into the
root of the output tree, and finally execs node. That is a shell process and a
few hundred lines of path resolution on every invocation, and it cannot run at
all where there is no bash.

The hermetic launcher is an experimental alternative, off by default:

```sh
bazel build //... --@aspect_rules_js//js:hermetic_launcher
```

With the flag on, a `js_binary`'s executable is a small native binary stamped by
[hermetic_launcher](https://github.com/hermeticbuild/hermetic-launcher) which
does nothing but resolve its runfiles and `execve` node on a generated
JavaScript launcher, `<name>_/<name>.cjs`. No shell is involved. The flag
applies everywhere: `bazel run`, `bazel test` and `js_run_binary` all go through
it, and a target gets one launcher or the other, never both.

This is the first step towards replacing the bash launcher outright. The
JavaScript launcher is deliberately an almost literal translation of the bash
one -- same order, same messages, same decisions -- so that the two can be read
side by side. `js/private/test/snapshots/launcher.sh` and
`js/private/test/snapshots/launcher.cjs` are checked-in expansions of both, kept
up to date by `//js/private/test:write_launcher` and
`//js/private/test:write_launcher_js`, and diffing them is how a change to
either is reviewed.

## What is not implemented

The JavaScript launcher does not implement stdout capture, stderr capture, exit
code capture or `silent_on_success`. It ignores `JS_BINARY__STDOUT_OUTPUT_FILE`,
`JS_BINARY__STDERR_OUTPUT_FILE`, `JS_BINARY__EXIT_CODE_OUTPUT_FILE` and
`JS_BINARY__SILENT_ON_SUCCESS` rather than honouring them.

Nothing in rules_js asks the launcher for those any more: `js_run_binary`
forwards `stdout`, `stderr`, `exit_code_out` and `silent_on_success` to
bazel-lib's `run_binary`, which captures through its own spawn wrapper -- a
process that outlives the program and can do the work they need once it has
exited. The launcher's implementation of them is legacy compatibility for code
outside rules_js that sets the variables by hand (#2955), and it stays in the
bash launcher.

`expected_exit_code` _is_ implemented, since it is a `js_binary` attribute with
no other home.

Everything else the bash launcher does is reproduced: the `--bazel-bindir` flag,
the execroot derivation, the `cd` into `BAZEL_BINDIR`, entry point / node / npm /
wrapper resolution, `node_options`, `fixed_args`, `JS_BINARY__FS_PATCH_ROOTS`,
coverage, the node wrapper on the `PATH`, the `JS_BINARY__*` per-target
constants, signal forwarding, and the debug and info logging.

## How many processes it costs

When there is no `expected_exit_code` -- almost always -- the launcher replaces
itself with node through `process.execve`, exactly as the bash launcher's `exec`
did, so no launcher process survives. It is still one more node startup than the
bash launcher paid, which is the price of this step; collapsing it is the point
of the next one.

`process.execve` is POSIX-only and was added in node 22.15. On an older node, on
Windows, and whenever `expected_exit_code` is set, the launcher spawns node and
waits for it, forwarding `SIGTERM` and `SIGINT` -- the bash launcher's
fork-and-wait path.

## Differences you may notice

-   **`fixed_args` are tokenized at analysis time.** The bash launcher spliced
    them into `ALL_ARGS=(... "$@")`, so the shell word-split them and removed
    quotes. `_shell_tokenize` in `js/private/js_binary.bzl` reproduces that
    splitting; backslash escapes are deliberately not interpreted, so a
    Windows-style path survives intact. That last point shows in one place: bash
    passes `\$VAR` through literally where this launcher expands it. Use
    `'$VAR'` for a literal `$`.
-   **`$VAR` expansion in `env`, `node_options` and `fixed_args` is done by the
    launcher, not a shell.** `$VAR` and `${VAR}` are expanded against the
    environment as it is built up; command substitution is not reproduced, and the
    result is not re-split on whitespace. A single-quoted segment of a `fixed_arg`
    is left alone, as bash would have left it.
-   **No stub, no launcher.** hermetic_launcher publishes prebuilt stubs for
    linux, macOS and Windows on x86_64 and arm64, plus linux s390x. For a target
    platform it has no stub for, `js_binary` writes a placeholder that fails with
    an explanatory message when run, so that `bazel build //...` still succeeds
    (#2347).

## Keeping the two launchers in sync

The JavaScript launcher is a transliteration of the bash one and has to stay that
way until it replaces it. The rest of the suite cannot check that: a target gets
one launcher per configuration, so every other both-launcher test skips one side
and CI covers the other by running the whole suite again with the flag on. That
catches breakage but not drift -- a bash-launcher change that was never ported
leaves both launchers passing every test.

`//js/private/test/launcher_sync` closes that gap. A configuration transition
builds one `js_binary` twice, once with the flag off and once with it on, runs
both, and diffs the state node ends up in: `process.env`, the cwd, `argv` and
`execArgv`. Because it compares the two launchers against each other rather than
against a recorded golden, it needs no snapshot to regenerate and it fails on
every CI leg rather than just the one with the flag on.

`dump_state.mjs` holds the short list of things it deliberately does not compare
-- bash's own `_`, `SHLVL` and `OLDPWD`, the `JAVA_RUNFILES` the stub exports,
and the per-action `TMPDIR` -- each with the reason. Sandbox paths and the
output-tree configuration segment are normalized away; everything else has to
match.

The four capture variables need no entry there: the bash launcher `export -n`s
them and this launcher never sets them, so neither reaches the program.

## Status

Windows is wired up -- the stub gets its `.exe` suffix and the `.bat` node
wrapper is used -- but is untested: the repo's Windows smoke job only runs on
`main`.

CI runs the whole test suite against the flag on the `bazel-9-hermetic-launcher`
matrix leg.
