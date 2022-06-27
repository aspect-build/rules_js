# rules_js documentation

> Migrating from rules_nodejs? Start at the [Migration Guide](./migrate.md)

Stuck?

-   See the [Frequently asked questions](./faq.md)
-   Ask in `#javascript` on <http://slack.bazel.build>
-   Check for [known issues](https://github.com/aspect-build/rules_js/issues)
-   Pay for support, provided by <https://aspect.dev>.

## Installation

From the release you wish to use:
<https://github.com/aspect-build/rules_js/releases>
copy the WORKSPACE snippet into your `WORKSPACE` file.

Note that [bzlmod] is experimentally supported as well.

## Usage

### Bazel basics

Bazel's `BUILD` or `BUILD.bazel` files are used to declare the dependency graph of your code.
They describe the source files and their dependencies, and declare entry points for programs or tests.
However, they don't say _how to build_ the code, that's the job of Bazel rules.

Because `BUILD` files typically declare a finer-grained dependency graph than `package.json` files, Bazel can be smarter about what to fetch or invalidate for a given build.
For example, Bazel might only need to fetch a single npm package for a simple build,
where you might experience other tools installing the entire `package.json` file.

On the other hand, authoring BUILD files is a chore that's required under Bazel and not in
other tools like Rush or Nx. We plan a [Gazelle] extension soon which automates much of this toil.

Other recommendations:

-   Put [common flags](https://blog.aspect.dev/bazelrc-flags) in your `.bazelrc` file.
-   Use [Renovate](https://docs.renovatebot.com/) to keep your Bazel dependencies up-to-date.

### Node.js

rules_js depends on rules_nodejs version 5.0 or greater.

Installation is included in the `WORKSPACE` snippet you pasted from the Installation instructions above.

**API docs:**

-   Installing and choosing the version of Node.js:
    <https://bazelbuild.github.io/rules_nodejs/install.html>
-   Rules API: <https://bazelbuild.github.io/rules_nodejs/Core.html>
-   The Node.js toolchain: <https://bazelbuild.github.io/rules_nodejs/Toolchains.html>

### Use third-party packages from npm

rules_js accesses npm packages using [pnpm].
pnpm's "virtual store" of packages aligns with Bazel's "external repositories",
and the pnpm "linker" which creates the `node_modules` tree has semantics we can reproduce with Bazel actions.

If your code works with pnpm, then you should expect it works under Bazel as well.
This means that if your issue can be reproduced outside of Bazel, using a reproduction with only pnpm,
then we ask that you fix the issue there, and will close such issues filed on rules_js.

The typical usage is to import an entire `pnpm-lock.yaml` file.
Create such a file if you don't have one. You could install pnpm on your machine, or use `npx` to run it.
For example, this command creates a lockfile with minimal installation needed:

```shell
$ npx pnpm install --lockfile-only
```

Next, you'll typically use `npm_translate_lock` to translate the Yaml file to Starlark, which Bazel extensions understand.
The `WORKSPACE` snippet you pasted above already contains this code.

Technically, we run a port of pnpm rather than pnpm itself. The reasoning is as follows:

1. You don't need to install pnpm on your machine to build and test with Bazel.
1. We re-use pnpm's resolver, by consuming the `pnpm-lock.yaml` file it produces.
1. We use Bazel's downloader API to fetch package tarballs and extract them to external repositories.
   To modify the URLs Bazel uses to download packages (for example, to fetch from Artifactory), read
   <https://blog.aspect.dev/configuring-bazels-downloader>.
1. We re-use the [`@pnpm/lifecycle`](https://www.npmjs.com/package/@pnpm/lifecycle) package to perform postinstall steps.
   (These run as cacheable Bazel actions.)
1. Finally, you link the `node_modules` tree by adding a `npm_link_package` or `npm_link_all_packages` in your `BUILD` file,
   which populates a tree under `bazel-bin/[path/to/package]/node_modules`.

After importing the lockfile, you should be able to fetch the resulting repository.
Assuming your `npm_translate_lock` was named `npm`, you can run:

```shell
$ bazel fetch @npm//...
```

Next, we'll need to "link" these npm packages into a `node_modules` tree.

> Bazel doesn't use the `node_modules` installed in your source tree.
> You do not need to run `pnpm install` before running Bazel commands.
> Changes you make to files under `node_modules` in your source tree are not reflected in Bazel results.

Typically, you'll just link all npm packages into the Bazel package containing the `package.json` file.
If you use [pnpm workspaces], you will do this for each npm package in your monorepo.

In `BUILD.bazel`:

```starlark
load("@npm//:defs.bzl", "npm_link_all_packages")

npm_link_all_packages()
```

You can see this working by running `bazel build ...`, then look in the `bazel-bin` folder.

You'll see something like this:

```bash
# the virtual store
bazel-bin/node_modules/.aspect_rules_js
 # symlink into the virtual store
bazel-bin/node_modules/some_pkg
# If you used pnpm workspaces:
bazel-bin/packages/some_pkg/node_modules/some_dep
```

**API docs:**

-   [npm_import](./npm_import.md): Import all packages from the pnpm-lock.yaml file, or import individual packages.
-   [npm_link_package](./npm_link_package.md): Link npm package(s) into the `bazel-bin/[path/to/package]/node_modules` tree so that the Node.js runtime can resolve them.

### JavaScript

rules_js provides some primitives to work with JS files.
However, since JavaScript is an interpreted language, simple use cases don't require performing build steps like compilation.

**API docs:**

-   [js_library](./js_library.md): Declare a logical grouping of JS files and their dependencies.
-   [js_binary](./js_binary.md): Declare a Node.js executable program.
-   [js_run_binary](./js_run_binary.md): Run a Node.js executable program as the "tool" in a Bazel action that produces outputs, similar to `genrule`.

### Using binaries published to npm

rules_js automatically mirrors the `bin` field from the `package.json` file of your npm dependencies
to a Starlark API you can load from in your BUILD file or macro.

For example, if you depend on the `typescript` npm package, you write this in `BUILD`:

```starlark=
load("@npm//:typescript/package_json.bzl", typescript_bin = "bin")

typescript_bin.tsc(
    name = "compile",
    srcs = [
        "fs.ts",
        "tsconfig.json",
        "//:node_modules/@types/node",
    ],
    outs = ["fs.js"],
    chdir = package_name(),
    args = ["-p", "tsconfig.json"],
)
```

> Note: this doesn't cause an eager fetch!
> Bazel doesn't download the typescript package when loading this file, so you can safely write this
> even in a BUILD.bazel file that includes unrelated rules.

To inspect what's in the `@npm` workspace, start with a `bazel query` like the following:

```shell
$ bazel query @npm//... --output=location
/shared/cache/bazel/user_base/581b2ac03dd093577e8a6ba6b6509be5/external/npm/BUILD.bazel:24:12: bzl_library rule @npm//:@types/node
/shared/cache/bazel/user_base/581b2ac03dd093577e8a6ba6b6509be5/external/npm/BUILD.bazel:17:12: bzl_library rule @npm//:typescript
/shared/cache/bazel/user_base/581b2ac03dd093577e8a6ba6b6509be5/external/npm/examples/macro/BUILD.bazel:19:12: bzl_library rule @npm//examples/macro:mocha
/shared/cache/bazel/user_base/581b2ac03dd093577e8a6ba6b6509be5/external/npm/examples/macro/BUILD.bazel:5:12: bzl_library rule @npm//examples/macro:mocha-junit-reporter
/shared/cache/bazel/user_base/581b2ac03dd093577e8a6ba6b6509be5/external/npm/examples/macro/BUILD.bazel:12:12: bzl_library rule @npm//examples/macro:mocha-multi-reporters
```

This shows locations on disk where the npm packages can be loaded.

To see the definition of one of these targets, you can run another `bazel query`:

```shell
$ bazel query --output=build @npm//:typescript
# /shared/cache/bazel/user_base/581b2ac03dd093577e8a6ba6b6509be5/external/npm/BUILD.bazel:17:12
bzl_library(
  name = "typescript",
  visibility = ["//visibility:public"],
  srcs = ["@npm//:typescript/package_json.bzl"],
  deps = ["@npm__typescript__4.7.2//:typescript"],
)
```

This shows us that the label `@npm//:typescript/package_json.bzl` can be used to load the "bin" symbol. You can also follow the location on disk to find that file.

Each bin exposes three rules, one for each Bazel command ("verb"):

| Use          | With          | To              |
| ------------ | ------------- | --------------- |
| `foo`        | `bazel build` | produce outputs |
| `foo_binary` | `bazel run`   | side-effects    |
| `foo_test`   | `bazel test`  | assert exit `0` |

### Macros

[Bazel macros] are a critical part of making your BUILD files more maintainable.
Make sure to follow the [Style Guide](https://bazel.build/rules/bzl-style#macros) when writing a macro,
since some anti-patterns can make your BUILD files difficult to change in the future.

Like Custom Rules, Macros require you to use the starlark language, but writing a macro is much easier
since it merely composes existing rules together, rather than writing any from scratch.
We believe that most use cases can be accomplished with macros, and discourage you learning how to write
custom rules unless you're really interested in investing time becoming a Bazel expert.

You can think of Macros as a way to create your own Build System, by piping the existing tools together
(like a unix pipeline that composes command-line utilities by piping their stdout/stdin).

As an example, we could write a wrapper for the `typescript_bin.tsc` rule above.

In `tsc.bzl` we could write:

```starlark
load("@npm//:typescript/package_json.bzl", typescript_bin = "bin")

def tsc(name, args = ["-p", "tsconfig.json"], **kwargs):
    typescript_bin.tsc(
        name = name,
        args = args,
        # Always run tsc with the working directory in the project folder
        chdir = native.package_name(),
        **kwargs
    )
```

so that the users `BUILD` file can omit some of the syntax and default settings:

```starlark
load(":tsc.bzl", "tsc")

tsc(
    name = "two",
    srcs = [
        "tsconfig.json",
        "two.ts",
        "//:node_modules/@types/node",
        "//examples/js_library/one",
    ],
    outs = [
        "two.js",
    ],
)
```

### Custom rules

If macros are not sufficient to express your Bazel logic, you can use a custom rule instead.
Aspect has written a number of these based on rules_js, such as:

-   [rules_ts](https://github.com/aspect-build/rules_ts) - Bazel rules for the `tsc` compiler from <http://typescriptlang.org>
-   [rules_swc](https://github.com/aspect-build/rules_swc) - Bazel rules for the swc toolchain <https://swc.rs/>
-   [rules_jest](https://github.com/aspect-build/rules_jest) - Bazel rules to run tests using https://jestjs.io
-   [rules_esbuild](https://github.com/aspect-build/rules_esbuild) - Bazel rules for <https://esbuild.github.io/> JS bundler
-   [rules_webpack](https://github.com/aspect-build/rules_webpack) - Bazel rules for webpack bundler <https://webpack.js.org/>
-   [rules_terser](https://github.com/aspect-build/rules_terser) - Bazel rules for <https://terser.org/> - a JavaScript minifier
-   [rules_rollup](https://github.com/aspect-build/rules_rollup) - Bazel rules for <https://rollupjs.org/> - a JavaScript bundler
-   [rules_deno](https://github.com/aspect-build/rules_deno) - Bazel rules for Deno http://deno.land

You can also write your own custom rule, though this is an advanced topic and not covered in this documentation.

### Documenting your macros and custom rules

You can use [stardoc] to produce API documentation from Starlark code.
We recommend producing Markdown output, and checking those `.md` files into your source repository.
This makes it easy to browse them at the same revision as the sources.

You'll need to create `bzl_library` targets for your starlark files.
This is a good practice as it lets users of your code generate their own documentation as well.

In addition, Aspect's bazel-lib provides some helpers that make it easy to run stardoc and check that it's up-to-date.

Continuing our example, where we wrote a macro in `tsc.bzl`, we'd write this to document it, in `BUILD`:

```starlark
load("@aspect_bazel_lib//lib:docs.bzl", "stardoc_with_diff_test", "update_docs")
load("@bazel_skylib//:bzl_library.bzl", "bzl_library")

bzl_library(
    name = "tsc",
    srcs = ["tsc.bzl"],
    deps = [
        # this is a bzl_library target, exposing the package_json.bzl file we depend on
        "@npm//:typescript",
    ],
)

stardoc_with_diff_test(
    name = "tsc-docs",
    bzl_library_target = ":tsc",
)

update_docs(name = "docs")
```

### Create first-party npm packages

You can declare an npm package from sources in your repository.

The package can be exported for usage outside the repository, to a registry like npm or Artifactory.
Or, you can use it locally within a monorepo using [pnpm workspaces].

> Note: we don't yet document how to publish. For now, build the `npm_package` target with `bazel build`, then
> `cd` into the `bazel-out` folder where the package was created, and run `npm pack` or `npm publish`.

**API docs:**

-   [npm_package](./npm_package.md)

[pnpm]: https://pnpm.io/
[pnpm workspaces]: https://pnpm.io/workspaces
[bzlmod]: https://blog.aspect.dev/bzlmod
[bazel macros]: https://bazel.build/rules/macros
[gazelle]: https://github.com/bazelbuild/bazel-gazelle
