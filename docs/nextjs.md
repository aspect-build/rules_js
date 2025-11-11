<!-- Generated with Stardoc: http://skydoc.bazel.build -->

Utilities for building Next.js applications with Bazel and rules_js.

All invocations of Next.js are done through a `next_js_binary` target passed into the macros.
This is normally generated once alongside the `package.json` containing the `next` dependency:

```
load("@npm//:next/package_json.bzl", next_bin = "bin")

next_bin.next_binary(
    name = "next_js_binary",
    visibility = ["//visibility:public"],
)
```

The next binary is then passed into the macros, for example:

```
nextjs_build(
    name = "next",
    config = "next.config.mjs",
    srcs = glob(["src/**"]),
    next_js_binary = "//:next_js_binary",
)
```

# Macros

There are two sets of macros for building Next.js applications: standard and standalone.

## Standard

- `nextjs()`: wrap the build+dev+start targets
- `nextjs_build()`: the Next.js [build](https://nextjs.org/docs/app/building-your-application/deploying#production-builds) command
- `nextjs_dev()`: the Next.js [dev](https://nextjs.org/docs/app/getting-started/installation#run-the-development-server) command
- `nextjs_start()`: the Next.js [start](https://nextjs.org/docs/app/building-your-application/deploying#nodejs-server) command,
   accepting a Next.js build artifact to start

## Standalone

For [standalone applications](https://nextjs.org/docs/app/api-reference/config/next-config-js/output#automatically-copying-traced-files):
- `nextjs_standalone_build()`: the Next.js [build](https://nextjs.org/docs/app/building-your-application/deploying#production-builds) command,
   configured for a standalone application within bazel
- `nextjs_standalone_server()`: constructs a standalone Next.js server `js_binary` following the
  [standalone directory structure guidelines](https://nextjs.org/docs/app/api-reference/config/next-config-js/output#automatically-copying-traced-files)

<a id="nextjs"></a>

## nextjs

<pre>
load("@aspect_rules_js//contrib/nextjs:defs.bzl", "nextjs")

nextjs(<a href="#nextjs-name">name</a>, <a href="#nextjs-srcs">srcs</a>, <a href="#nextjs-next_js_binary">next_js_binary</a>, <a href="#nextjs-config">config</a>, <a href="#nextjs-data">data</a>, <a href="#nextjs-serve_data">serve_data</a>, <a href="#nextjs-kwargs">kwargs</a>)
</pre>

Generates Next.js build, dev & start targets.

`{name}`       - a Next.js production bundle
`{name}.dev`   - a Next.js devserver
`{name}.start` - a Next.js prodserver

Use this macro in the BUILD file at the root of a next app where the `next.config.mjs`
file is located.

For example, a target such as `//app:next` in `app/BUILD.bazel`

```
next(
    name = "next",
    config = "next.config.mjs",
    srcs = glob(["src/**"]),
    data = [
        "//:node_modules/next",
        "//:node_modules/react-dom",
        "//:node_modules/react",
        "package.json",
    ],
    next_js_binary = "//:next_js_binary",
)
```

will create the targets:

```
//app:next
//app:next.dev
//app:next.start
```

To build the above next app, equivalent to running `next build` outside Bazel:

```
bazel build //app:next
```

To run the development server in watch mode with
[ibazel](https://github.com/bazelbuild/bazel-watcher), equivalent to running
`next dev` outside Bazel:

```
ibazel run //app:next.dev
```

To run the production server in watch mode with
[ibazel](https://github.com/bazelbuild/bazel-watcher), equivalent to running
`next start` outside Bazel:

```
ibazel run //app:next.start
```


**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="nextjs-name"></a>name |  the name of the build target   |  none |
| <a id="nextjs-srcs"></a>srcs |  Source files to include in build & dev targets. Typically these are source files or transpiled source files in Next.js source folders such as `pages`, `public` & `styles`.   |  none |
| <a id="nextjs-next_js_binary"></a>next_js_binary |  The next `js_binary` target to use for running Next.js<br><br>Typically this is a js_binary target created using `bin` loaded from the `package_json.bzl` file of the npm package.<br><br>See main docstring above for example usage.   |  none |
| <a id="nextjs-config"></a>config |  the Next.js config file. Typically `next.config.mjs`.   |  `"next.config.mjs"` |
| <a id="nextjs-data"></a>data |  Data files to include in all targets. These are typically npm packages required for the build & configuration files such as package.json and next.config.js.   |  `[]` |
| <a id="nextjs-serve_data"></a>serve_data |  Data files to include in devserver targets   |  `[]` |
| <a id="nextjs-kwargs"></a>kwargs |  Other attributes passed to all targets such as `tags`.   |  none |


<a id="nextjs_build"></a>

## nextjs_build

<pre>
load("@aspect_rules_js//contrib/nextjs:defs.bzl", "nextjs_build")

nextjs_build(<a href="#nextjs_build-name">name</a>, <a href="#nextjs_build-config">config</a>, <a href="#nextjs_build-srcs">srcs</a>, <a href="#nextjs_build-next_js_binary">next_js_binary</a>, <a href="#nextjs_build-data">data</a>, <a href="#nextjs_build-kwargs">kwargs</a>)
</pre>

Build the Next.js production artifact.

See https://nextjs.org/docs/pages/api-reference/cli/next#build


**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="nextjs_build-name"></a>name |  the name of the build target   |  none |
| <a id="nextjs_build-config"></a>config |  the Next.js config file   |  none |
| <a id="nextjs_build-srcs"></a>srcs |  the sources to include in the build, including any transitive deps   |  none |
| <a id="nextjs_build-next_js_binary"></a>next_js_binary |  The next `js_binary` target to use for running Next.js<br><br>Typically this is a js_binary target created using `bin` loaded from the `package_json.bzl` file of the npm package.<br><br>See main docstring above for example usage.   |  none |
| <a id="nextjs_build-data"></a>data |  the data files to include in the build   |  `[]` |
| <a id="nextjs_build-kwargs"></a>kwargs |  Other attributes passed to all targets such as `tags`, env   |  none |


<a id="nextjs_dev"></a>

## nextjs_dev

<pre>
load("@aspect_rules_js//contrib/nextjs:defs.bzl", "nextjs_dev")

nextjs_dev(<a href="#nextjs_dev-name">name</a>, <a href="#nextjs_dev-config">config</a>, <a href="#nextjs_dev-srcs">srcs</a>, <a href="#nextjs_dev-data">data</a>, <a href="#nextjs_dev-next_js_binary">next_js_binary</a>, <a href="#nextjs_dev-kwargs">kwargs</a>)
</pre>

Run the Next.js development server.

See https://nextjs.org/docs/pages/api-reference/cli/next#next-dev-options


**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="nextjs_dev-name"></a>name |  the name of the build target   |  none |
| <a id="nextjs_dev-config"></a>config |  the Next.js config file   |  none |
| <a id="nextjs_dev-srcs"></a>srcs |  the sources to include in the build, including any transitive deps   |  none |
| <a id="nextjs_dev-data"></a>data |  additional devserver runtime data   |  none |
| <a id="nextjs_dev-next_js_binary"></a>next_js_binary |  The next `js_binary` target to use for running Next.js<br><br>Typically this is a js_binary target created using `bin` loaded from the `package_json.bzl` file of the npm package.<br><br>See main docstring above for example usage.   |  none |
| <a id="nextjs_dev-kwargs"></a>kwargs |  Other attributes passed to all targets such as `tags`, env   |  none |


<a id="nextjs_standalone_build"></a>

## nextjs_standalone_build

<pre>
load("@aspect_rules_js//contrib/nextjs:defs.bzl", "nextjs_standalone_build")

nextjs_standalone_build(<a href="#nextjs_standalone_build-name">name</a>, <a href="#nextjs_standalone_build-config">config</a>, <a href="#nextjs_standalone_build-srcs">srcs</a>, <a href="#nextjs_standalone_build-next_js_binary">next_js_binary</a>, <a href="#nextjs_standalone_build-data">data</a>, <a href="#nextjs_standalone_build-kwargs">kwargs</a>)
</pre>

Compile a standalone Next.js application.

See https://nextjs.org/docs/app/api-reference/config/next-config-js/output#automatically-copying-traced-files

NOTE: a `next.config.mjs` is generated, wrapping the passed `config`, to overcome Next.js limitation with bazel,
rules_js and pnpm (with hoist=false, as required by rules_js).

Due to the generated `next.config.mjs` file the `nextjs_standalone_build(config)` must have a unique name
or file path that does not conflict with standard Next.js config files.

Issues worked around by the generated config include:
* https://github.com/vercel/next.js/issues/48017
* https://github.com/aspect-build/rules_js/issues/714


**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="nextjs_standalone_build-name"></a>name |  the name of the build target   |  none |
| <a id="nextjs_standalone_build-config"></a>config |  the Next.js config file   |  none |
| <a id="nextjs_standalone_build-srcs"></a>srcs |  the sources to include in the build, including any transitive deps   |  none |
| <a id="nextjs_standalone_build-next_js_binary"></a>next_js_binary |  the Next.js binary to use for building   |  none |
| <a id="nextjs_standalone_build-data"></a>data |  the data files to include in the build   |  `[]` |
| <a id="nextjs_standalone_build-kwargs"></a>kwargs |  Other attributes passed to all targets such as `tags`, env   |  none |


<a id="nextjs_standalone_server"></a>

## nextjs_standalone_server

<pre>
load("@aspect_rules_js//contrib/nextjs:defs.bzl", "nextjs_standalone_server")

nextjs_standalone_server(<a href="#nextjs_standalone_server-name">name</a>, <a href="#nextjs_standalone_server-app">app</a>, <a href="#nextjs_standalone_server-pkg">pkg</a>, <a href="#nextjs_standalone_server-data">data</a>, <a href="#nextjs_standalone_server-kwargs">kwargs</a>)
</pre>

Configures the output of a standalone Next.js application to be a standalone server binary.

See the Next.js [standalone server documentation](https://nextjs.org/docs/app/api-reference/config/next-config-js/output#automatically-copying-traced-files)
for details on the standalone server directory structure.

This function is normally used in conjunction with `nextjs_standalone_build` to create a standalone
Next.js application. The standalone server is a `js_binary` target that can be run with `bazel run`
or deployed in a container image etc.


**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="nextjs_standalone_server-name"></a>name |  the name of the binary target   |  none |
| <a id="nextjs_standalone_server-app"></a>app |  the standalone app directory, typically the output of `nextjs_standalone_build`   |  none |
| <a id="nextjs_standalone_server-pkg"></a>pkg |  the directory server.js is in within the standalone/ directory.<br><br>This is normally the application path relative to the pnpm-lock.yaml.<br><br>Default: native.package_name() (for a pnpm-lock.yaml in the root of the workspace)   |  `None` |
| <a id="nextjs_standalone_server-data"></a>data |  runtime data required to run the standalone server.<br><br>Normally requires `[":node_modules/next", ":node_modules/react"]` which are not included in the Next.js standalone output.   |  `[]` |
| <a id="nextjs_standalone_server-kwargs"></a>kwargs |  additional `js_binary` attributes   |  none |


<a id="nextjs_start"></a>

## nextjs_start

<pre>
load("@aspect_rules_js//contrib/nextjs:defs.bzl", "nextjs_start")

nextjs_start(<a href="#nextjs_start-name">name</a>, <a href="#nextjs_start-config">config</a>, <a href="#nextjs_start-app">app</a>, <a href="#nextjs_start-next_js_binary">next_js_binary</a>, <a href="#nextjs_start-data">data</a>, <a href="#nextjs_start-kwargs">kwargs</a>)
</pre>

Run the Next.js production server for an app.

See https://nextjs.org/docs/pages/api-reference/cli/next#next-start-options


**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="nextjs_start-name"></a>name |  the name of the build target   |  none |
| <a id="nextjs_start-config"></a>config |  the Next.js config file   |  none |
| <a id="nextjs_start-app"></a>app |  the pre-compiled Next.js application, typically the output of `nextjs_build`   |  none |
| <a id="nextjs_start-next_js_binary"></a>next_js_binary |  The next `js_binary` target to use for running Next.js<br><br>Typically this is a js_binary target created using `bin` loaded from the `package_json.bzl` file of the npm package.<br><br>See main docstring above for example usage.   |  none |
| <a id="nextjs_start-data"></a>data |  additional server data   |  `[]` |
| <a id="nextjs_start-kwargs"></a>kwargs |  Other attributes passed to all targets such as `tags`, env   |  none |


