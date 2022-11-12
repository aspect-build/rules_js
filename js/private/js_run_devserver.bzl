"Implementation details for js_run_devserver rule"

load(":js_binary.bzl", "js_binary_lib")
load(":js_binary_helpers.bzl", _gather_files_from_js_providers = "gather_files_from_js_providers")
load("@bazel_skylib//lib:dicts.bzl", "dicts")

_DOC = """Runs a devserver via binary target or command.

A simple http-server, for example, can be setup as follows,

```
load("@aspect_rules_js//js:defs.bzl", "js_run_devserver")
load("@npm//:http-server/package_json.bzl", http_server_bin = "bin")

http_server_bin.http_server_binary(
    name = "http_server",
)

js_run_devserver(
    name = "serve",
    args = ["."],
    data = ["index.html"],
    tool = ":http_server",
)
```

A Next.js devserver can be setup as follows,

```
js_run_devserver(
    name = "dev",
    args = ["dev"],
    command = "./node_modules/.bin/next",
    data = [
        "next.config.js",
        "package.json",
        ":node_modules/next",
        ":node_modules/react",
        ":node_modules/react-dom",
        ":node_modules/typescript",
        "//pages",
        "//public",
        "//styles",
    ],
)
```

where the `./node_modules/.bin/next` bin entry of Next.js is configured in
`npm_translate_lock` as such,

```
npm_translate_lock(
    name = "npm",
    bins = {
        # derived from "bin" attribute in node_modules/next/package.json
        "next": {
            "next": "./dist/bin/next",
        },
    },
    pnpm_lock = "//:pnpm-lock.yaml",
)
```

and run in watch mode using [ibazel](https://github.com/bazelbuild/bazel-watcher) with
`ibazel run //:dev`.

The devserver specified by either `tool` or `command` is run in a custom sandbox that is more
compatible with devserver watch modes in Node.js tools such as Webpack and Next.js.

The custom sandbox is populated with the default outputs of all targets in `data`
as well as transitive sources & npm links.

An an optimization, virtual store files are explicitly excluded from the sandbox since the npm
links will point to the virtual store in the execroot and Node.js will follow those links as it
does within the execroot. As a result, rules_js npm package link targets such as
`//:node_modules/next` are handled efficiently. Since these targets are symlinks in the output
tree, they are recreated as symlinks in the custom sandbox and do not incur a fully copy of the
underlying npm packages.

Supports running with [ibazel](https://github.com/bazelbuild/bazel-watcher).
Only `data` files that change on incremental builds are synchronized when running with ibazel.
"""

_attrs = dicts.add(js_binary_lib.attrs, {
    "tool": attr.label(
        doc = """The devserver binary target to run.
        
Only one of `command` or `tool` may be specified.""",
        executable = True,
        cfg = "exec",
    ),
    "command": attr.string(
        doc = """The devserver command to run.

For example, this could be the bin entry of an npm package that is included
in data such as `./node_modules/.bin/next`.

Using the bin entry of next, for example, resolves issues with Next.js and React
being found in multiple node_modules trees when next is run as an encapsulated
`js_binary` tool.

Only one of `command` or `tool` may be specified.""",
    ),
})

def _impl(ctx):
    config_file = ctx.actions.declare_file("{}_config.json".format(ctx.label.name))

    launcher = js_binary_lib.create_launcher(
        ctx,
        log_prefix_rule_set = "aspect_rules_js",
        log_prefix_rule = "js_run_devserver",
        fixed_args = [config_file.short_path],
    )

    if not ctx.attr.tool and not ctx.attr.command:
        fail("Either tool or command must be specified")
    if ctx.attr.tool and ctx.attr.command:
        fail("Only one of tool or command may be specified")

    transitive_runfiles = [_gather_files_from_js_providers(
        targets = ctx.attr.data,
        include_transitive_sources = ctx.attr.include_transitive_sources,
        include_declarations = ctx.attr.include_declarations,
        include_npm_linked_packages = ctx.attr.include_npm_linked_packages,
    )]

    # The .to_list() calls here are intentional and cannot be avoided; they should be small sets of
    # files as they only include direct npm links (node_modules/foo) and the virtual store tree
    # artifacts those symlinks point to (node_modules/.aspect_rules_js/foo@1.2.3/node_modules/foo)
    data_files = []
    for f in depset(transitive = transitive_runfiles + [dep.files for dep in ctx.attr.data]).to_list():
        # don't include the virtual store tree artifact; only the node_module link is needed
        if not "/.aspect_rules_js/" in f.path:
            data_files.append(f)

    config = {
        "data_files": [f.short_path for f in data_files],
    }
    if ctx.attr.tool:
        config["tool"] = ctx.executable.tool.short_path
    if ctx.attr.command:
        config["command"] = ctx.attr.command
    ctx.actions.write(config_file, json.encode(config))

    runfiles_merge_targets = ctx.attr.data[:]
    if ctx.attr.tool:
        runfiles_merge_targets.append(ctx.attr.tool)

    runfiles = ctx.runfiles(
        files = ctx.files.data + [config_file],
        transitive_files = depset(transitive = transitive_runfiles),
    ).merge(launcher.runfiles).merge_all([
        target[DefaultInfo].default_runfiles
        for target in runfiles_merge_targets
    ])

    return [
        DefaultInfo(
            executable = launcher.executable,
            runfiles = runfiles,
        ),
    ]

js_run_devserver = rule(
    doc = _DOC,
    attrs = _attrs,
    implementation = _impl,
    toolchains = js_binary_lib.toolchains,
    executable = True,
)
