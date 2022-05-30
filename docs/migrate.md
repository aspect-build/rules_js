# Migrating to rules_js

There are more migration steps needed, this guide is still a work-in-progress.

## Upgrade to Bazel 5.0 or greater

We follow [Bazel's LTS policy](https://bazel.build/release/versioning).

`rules_js` and the related rules depend on APIs that were introduced in Bazel 5.0.

## Install pnpm (optional)

`rules_js` is based on the pnpm package manager.
Our implementation is self-contained, so it doesn't matter if users install pnpm,
however it's typically useful to manipulate the lockfile or to install packages for use outside of Bazel.

You can follow the [pnpm install docs](https://pnpm.io/installation).

Alternatively, you can skip the install. All commands in this guide will use `npx` to run the pnpm tool without any installation.

## Translate your lockfile to pnpm format

`rules_js` uses the `pnpm` lockfile to declare dependency versions as well as a deterministic layout for the `node_modules` tree.

1. Most migrations should avoid changing two things at the same time,
   so we recommend taking care to keep all dependencies the same (including transitive).
   Run `npx pnpm import` to translate the existing file. See the [pnpm import docs](https://pnpm.io/cli/import)  
2. If you don't care about keeping identical versions, or don't have a lockfile,
   you could just run `npx pnpm install` which generates a new lockfile.

The new `pnpm-lock.yaml` file needs to be updated by engineers on the team as well,
so when you're ready to switch over to rules_js, you'll have to train them to run `pnpm` rather than `npm` or `yarn`
when changing dependency versions.

If needed, you might have both the pnpm lockfile and your legacy one checked into the repo during a migration window.
You'll have to avoid version skew between the two files during that time.

## Test whether pnpm is working

A few packages have bugs which rely on "hoisting" behavior in yarn or npm, where undeclared dependencies can be loaded because they happen to be installed in an ancestor folder under `node_modules`.

In many cases, updating your dependencies will fix issues since maintainers are constantly addressing pnpm bugs.

See <https://pnpm.io/faq#pnpm-does-not-work-with-your-project-here> for other mitigations.

As long as you're able to run your build and test under pnpm, we expect the behavior of `rules_js` should match.

## Link the node modules

Typically you just add a `link_js_packages` call to the BUILD file next to each `package.json` file:

```starlark
load("@npm//:defs.bzl", "link_js_packages")

link_js_packages()
```

This macro will expand to a rule for each npm package, which creates part of the `bazel-bin/[path/to/package]/node_modules` tree.

## Update WORKSPACE

The `WORKSPACE` file contains Bazel module dependency fetching and installation.

Add install steps from a release of rules_js, along with related rulesets you plan to use.

When you're ready to complete the migration, remove usage of the following:

- `build_bazel_rules_nodejs`

You'll need to remove `build_bazel_rules_nodejs` load() statements from BUILD files as well.
We suggest using https://docs.aspect.build/ to locate replacements for the rules you use.

## Update package.json

When you're ready to complete the migration, remove usage of the following npm packages which contain Bazel rules, as they don't work with `rules_js`.
Instead, look under https://github.com/aspect-build/ for replacement rulesets.

- `@bazel/typescript`
- `@bazel/rollup`
- `@bazel/esbuild`
- `@bazel/create`
- `@bazel/cypress`
- `@bazel/concatjs`
- `@bazel/jasmine`
- `@bazel/karma`
- `@bazel/terser`

Some `@bazel`-scoped packages are still fine, as they're tools or JS libraries rather than Bazel rules:

- `@bazel/bazelisk`
- `@bazel/buildozer`
- `@bazel/buildifier`
- `@bazel/ibazel` (watch mode)
- `@bazel/runfiles`

In addition, rules_js and associated rulesets can manage dependencies for tools they run. For example, rules_esbuild downloads its own esbuild packages. So you can remove these tools from package.json if you intend to run them only under Bazel.

## Account for change to working directory

`rules_js` spawns all Bazel actions in the bazel-bin folder.

- If you use a `chdir.js` workaround for tools like react-scripts, you can just remove this.
- If you use `$(location)`, `$(execpath)`, or `$(rootpath)` make variable expansions in an argument to a program, you may need to prefix with `../../../` to avoid duplicated `bazel-out/[arch]/bin` path segments.
- If you spawn node programs, you'll need to pass the `BAZEL_BINDIR` environment variable.
    - In a `genrule` add `BAZEL_BINDIR=$(BINDIR)`
    - ctx.actions.run add `env = { "BAZEL_BINDIR": ctx.bin_dir.path}`

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
