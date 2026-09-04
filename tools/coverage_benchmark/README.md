# Coverage benchmark

Measures how much slower `bazel coverage` is than `bazel build` / `bazel test` for a
rules_js workspace, and where the difference goes. It exists because the cost is mostly
*per test* and mostly invisible in `aquery`: the action graph barely changes, but the test
actions do much more work.

```sh
tools/coverage_benchmark/bench.sh --scale medium --runs 3
```

Writes `results.tsv` under `$TMPDIR/rules_js_coverage_bench/results-<scale>/`, plus the
raw BEP, profile and execution log for every run.

## Why it generates a workspace

`generate.sh` materializes a synthetic workspace at one of three scales
(`small` 10x10/5, `medium` 100x20/50, `large` 500x20/200 — libraries x sources / tests)
consuming this repo through `local_path_override`. Scaling is the point: a constant
overhead, a cost that grows with the number of instrumented files, and one that grows with
their product look identical at a single size. Pass `--npm` to link a real node_modules
tree; only the runfiles-materialization question needs it, and it costs a pnpm resolve.

The workspace imports `tools/preset.bazelrc`, so the arms inherit the flags a rules_js user
actually gets — including `common --nobuild_runfile_links` paired with
`coverage --build_runfile_links`, which is one of the things being measured.

## Two ways the measurement can silently lie

**A warm output base.** A machine that has built this repo before carries warm bases, and
an invocation that lets bazel choose one reports a warm number as a cold one. Every arm
therefore pins `--output_base`, and a cold arm refuses to start if its base already
exists. The `output_base` is not in the TSV by accident — it is there so a contaminated row
can be spotted afterwards.

**A cached test result.** `bazel coverage` will happily republish a cached `coverage.dat`
without running the test at all, which makes any change to the coverage reporter measure
as exactly zero. Every test and coverage arm passes `--nocache_test_results`.

The `toggle.*` arms deliberately share one output base across two commands, to capture the
analysis-cache discard that flipping `--collect_code_coverage` causes. The
`cache_discarded` column says whether that actually happened; `no` means the arm
degenerated into a warm run and the row is meaningless.

## Reading `results.tsv`

| column | meaning |
| --- | --- |
| `wall_s` | wall time of the whole invocation, measured outside bazel |
| `pre_exec_ms` | time before the first action ran: repository fetching plus analysis |
| `bazel_ms` | bazel's own wall time. Bazel 7 interleaves analysis and execution, so this and `pre_exec_ms` overlap and must not be summed |
| `actions` | actions that *executed*, from BEP. Not the graph size — `aquery` answers that, and the two differ a lot under coverage |
| `baseline_cov` | executed `BaselineCoverage` actions. `--instrumentation_filter` drives this to zero |
| `tests` / `test_s` | number of test spawns and their summed wall time. **The headline number**: the coverage reporter's cost lands here |
| `symlink_s` | summed `SymlinkTree` spawn time — runfiles materialization, which `bazel test` skips and `bazel coverage` does not |
| `javac_cpp` | `Javac` + `CppCompile` actions, i.e. the Java/C++ coverage tooling a JS-only repo otherwise never builds |
| `manifest` | largest `COVERAGE_MANIFEST` produced. The reporter's input size |
| `report_ms` | reporter time summed over the tests, from the `JS_BINARY__LOG_DEBUG` timings. Requires `--test_env=JS_BINARY__LOG_DEBUG=1` |
| `cache_discarded` | whether bazel logged `discarding analysis cache` |

`BaselineCoverage` is a `FileWriteAction`, not a spawn, so it never appears in the
execution log — only BEP with `--build_event_publish_all_actions` sees it. That is why the
executed-action columns come from BEP and the timing columns from the execution log.

## Housekeeping

Each arm's output base is shut down and deleted once its numbers are extracted, keeping
only the small BEP/profile/execlog artifacts; a full sweep would otherwise leave tens of
gigabytes behind. All arms share one `--repository_cache` so npm and toolchain fetching
happens once instead of once per arm.
