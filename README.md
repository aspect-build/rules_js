# Bazel rules for JavaScript

This ruleset is a high-performance alternative to the `build_bazel_rules_nodejs` Bazel module and
accompanying npm packages hosted in https://github.com/bazelbuild/rules_nodejs.

It is not a complete replacement for rules_nodejs, as the foundational layer is still used:

![Block Diagram](./block_diagram.svg)

The common layer here is the `rules_nodejs` Bazel module, documented as the "core" in
https://bazelbuild.github.io/rules_nodejs/:

> It is currently useful for Bazel Rules developers who want to make their own JavaScript support.

That's what `rules_js` does! It's a completely different approach to making JS tooling work under Bazel.

First, there's dependency management.

-   `build_bazel_rules_nodejs` uses existing package managers by calling `npm install` or `yarn install` on a whole `package.json`.
-   `rules_js` uses Bazel's downloader to fetch only the packages needed for the requested targets, then mimics [`pnpm`](https://pnpm.io/) to lay out a `node_modules` tree.

Then, there's how a nodejs tool can be executed:

-   `build_bazel_rules_nodejs` follows the Bazel idiom: sources in one folder, outputs in another.
-   `rules_js` follows the npm idiom: sources and outputs together in a common folder.

There are trade-offs involved here, but we think the `rules_js` approach is superior for all users,
especially those at large scale. Read below for more in-depth discussion of the design differences
and trade-offs you should be aware of.

rules_js is just a part of what Aspect provides:

-   _Need help?_ This ruleset has support provided by https://aspect.dev.
-   Javascript
    -   **rules_js** - Rules for running nodejs tools and building JavaScript projects
    -   [rules_esbuild](https://github.com/aspect-build/rules_esbuild) - Bazel rules for <https://esbuild.github.io/> JS bundler
    -   [rules_terser](https://github.com/aspect-build/rules_terser) - Bazel rules for <https://terser.org/> - a JavaScript minifier
    -   [rules_swc](https://github.com/aspect-build/rules_swc) - Bazel rules for the swc toolchain <https://swc.rs/>
    -   [rules_ts](https://github.com/aspect-build/rules_ts) - Bazel rules for the `tsc` compiler from <http://typescriptlang.org>
    -   [rules_webpack](https://github.com/aspect-build/rules_webpack) - Bazel rules for webpack bundler <https://webpack.js.org/>
    -   [rules_rollup](https://github.com/aspect-build/rules_rollup) - Bazel rules for <https://rollupjs.org/> - a JavaScript bundler
    -   [rules_jest](https://github.com/aspect-build/rules_jest) - Bazel rules to run tests using https://jestjs.io
-   Python
    -   [rules_py](https://github.com/aspect-build/rules_py) - Bazel rules for running Python tools and building Python projects
-   C / C++
    -   [gcc-toolchain](https://github.com/aspect-build/gcc-toolchain) - A fully-hermetic Bazel GCC toolchain for Linux

## Installation

From the release you wish to use:
<https://github.com/aspect-build/rules_js/releases>
copy the WORKSPACE snippet into your `WORKSPACE` file.

## Usage

See the API documentation in the [docs](docs/) folder and the example usage in the [example](example/) folder.
Note that the example also relies on code in the `/WORKSPACE` file in the root of this repo.

## Design

The authors of `rules_js` spent four years writing and re-writing `build_bazel_rules_nodejs`.
We learned a lot from that project, as well as from discussions with [Rush](https://rushjs.io/) maintainer @octogonz.

There are two core problems:

-   How do you install third-party dependencies?
-   How does a running nodejs program resolve those dependencies?

And there's a fundamental trade-off: make it fast and deterministic, or support 100% of existing use cases.

Over the years we tried a number of solutions and each end of the trade-off spectrum.

### Installing third-party libraries

Downloading packages should be Bazel's job. It has a full featured remote downloader, with a content-address-cached (confusingly called the "repository cache"). We now mirror pnpm's lock file
into starlark code, then use only Bazel repository rules to perform fetches and translate the
dependency graph into Bazel's representation.

See the [design doc](https://hackmd.io/gu2Nj0TKS068LKAf8KanuA)

### Running nodejs programs

Fundamentally, Bazel operates out of a different filesystem layout than Node.
Bazel keeps outputs in a distinct tree outside of the sources.

Our first attempt was based on what Google does: monkey-patch the implementation of `require` in
NodeJS itself, so that every resolution can be aware of the source/output tree difference.
The main downside to this is compatibility: many packages on npm make their own assumptions about
how to resolve dependencies without asking the `require` implementation, and you can't patch them all.
Unlike Google, most of us don't want to re-write all the npm packages we use to be compatible.

Our second attempt was essentially to run `npm link` before running a program, using a "linker".
This was largely successful at papering over the filesystem layout differences without disrupting
execution of programs. However, it required a lot of workarounds anytime a JS tool wanted to be
aware of the input and output locations on disk. For example, many tools like react-scripts (the
build system used by Create React App aka. CRA) insist on writing their outputs relative to the
working directory. Such programs were forced to be run with Bazel's output folder as the working
directory, and their sources copied to that location.

Our third attempt is here in `rules_js`, where we take that react-scripts-prompted workaround to the
extreme. We _always_ run JS tools with the working directory in Bazel's output tree.
We can use a `pnpm`-style layout tool to create a `node_modules` under `bazel-out`, and all resolutions
naturally work.

This third approach has trade-offs.

-   The benefit is that very intractable problems like TypeScript's `rootDirs` just go away.
    In that example, we filed https://github.com/microsoft/TypeScript/issues/37378 but it probably
    won't be solved, so many users trip over issues like
    [this](https://github.com/bazelbuild/rules_nodejs/issues/3423) and
    [this](https://github.com/bazelbuild/rules_nodejs/issues/3421). Now this just works, plus results like sourcemaps look like users expect: just like they would if the tool had written outputs in the source tree.
-   The downside is that Bazel rules/macro authors (even `genrule` authors) must re-path
    inputs and outputs to account for the working directory under `bazel-out`,
    and must ensure that sources are copied there first.
