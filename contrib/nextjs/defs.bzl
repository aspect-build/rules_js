"""Utilities for building Next.js applications with Bazel and rules_js.

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
"""

load("@bazel_lib//lib:copy_file.bzl", "copy_file")
load("@bazel_lib//lib:copy_to_directory.bzl", "copy_to_directory")
load("@bazel_lib//lib:directory_path.bzl", "directory_path")
load("//js:defs.bzl", "js_binary", "js_run_binary", "js_run_devserver")

# The Next.js output directory which is not configurable
_next_build_out = ".next"

# The Next.js config file which is not configurable (other then file extension).
_next_build_config = "next.config.mjs"

# A label to the rules_js/contrib config file.
_next_standalone_config = Label("next.bazel.mjs")

def nextjs(
        name,
        srcs,
        next_js_binary,
        config = "next.config.mjs",
        data = [],
        serve_data = [],
        **kwargs):
    """Generates Next.js build, dev & start targets.

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

    Args:
        name: the name of the build target

        config: the Next.js config file. Typically `next.config.mjs`.

        srcs: Source files to include in build & dev targets.
            Typically these are source files or transpiled source files in Next.js source folders
            such as `pages`, `public` & `styles`.

        data: Data files to include in all targets.
            These are typically npm packages required for the build & configuration files such as
            package.json and next.config.js.

        serve_data: Data files to include in devserver targets

        next_js_binary: The next `js_binary` target to use for running Next.js

            Typically this is a js_binary target created using `bin` loaded from the `package_json.bzl`
            file of the npm package.

            See main docstring above for example usage.

        **kwargs: Other attributes passed to all targets such as `tags`.
    """

    nextjs_build(
        name = name,
        config = config,
        srcs = srcs,
        next_js_binary = next_js_binary,
        data = data,
        **kwargs
    )
    nextjs_dev(
        name = name + ".dev",
        config = config,
        srcs = srcs,
        data = data + serve_data,
        next_js_binary = next_js_binary,
        **kwargs
    )
    nextjs_start(
        name = name + ".start",
        config = config,
        app = ":{}".format(name),
        next_js_binary = next_js_binary,
        # NOTE: must include `srcs` in addition to the pre-compiled `app` to include transitive
        # deps such as npm packages, including the core Next.js and react packages. Could possibly
        # remove source files and only include transitive deps.
        data = data + srcs + serve_data,
        **kwargs
    )

def nextjs_build(name, config, srcs, next_js_binary, data = [], **kwargs):
    """Build the Next.js production artifact.

    See https://nextjs.org/docs/pages/api-reference/cli/next#build

    Args:
        name: the name of the build target
        config: the Next.js config file
        srcs: the sources to include in the build, including any transitive deps
        data: the data files to include in the build

        next_js_binary: The next `js_binary` target to use for running Next.js

            Typically this is a js_binary target created using `bin` loaded from the `package_json.bzl`
            file of the npm package.

            See main docstring above for example usage.

        **kwargs: Other attributes passed to all targets such as `tags`, env
    """
    js_run_binary(
        name = name,
        tool = next_js_binary,
        args = ["build"],
        srcs = srcs + data + [config],
        out_dirs = [_next_build_out],
        chdir = native.package_name(),
        mnemonic = "NextJs",
        progress_message = "Compile Next.js app %{label}",
        **kwargs
    )

def nextjs_start(name, config, app, next_js_binary, data = [], **kwargs):
    """Run the Next.js production server for an app.

    See https://nextjs.org/docs/pages/api-reference/cli/next#next-start-options

    Args:
        name: the name of the build target
        config: the Next.js config file
        app: the pre-compiled Next.js application, typically the output of `nextjs_build`
        data: additional server data

        next_js_binary: The next `js_binary` target to use for running Next.js

            Typically this is a js_binary target created using `bin` loaded from the `package_json.bzl`
            file of the npm package.

            See main docstring above for example usage.

        **kwargs: Other attributes passed to all targets such as `tags`, env
    """

    js_run_devserver(
        name = name,
        tool = next_js_binary,
        args = ["start"],
        data = data + [app, config],
        chdir = native.package_name(),
        **kwargs
    )

def nextjs_dev(name, config, srcs, data, next_js_binary, **kwargs):
    """Run the Next.js development server.

    See https://nextjs.org/docs/pages/api-reference/cli/next#next-dev-options

    Args:
        name: the name of the build target
        config: the Next.js config file
        srcs: the sources to include in the build, including any transitive deps
        data: additional devserver runtime data

        next_js_binary: The next `js_binary` target to use for running Next.js

            Typically this is a js_binary target created using `bin` loaded from the `package_json.bzl`
            file of the npm package.

            See main docstring above for example usage.

        **kwargs: Other attributes passed to all targets such as `tags`, env
    """
    js_run_devserver(
        name = name,
        tool = next_js_binary,
        args = ["dev"],
        data = srcs + data + [config],
        chdir = native.package_name(),
        **kwargs
    )

