# Migrating to rules_js

There are more migration steps needed, this guide is still a work-in-progress.

## Upgrade to Bazel 5.1 or greater

We follow [Bazel's LTS policy](https://bazel.build/release/versioning).

`rules_js` and the related rules depend on APIs that were introduced in Bazel 5.0.

However we recommend 5.1 because it includes a [cache for MerkleTree computations](https://github.com/bazelbuild/bazel/pull/13879), which makes our copy operations a lot faster.

## Upgrade to rules_nodejs 5.0 or greater

As explained in the [README](/README.md), rules_js depends on rules_nodejs.
We need at least version 5.0.

This also requires you upgrade `build_bazel_rules_nodejs` to 5.x,
along with `@bazel`-scoped npm packages like `@bazel/typescript`.

## Install pnpm (optional)

`rules_js` is based on the pnpm package manager.
Our implementation is self-contained, so it doesn't matter if Bazel users of your project install pnpm.
However it's typically useful to create or manipulate the lockfile, or to install packages for use outside of Bazel.

You can follow the [pnpm install docs](https://pnpm.io/installation).

Alternatively, you can skip the install. All commands in this guide will use `npx` to run the pnpm tool without any installation.

## Translate your lockfile to pnpm format

`rules_js` uses the `pnpm` lockfile to declare dependency versions as well as a deterministic layout for the `node_modules` tree.

1. Most migrations should avoid changing two things at the same time,
   so we recommend taking care to keep all dependencies the same (including transitive).
   Run `npx pnpm import` to translate the existing file. See the [pnpm import docs](https://pnpm.io/cli/import)  
2. If you don't care about keeping identical versions, or don't have a lockfile,
   you could just run `npx pnpm install --lockfile-only` which generates a new lockfile.

> To make those commands shorter, we rely on the `npx` binary already on your machine.
> However you could use the Bazel-managed one from rules_nodejs instead, like so:
> `bazel run -- @nodejs_host//:npx_bin pnpm@latest i --lockfile-only`

The new `pnpm-lock.yaml` file needs to be updated by engineers on the team as well,
so when you're ready to switch over to rules_js, you'll have to train them to run `pnpm`
rather than `npm` or `yarn` when changing dependency versions or adding new dependencies.

If needed, you might have both the pnpm lockfile and your legacy one checked into the repo during a migration window.
You'll have to avoid version skew between the two files during that time.

## Test whether pnpm is working

A few packages have bugs which rely on "hoisting" behavior in yarn or npm, where undeclared dependencies can be loaded because they happen to be installed in an ancestor folder under `node_modules`.

In many cases, updating your dependencies will fix issues since maintainers are constantly addressing pnpm bugs.

Another pattern which may break is when a configuration file references an npm package, then a library reads that configuration and tries to require that package. For example, this [mocha json config file](https://github.com/aspect-build/rules_js/blob/main/examples/macro/mocha_reporters.json) references the `mocha-junit-reporter` package, so mocha will try to load that package despite not having a declared dependency on it.

Useful pnpm resources for these patterns:

- <https://pnpm.io/package_json#pnpmpackageextensions>
- <https://pnpm.io/faq#pnpm-does-not-work-with-your-project-here>

In our mocha example, the solution is to declare the expected dependency in `package.json` using the `pnpm.packageExtensions` key: <https://github.com/aspect-build/rules_js/blob/main/package.json>.

Another approach is to just give up on pnpm's stricter visibility for npm modules, and hoist packages as needed.
pnpm has flags `public-hoist-pattern` and `shamefully-hoist` which can do this, however we don't support those flags in rules_js yet.
Instead we have the `public_hoist_packages` attribute of [npm_translate_lock](/docs/npm_import.md#npm_translate_lock).
In the future we plan to read these settings from `.npmrc` like pnpm does; follow https://github.com/aspect-build/rules_js/issues/239.

As long as you're able to run your build and test under pnpm, we expect the behavior of `rules_js` should match.

## Link the node modules

Typically you just add a `npm_link_all_packages(name = "node_modules")` call to the BUILD file next to each `package.json` file:

```starlark
load("@npm//:defs.bzl", "npm_link_all_packages")

npm_link_all_packages(name = "node_modules")
```

This macro will expand to a rule for each npm package, which creates part of the `bazel-bin/[path/to/package]/node_modules` tree.

## Update WORKSPACE

The `WORKSPACE` file contains Bazel module dependency fetching and installation.

Add install steps from a release of rules_js, along with related rulesets you plan to use.

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
- to run as a tool under `bazel build` you use [package] which is a `js_run_binary`
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
load("@npm//:npm-check/package_json.bzl", "bin")

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

## Completing the migration

Once everything is migrated, we can remove the legacy rules.

In `package.json` you can remove usage of the following npm packages which contain Bazel rules, as they don't work with `rules_js`.
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

In `WORKSPACE` you can remove declaration of the following bazel modules:

- `build_bazel_rules_nodejs`

You'll need to remove `build_bazel_rules_nodejs` load() statements from BUILD files as well.
We suggest using https://docs.aspect.build/ to locate replacements for the rules you use.
