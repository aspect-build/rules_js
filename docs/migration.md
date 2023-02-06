# Migration

If you are coming from `rules_nodejs`, this page outlines some of the bumps you will need to be aware of when translating rulesets

## js_library

js_library no longer supports attributes `package_name` and `strip_prefix`. However, the rule invocation is the same.

```diff
js_library(
  name = "target",
-  package_name = "@scope/package_name",
-  strip_prefix = "."
  # ...
)
```

If you need to keep the above invocations for backwards compatability you can follow [this example](https://github.com/aspect-build/bazel-examples/blob/5c785b85cbe6efaeb0014023c75ccd625340e351/rules_nodejs_to_rules_js_migration/libs/a/BUILD.bazel#L21)

## pkg_npm

`pkg_npm` has been renamed to `npm_package`. The attribute `data` has been swapped for `srcs.

```diff
-  pkg_npm(
+  npm_package(
  name = "target",
-  data = [],
+  srcs = [],
  # ...
)
```

## nodejs_binary

`nodejs_binary` has been renamed `js_binary`. No other changes needed.

```diff
-  nodejs_binary(
+  js_binary(
  name = "target",
  # ...
)
```
