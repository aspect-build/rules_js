# The hermetic launcher

A `js_binary` is normally invoked through a generated bash script, which works
out where node, the fs patches and the entry point are, exports a set of
`JS_BINARY__*` variables, changes into the root of the output tree, and finally
execs node. That is a shell process and a few hundred lines of path resolution
on every invocation, which is noticeable when the `js_binary` is the tool of a
build action that runs thousands of times.

The hermetic launcher is an alternative: a small native binary, stamped per
target by [hermetic_launcher](https://github.com/hermeticbuild/hermetic-launcher),
which does nothing but `execve` node with a fixed set of arguments baked into it.
No shell is involved.

`js_run_binary` uses it automatically for a target when it can determine that
doing so behaves identically. Nothing else does yet; `bazel run` and `bazel test`
still go through the bash launcher.

## What replaces the launcher script

The launcher binary can only `execve`. Everything the script did before reaching
node is instead done by `js/private/node-bootstrap/launcher.cjs`, which node
loads with `--require` before the entry point. Running inside node, before any
user code, it can do almost everything the shell did:

- consume the `--bazel-bindir` flag that `js_run_binary` passes, so that it does
  not reach the program as a positional argument
- change into the bin directory, preserving the "everything runs from the root
  of the output tree" contract
- derive the execroot and the runfiles root, and set `JS_BINARY__FS_PATCH_ROOTS`
  so that the fs patches apply
- put the node wrapper on the `PATH` and set `JS_BINARY__NODE_BINARY`,
  `JS_BINARY__NODE_WRAPPER` and `JS_BINARY__NODE_PATCHES`, so that a child
  process which shells out to `node` still gets the patched runtime
- honour `JS_BINARY__CHDIR`

Two kinds of thing are out of reach. Node CLI flags have to be baked into the
launcher, because node has already parsed its options by the time a preload
runs; only `--preserve-symlinks-main` is. And the per-target constants the
script bakes in -- `JS_BINARY__WORKSPACE`, `JS_BINARY__TARGET`,
`JS_BINARY__PACKAGE`, `JS_BINARY__BUILD_FILE_PATH`,
`JS_BINARY__COMPILATION_MODE`, `JS_BINARY__TARGET_CPU` and `JS_BINARY__BINDIR`
-- are not set at all, since there is no channel to carry them. A program that
reads one of those will see `undefined`.

## When it is used

Both the `js_binary` and the `js_run_binary` have to qualify.

A `js_binary` is disqualified by `chdir`, `env`, `node_options`,
`expected_exit_code` or `include_npm`, by targeting Windows, or by setting
`copy_data_to_bin = False` -- without that the entry point is never copied to the
bindir, and the execroot mode below has nothing to run.
`patch_node_fs` is not a disqualifier: `js_run_binary` always passes it through the
action environment.

`fixed_args` are disqualifying only when they need a shell. The launcher can carry
an argument verbatim, and it can resolve one through its runfiles, so the documented
`fixed_args = ["--config", "$$RUNFILES_DIR/$(rlocationpath :config)"]` idiom is
supported: `$(rlocationpath ...)` is expanded at analysis time, and the launcher
resolves what remains to the same absolute path the shell would have produced from
`$RUNFILES_DIR`. A `fixed_arg` containing any other `$`, or spelled
`--bazel-bindir`, is a disqualifier. Since `fixed_args` become embedded arguments
they also consume the launcher's ten argument slots, five of which are already
taken; a target with too many falls back to the bash launcher.

A `js_run_binary` is disqualified by a `--node_options=` entry in `args`. Its `env` is not
consulted at all.

`stdout`, `stderr`, `exit_code_out` and `silent_on_success` are not disqualifiers, even
though all four need work after the program exits and the launcher only `execve`s.
`js_run_binary` forwards them to `run_binary`, which captures through its `spawn_binary`
wrapper -- a process that outlives the program and can do that work. This costs nothing:
the launcher script only forks rather than `exec`s because of these same features, so the
wrapper's fork replaces the script's.

Setting the matching `JS_BINARY__*` variable through `env` by hand is the one way to ask
for something the launcher genuinely cannot do, since only the script implements those.
It is not treated as a disqualifier: it means going out of the way to reach for a private
variable in place of the attribute that exists for it, and `launcher.cjs` refuses to run
at all when it sees one, naming the variable. The variables that do have an
implementation here -- `JS_BINARY__CHDIR`, `JS_BINARY__NO_CD_BINDIR`,
`JS_BINARY__LOG_*`, `JS_BINARY__USE_EXECROOT_ENTRY_POINT` -- are honoured either way.

`log_level` is not a disqualifier on either side, because it only selects how much
diagnostic output is printed. `js_run_binary` passes `JS_BINARY__LOG_*` through the
action environment, so a level set there reaches `launcher.cjs` and `bootstrap.cjs`
unchanged. What differs is the detail: the launcher script's info and debug output
dumps the `PATH`, the `BAZEL_*` and `JS_BINARY__*` values it computed and the node
command line, and none of that is printed when the script does not run. A `log_level`
set on the `js_binary` itself has no channel to the stub and is not applied at all.

A coverage-enabled test is not a disqualifier either. The lcov report is generated from a
node exit hook rather than by the launcher script after node is gone, so nothing is left
that needs a process outliving the program. What remains is `NODE_V8_COVERAGE`, which node
reads once as it opens its V8 coverage connection during startup -- before any `--require`
preload runs, so `launcher.cjs` cannot turn coverage on for the process it is in. It
starts node again with the variable set instead, in place through `process.execve` where
node has it. Only the first node in the tree does that; every child inherits the variable
and opens its own connection. The path of the report generator has no channel from the
rule either, so `launcher.cjs` derives it from its own path in the runfiles, the same way
it finds the node wrapper.

`use_execroot_entry_point` is not a disqualifier either, though it is the one place where
the launcher has to do real work the stub cannot express. The two modes differ in which
copy of the entry point node runs, and therefore in the directory node walks up from to
resolve the program's own `require`s:

| mode | main module | resolution root |
| --- | --- | --- |
| `False` | `$RUNFILES/<repo>/<short_path>` | the tool's runfiles tree |
| `True` | `$EXECROOT/$BAZEL_BINDIR/<short_path>` | the target-configuration bin tree, where the action's `srcs` and outputs also live |

Only the runfiles form can be baked into the launcher binary: its single argument
transformation resolves against the runfiles root, and the bindir is the *target*
configuration's, which a `js_binary` analyzed for the exec platform does not know. So
`launcher.cjs` composes the execroot form at startup instead, exactly as the launcher
script does, and then redirects node's main module to it. It needs no extra embedded
argument to do so: an rlocation path and a short path differ only in their first segment,
so the short path is recovered from the runfiles path already in `argv[1]`. That inversion
needs the name of the main repository, which under bzlmod -- the only mode rules_js
supports -- is always `_main`.

Redirecting the main is what moves the resolution root, so it has to happen before node
loads it. For a CommonJS main that is a `Module._resolveFilename` hook; for an ES module it
is a `module.registerHooks` resolve hook, and on a node too old to have that
(before 22.15) the launcher re-executes node on the right file rather than run the wrong
copy. Both hooks are installed, so nothing has to predict which loader node will choose.
Only the process the build action launched does any of this -- a child that re-enters node
was handed its own script, and the launcher script would not have touched that either.

See [use_execroot_entry_point.md](use_execroot_entry_point.md) for what the two modes are
for.

Anything that does not qualify keeps using the bash launcher, with no error.

## Finding out what a target got

The action's executable path differs, so `aquery` answers the question directly
and cannot be out of date:

```sh
bazel aquery --output=textproto //your:target | grep -A2 'JsRunBinary'
```

For the `js_binary` side, every target publishes its verdict in an output group,
which is written only when asked for:

```sh
bazel build //... --output_groups=hermetic_launcher_report
find -L bazel-out -name hermetic_launcher_report.txt | xargs cat
```

Each line is the target label followed by `eligible`, `unavailable` (no prebuilt
stub for this platform, or an embedded argument over the launcher's 256-byte
limit), or `blocked:` and a comma-separated list of reason codes. Summing the
last column over a whole repository shows what is holding adoption back:

```sh
find -L bazel-out -name hermetic_launcher_report.txt | xargs cat |
    sed 's/^[^ ]* //' | sort | uniq -c | sort -rn
```
