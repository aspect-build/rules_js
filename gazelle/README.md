# TypeScript Gazelle plugin

This directory contains a plugin for
[Gazelle](https://github.com/bazelbuild/bazel-gazelle)
that generates BUILD file content for TypeScript code.

## Installation

First, you'll need to add Gazelle to your `WORKSPACE` file.
Follow the instructions at https://github.com/bazelbuild/bazel-gazelle#running-gazelle-with-bazel

Next, we need to fetch the third-party Go libraries that the TypeScript extension
depends on.

Add this to your `WORKSPACE`:

```starlark
# To compile the rules_js gazelle extension from source,
# we must fetch some third-party go dependencies that it uses.
load("@rules_js//gazelle:deps.bzl", _ts_gazelle_deps = "gazelle_deps")

_ts_gazelle_deps()
```

That's it, now you can run `bazel run //:gazelle` anytime you edit TypeScript code,
and it should update your `BUILD` files correctly.

## Usage

Gazelle is non-destructive.
It will try to leave your edits to BUILD files alone, only making updates to `ts_*` targets.
However it will remove dependencies that appear to be unused, so it's a
good idea to check in your work before running Gazelle so you can easily
revert any changes it made.

The rules_js extension assumes some conventions about your TypeScript code.
These are noted below, and might require changes to your existing code.

Note that the `gazelle` program has multiple commands. At present, only the `update` command (the default) does anything for TypeScript code.

### Directives

You can configure the extension using directives, just like for other
languages. These are just comments in the `BUILD.bazel` file which
govern behavior of the extension when processing files under that
folder.

See https://github.com/bazelbuild/bazel-gazelle#directives
for some general directives that may be useful.
In particular, the `resolve` directive is language-specific
and can be used with TypeScript.
Examples of these directives in use can be found in the
/gazelle/tests folder in the aspect-build/rules_js repo.

TODO TypeScript-specific directives are as follows:

| **Directive**            | **Default value** |
| ------------------------ | ----------------- |
| `# gazelle:typescript_*` | ?????             |
| TODO: list directives.   |                   |

### Libraries

TypeScript source files are those ending in `.ts`, `.tsx` as well as `.js`, `.mjs`.

TODO: differenciate source vs spec files?

First, we look for the nearest ancestor BUILD file starting from the folder
containing the TypeScript source file.

If there is no `ts_project` in this BUILD file, one is created, using the
package name as the target's name. This makes it the default target in the
package.

Next, all source files are collected into the `srcs` of the `ts_project`.

Finally, the `import` statements in the source files are parsed, and
dependencies are added to the `deps` attribute.

TODO: require statements?

### TODO: Tests - \*.spec.ts, ?

## Developing on the extension

Gazelle extensions are written in Go.

The Go dependencies are managed by the go.mod file.
After changing that file, run `go mod tidy` to get a `go.sum` file,
then run `bazel run //:update_go_deps` to convert that to the `gazelle/deps.bzl` file.
The latter is loaded in our `/WORKSPACE` to define the external repos
that we can load Go dependencies from.

Then after editing Go code, run `bazel run //:gazelle` to generate/update
go\_\* rules in the BUILD.bazel files in our repo.
