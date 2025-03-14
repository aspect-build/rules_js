<!-- Generated with Stardoc: http://skydoc.bazel.build -->

Implementation details for js_run_devserver rule

<a id="js_run_devserver"></a>

## js_run_devserver

<pre>
js_run_devserver(<a href="#js_run_devserver-name">name</a>, <a href="#js_run_devserver-tool">tool</a>, <a href="#js_run_devserver-command">command</a>, <a href="#js_run_devserver-grant_sandbox_write_permissions">grant_sandbox_write_permissions</a>, <a href="#js_run_devserver-use_execroot_entry_point">use_execroot_entry_point</a>,
                 <a href="#js_run_devserver-allow_execroot_entry_point_with_no_copy_data_to_bin">allow_execroot_entry_point_with_no_copy_data_to_bin</a>, <a href="#js_run_devserver-kwargs">kwargs</a>)
</pre>

Runs a devserver via binary target or command.

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

As an optimization, package store files are explicitly excluded from the sandbox since the npm
links will point to the package store in the execroot and Node.js will follow those links as it
does within the execroot. As a result, rules_js npm package link targets such as
`//:node_modules/next` are handled efficiently. Since these targets are symlinks in the output
tree, they are recreated as symlinks in the custom sandbox and do not incur a full copy of the
underlying npm packages.

Supports running with [ibazel](https://github.com/bazelbuild/bazel-watcher).
Only `data` files that change on incremental builds are synchronized when running with ibazel.

Note that the use of `alias` targets is not supported by ibazel: https://github.com/bazelbuild/bazel-watcher/issues/100


**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="js_run_devserver-name"></a>name |  A unique name for this target.   |  none |
| <a id="js_run_devserver-tool"></a>tool |  The devserver binary target to run.<br><br>Only one of `command` or `tool` may be specified.   |  `None` |
| <a id="js_run_devserver-command"></a>command |  The devserver command to run.<br><br>For example, this could be the bin entry of an npm package that is included in data such as `./node_modules/.bin/next`.<br><br>Using the bin entry of next, for example, resolves issues with Next.js and React being found in multiple node_modules trees when next is run as an encapsulated `js_binary` tool.<br><br>Only one of `command` or `tool` may be specified.   |  `None` |
| <a id="js_run_devserver-grant_sandbox_write_permissions"></a>grant_sandbox_write_permissions |  If set, write permissions is set on all files copied to the custom sandbox.<br><br>This can be useful to support some devservers such as Next.js which may, under some circumstances, try to modify files when running.<br><br>See https://github.com/aspect-build/rules_js/issues/935 for more context.   |  `False` |
| <a id="js_run_devserver-use_execroot_entry_point"></a>use_execroot_entry_point |  Use the `entry_point` script of the `js_binary` `tool` that is in the execroot output tree instead of the copy that is in runfiles.<br><br>Using the entry point script that is in the execroot output tree means that there will be no conflicting runfiles `node_modules` in the node_modules resolution path which can confuse npm packages such as next and react that don't like being resolved in multiple node_modules trees. This more closely emulates the environment that tools such as Next.js see when they are run outside of Bazel.<br><br>When True, the `js_binary` tool must have `copy_data_to_bin` set to True (the default) so that all data files needed by the binary are available in the execroot output tree. This requirement can be turned off with by setting `allow_execroot_entry_point_with_no_copy_data_to_bin` to True.   |  `True` |
| <a id="js_run_devserver-allow_execroot_entry_point_with_no_copy_data_to_bin"></a>allow_execroot_entry_point_with_no_copy_data_to_bin |  Turn off validation that the `js_binary` tool has `copy_data_to_bin` set to True when `use_execroot_entry_point` is set to True.<br><br>See `use_execroot_entry_point` doc for more info.   |  `False` |
| <a id="js_run_devserver-kwargs"></a>kwargs |  All other args from `js_binary` except for `entry_point` which is set implicitly.<br><br>`entry_point` is set implicitly by `js_run_devserver` and cannot be overridden.<br><br>See https://docs.aspect.build/rules/aspect_rules_js/docs/js_binary   |  none |


