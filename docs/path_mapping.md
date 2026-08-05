# Path mapping

It is not unusual for Bazel build actions for different compilation modes to be
substantively identical, and yet unable to share a cached result due to
superficial differences in output paths. For example, a `fastbuild` result
might land in `bazel-out/k8-fastbuild/bin` whereas an `opt` result lands in
`bazel-out/k8-opt/bin`. This can result in a lot of wasted work, with Bazel
needlessly repeating the same action for each compilation mode even when there
is no real difference in the work being done.

Fortunately, Bazel supports a feature called [path
mapping](https://github.com/bazelbuild/bazel/discussions/22658) that addresses
this issue. When path mapping is active, Bazel temporarily collapses all bin
directories into a single one called `bazel-out/cfg/bin` during the action.
This way, build actions for different compilation modes or even CPU platforms
can share a cached result, provided that the actions are otherwise identical.

## Enabling path mapping

Getting path mapping set up requires both enabling it via command-line flags at
the Bazel level and then ensuring that specific targets are compatible with it.

At the Bazel level:
 - Pass the `--experimental_output_paths=strip` flag to Bazel
 - Use either remote caching or `--disk_cache`. Counterintuitively, Bazel's
   default caching will otherwise not benefit from path mapping.

The `js_run_binary` macro will automatically enable path mapping if it
determines it is safe to do so, but you may need to explicitly opt in (see
below). To set up a `js_run_binary` target for path mapping:
 - Pass `set_legacy_environment_variables = False`. This will disable the
   setting of environment variables such as `BAZEL_COMPILATION_MODE` that would
   otherwise be problematic. Alternatively, you can turn off this behavior by
   default globally by passing
   `--@aspect_rules_js//js:set_legacy_environment_variables=False`.
 - Avoid using [Make
   variables](https://bazel.build/reference/be/make-variables) or expressions
   such as `$(execpath :target)`. Such variables and expressions are not
   path-mapping-aware and may be unsafe.
 - If you need to use a Make variable or an expression such as `$(rootpath
   :target)` but you know that it is safe with respect to path mapping, you can
   explicitly opt in with `execution_requirements = {"supports-path-mapping":
   "1"}`. This is fine as long as you know the expression will not include
   `bazel-out/<platform dir>`, which would be incorrect when path mapping is
   active.

For custom rules that invoke a `js_binary`:
 - Use the helper function `js_binary_lib.run_binary_action()` from
   `@aspect_rules_js//js:libs.bzl`. This is a thin wrapper around
   `ctx.actions.run()` that handles some internal implementation details in a
   path-mapping-friendly way.
 - Set `execution_requirements = {"supports-path-mapping": "1"}` to opt into
   path mapping.
 - Make sure that any paths involving `bazel-out/` are mapped correctly. The
   only way to do this is to call `args.add()` or `args.add_all()` on an
   [Args](https://bazel.build/rules/lib/builtins/Args) object from
   `ctx.actions.args()`. If you need to do any additional munging of the path,
   it must be done in a `map_each` callback passed to
   [args.add_all()](https://bazel.build/rules/lib/builtins/Args#add_all).