# ---------------------------------------------------------------------------------------------
# Standalone Next.js build & server binary.
# ---------------------------------------------------------------------------------------------

def nextjs_standalone_build(name, config, srcs, next_js_binary, data = [], **kwargs):
    """Compile a standalone Next.js application.

    See https://nextjs.org/docs/app/api-reference/config/next-config-js/output#automatically-copying-traced-files

    NOTE: a `next.config.mjs` is generated, wrapping the passed `config`, to overcome Next.js limitation with bazel,
    rules_js and pnpm (with hoist=false, as required by rules_js).

    Due to the generated `next.config.mjs` file the `nextjs_standalone_build(config)` must have a unique name
    or file path that does not conflict with standard Next.js config files.

    Issues worked around by the generated config include:
    * https://github.com/vercel/next.js/issues/48017
    * https://github.com/aspect-build/rules_js/issues/714

    Args:
        name: the name of the build target
        config: the Next.js config file
        srcs: the sources to include in the build, including any transitive deps
        next_js_binary: the Next.js binary to use for building
        data: the data files to include in the build
        **kwargs: Other attributes passed to all targets such as `tags`, env
    """

    # Wrap the config file to add necessary bazel logic
    env = kwargs.pop("env", {})
    env["NEXTJS_STANDALONE_CONFIG"] = "$(locations %s)" % config
    copy_file(
        name = "_%s.standalone_config_file" % name,
        src = _next_standalone_config,
        out = _next_build_config,
        visibility = ["//visibility:private"],
        tags = ["manual"],
    )

    # `next build` of the standalone application
    js_run_binary(
        name = name,
        tool = next_js_binary,
        env = env,
        args = ["build"],
        srcs = srcs + data + [":_%s.standalone_config_file" % name, config],
        out_dirs = [_next_build_out],
        chdir = native.package_name(),
        mnemonic = "NextJs",
        progress_message = "Compile Next.js standalone app %{label}",
        **kwargs
    )

def nextjs_standalone_server(name, app, pkg = None, data = [], **kwargs):
    """Configures the output of a standalone Next.js application to be a standalone server binary.

    See the Next.js [standalone server documentation](https://nextjs.org/docs/app/api-reference/config/next-config-js/output#automatically-copying-traced-files)
    for details on the standalone server directory structure.

    This function is normally used in conjunction with `nextjs_standalone_build` to create a standalone
    Next.js application. The standalone server is a `js_binary` target that can be run with `bazel run`
    or deployed in a container image etc.

    Args:
        name: the name of the binary target

        app: the standalone app directory, typically the output of `nextjs_standalone_build`

        pkg: the directory server.js is in within the standalone/ directory.

            This is normally the application path relative to the pnpm-lock.yaml.

            Default: native.package_name() (for a pnpm-lock.yaml in the root of the workspace)

        data: runtime data required to run the standalone server.

            Normally requires `[":node_modules/next", ":node_modules/react"]` which are not included
            in the Next.js standalone output.

        **kwargs: additional `js_binary` attributes
    """

    # The output directory containing the standalone application.
    standalone_outdir = name

    if pkg == None:
        pkg = native.package_name()

    # The standalone server binary
    js_binary(
        name = name,
        entry_point = ":_{}.js".format(name),
        chdir = native.package_name(),
        data = data,
        **kwargs
    )

    # The server entry point into the standalone directory.
    directory_path(
        name = "_{}.js".format(name),
        directory = ":_{}.standalone".format(name),
        path = "standalone/{}/server.js".format(pkg),
        visibility = ["//visibility:private"],
        tags = ["manual"],
    )

    # Copy the standalone directory and public/static to create a standalone server.
    # See https://nextjs.org/docs/pages/api-reference/config/next-config-js/output#automatically-copying-traced-files
    copy_to_directory(
        name = "_{}.standalone".format(name),
        srcs = [app] + native.glob(["public/**"]),
        include_srcs_patterns = [
            "public/**",
            "{}/static/**".format(_next_build_out),
            "{}/standalone/**".format(_next_build_out),
        ],
        exclude_srcs_patterns = [
            # TODO: exclude non-deterministic and log/trace files?
        ],
        replace_prefixes = {
            "{}/standalone".format(_next_build_out): "standalone",
            "{}/static".format(_next_build_out): "standalone/{}/{}/static".format(pkg, _next_build_out),
            "public": "standalone/{}/public".format(pkg),
        },
        out = standalone_outdir,
        visibility = ["//visibility:private"],
        tags = ["manual"],
    )
