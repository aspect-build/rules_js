# Migrating to rules_js

1. [Upgrade Bazel to >=5.0](#upgrade-to-bazel-50-or-greater)
2. [Translate lockfile to pnpm format](#translate-your-lockfile-to-pnpm-format)
3. [Update usage of npm package generated rules](#update-usage-of-npm package-generated-rules)

> There are more migration steps needed, this guide is still a work-in-progress

## Upgrade to Bazel 5.0 or greater

We follow [Bazel's LTS policy](https://bazel.build/release/versioning).

`rules_js` and the related rules depend on APIs that were introduced in Bazel 5.0.

## Translate your lockfile to pnpm format

`rules_js` uses the `pnpm` lockfile to declare dependency versions as well as a deterministic layout for the `node_modules` tree.

1. Most migrations should avoid changing two things at the same time,
   so we recommend taking care to keep all dependencies the same (including transitive).
   Run `npx pnpm import` to translate the existing file. See the [pnpm import docs](https://pnpm.io/cli/import)  
2. If you don't care about keeping identical versions, or don't have a lockfile,
   you could just run `pnpm install` which generates a new lockfile.

## Update usage of npm package generated rules

- the load point is now a `bin` symbol from `package_json.bzl`
- this now produces different rules, which are explicitly referenced from `bin`
- to run as a tool under `bazel build` you use [package] which is a `run_js_binary`
  - rename `data` to `srcs`
  - rename `templated_args` to `args`
- as a program under `bazel run` you need to add a `_binary` suffix, you get a `js_binary`
- as a test under `bazel test` you get a `js_test`

Example, before:

```starlark
load("@npm//npm-check:index.bzl", "npm_check")

npm_check(
    name = "check",
    data = [
        "//third_party/npm:package.json",
    ],
    templated_args = [
        "--no-color",
        "--no-emoji",
        "--save-exact",
        "--skip-unused",
        "third_party/npm",
    ],
)
```

Example, after:

```starlark
load("@npm//npm-check:package_json.bzl", "bin")

exports_files(["package.json"])

bin.npm_check(
    name = "check",
    srcs = [
        "//third_party/npm:package.json",
    ],
    args = [
        "--no-color",
        "--no-emoji",
        "--save-exact",
        "--skip-unused",
        "third_party/npm",
    ],
)

```
