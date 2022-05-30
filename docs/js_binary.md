<!-- Generated with Stardoc: http://skydoc.bazel.build -->

Rules for running JavaScript programs under Bazel, as tools or with `bazel run` or `bazel test`.

Load these with

```starlark
load("@aspect_rules_js//js:defs.bzl", "js_binary", "js_test")
```


<a id="#js_binary"></a>

## js_binary

<pre>
js_binary(<a href="#js_binary-name">name</a>, <a href="#js_binary-chdir">chdir</a>, <a href="#js_binary-data">data</a>, <a href="#js_binary-enable_runfiles">enable_runfiles</a>, <a href="#js_binary-entry_point">entry_point</a>, <a href="#js_binary-env">env</a>, <a href="#js_binary-expected_exit_code">expected_exit_code</a>, <a href="#js_binary-log_level">log_level</a>,
          <a href="#js_binary-node_options">node_options</a>)
</pre>

Execute a program in the node.js runtime.

The version of node is determined by Bazel's toolchain selection. In the WORKSPACE you used
`nodejs_register_toolchains` to provide options to Bazel. Then Bazel selects from these options
based on the requested target platform. Use the
[`--toolchain_resolution_debug`](https://docs.bazel.build/versions/main/command-line-reference.html#flag--toolchain_resolution_debug)
Bazel option to see more detail about the selection.

For node_modules resolution support and to prevent node programs for following symlinks back to the
user source tree when outside of the sandbox, this rule always copies the entry_point to the output
tree (if it is not already there) and run the programs from the entry points's runfiles location.

Data files that are not already in the output tree are also copied there so that node programs can
find them when outside of the sandbox and so that they don't follow symlinks back to the user source
tree.

TODO: link to rules_js linker design doc

This rules requires that Bazel was run with
[`--enable_runfiles`](https://docs.bazel.build/versions/main/command-line-reference.html#flag--enable_runfiles). 


**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="js_binary-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/docs/build-ref.html#name">Name</a> | required |  |
| <a id="js_binary-chdir"></a>chdir |  Working directory to run the binary or test in, relative to the workspace.<br><br>        By default, <code>js_binary</code> runs in the root of the output tree.<br><br>        To run in the directory containing the <code>js_binary</code> use<br><br>            chdir = package_name()<br><br>        (or if you're in a macro, use <code>native.package_name()</code>)<br><br>        WARNING: this will affect other paths passed to the program, either as arguments or in configuration files,         which are workspace-relative.<br><br>        You may need <code>../../</code> segments to re-relativize such paths to the new working directory.         In a <code>BUILD</code> file you could do something like this to point to the output path:<br><br>        <pre><code>python         js_binary(             ...             chdir = package_name(),             # ../.. segments to re-relative paths from the chdir back to workspace;             # add an additional 3 segments to account for running js_binary running             # in the root of the output tree             args = ["/".join([".."] * len(package_name().split("/")) + "$(rootpath //path/to/some:file)"],         )         </code></pre>   | String | optional | "" |
| <a id="js_binary-data"></a>data |  Runtime dependencies of the program.<br><br>        The transitive closure of the <code>data</code> dependencies will be available in         the .runfiles folder for this binary/test.<br><br>        You can use the <code>@bazel/runfiles</code> npm library to access these files         at runtime.<br><br>        npm packages are also linked into the <code>.runfiles/node_modules</code> folder         so they may be resolved directly from runfiles.   | <a href="https://bazel.build/docs/build-ref.html#labels">List of labels</a> | optional | [] |
| <a id="js_binary-enable_runfiles"></a>enable_runfiles |  Whether runfiles are enabled in the current build configuration.<br><br>        Typical usage of this rule is via a macro which automatically sets this         attribute based on a <code>config_setting</code> rule.   | Boolean | required |  |
| <a id="js_binary-entry_point"></a>entry_point |  The main script which is evaluated by node.js.<br><br>        This is the module referenced by the <code>require.main</code> property in the runtime.<br><br>        This must be a target that provides a single file or a <code>DirectoryPathInfo</code>         from <code>@aspect_bazel_lib//lib::directory_path.bzl</code>.<br><br>        See https://github.com/aspect-build/bazel-lib/blob/main/docs/directory_path.md         for more info on creating a target that provides a <code>DirectoryPathInfo</code>.   | <a href="https://bazel.build/docs/build-ref.html#labels">Label</a> | required |  |
| <a id="js_binary-env"></a>env |  Environment variables of the action.<br><br>        Subject to <code>$(location)</code> and make variable expansion.   | <a href="https://bazel.build/docs/skylark/lib/dict.html">Dictionary: String -> String</a> | optional | {} |
| <a id="js_binary-expected_exit_code"></a>expected_exit_code |  The expected exit code.<br><br>        Can be used to write tests that are expected to fail.   | Integer | optional | 0 |
| <a id="js_binary-log_level"></a>log_level |  Set the logging level.<br><br>        Log from are written to stderr. They will be supressed on success when running as the tool         of a run_js_binary when silent_on_success is True. In that case, they will be shown         only on a build failure along with the stdout & stderr of the node tool being run.   | String | optional | "error" |
| <a id="js_binary-node_options"></a>node_options |  Options to pass to the node.<br><br>        https://nodejs.org/api/cli.html   | List of strings | optional | [] |


<a id="#js_test"></a>

## js_test

<pre>
js_test(<a href="#js_test-name">name</a>, <a href="#js_test-chdir">chdir</a>, <a href="#js_test-data">data</a>, <a href="#js_test-enable_runfiles">enable_runfiles</a>, <a href="#js_test-entry_point">entry_point</a>, <a href="#js_test-env">env</a>, <a href="#js_test-expected_exit_code">expected_exit_code</a>, <a href="#js_test-log_level">log_level</a>,
        <a href="#js_test-node_options">node_options</a>)
</pre>

Identical to js_binary, but usable under `bazel test`.

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="js_test-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/docs/build-ref.html#name">Name</a> | required |  |
| <a id="js_test-chdir"></a>chdir |  Working directory to run the binary or test in, relative to the workspace.<br><br>        By default, <code>js_binary</code> runs in the root of the output tree.<br><br>        To run in the directory containing the <code>js_binary</code> use<br><br>            chdir = package_name()<br><br>        (or if you're in a macro, use <code>native.package_name()</code>)<br><br>        WARNING: this will affect other paths passed to the program, either as arguments or in configuration files,         which are workspace-relative.<br><br>        You may need <code>../../</code> segments to re-relativize such paths to the new working directory.         In a <code>BUILD</code> file you could do something like this to point to the output path:<br><br>        <pre><code>python         js_binary(             ...             chdir = package_name(),             # ../.. segments to re-relative paths from the chdir back to workspace;             # add an additional 3 segments to account for running js_binary running             # in the root of the output tree             args = ["/".join([".."] * len(package_name().split("/")) + "$(rootpath //path/to/some:file)"],         )         </code></pre>   | String | optional | "" |
| <a id="js_test-data"></a>data |  Runtime dependencies of the program.<br><br>        The transitive closure of the <code>data</code> dependencies will be available in         the .runfiles folder for this binary/test.<br><br>        You can use the <code>@bazel/runfiles</code> npm library to access these files         at runtime.<br><br>        npm packages are also linked into the <code>.runfiles/node_modules</code> folder         so they may be resolved directly from runfiles.   | <a href="https://bazel.build/docs/build-ref.html#labels">List of labels</a> | optional | [] |
| <a id="js_test-enable_runfiles"></a>enable_runfiles |  Whether runfiles are enabled in the current build configuration.<br><br>        Typical usage of this rule is via a macro which automatically sets this         attribute based on a <code>config_setting</code> rule.   | Boolean | required |  |
| <a id="js_test-entry_point"></a>entry_point |  The main script which is evaluated by node.js.<br><br>        This is the module referenced by the <code>require.main</code> property in the runtime.<br><br>        This must be a target that provides a single file or a <code>DirectoryPathInfo</code>         from <code>@aspect_bazel_lib//lib::directory_path.bzl</code>.<br><br>        See https://github.com/aspect-build/bazel-lib/blob/main/docs/directory_path.md         for more info on creating a target that provides a <code>DirectoryPathInfo</code>.   | <a href="https://bazel.build/docs/build-ref.html#labels">Label</a> | required |  |
| <a id="js_test-env"></a>env |  Environment variables of the action.<br><br>        Subject to <code>$(location)</code> and make variable expansion.   | <a href="https://bazel.build/docs/skylark/lib/dict.html">Dictionary: String -> String</a> | optional | {} |
| <a id="js_test-expected_exit_code"></a>expected_exit_code |  The expected exit code.<br><br>        Can be used to write tests that are expected to fail.   | Integer | optional | 0 |
| <a id="js_test-log_level"></a>log_level |  Set the logging level.<br><br>        Log from are written to stderr. They will be supressed on success when running as the tool         of a run_js_binary when silent_on_success is True. In that case, they will be shown         only on a build failure along with the stdout & stderr of the node tool being run.   | String | optional | "error" |
| <a id="js_test-node_options"></a>node_options |  Options to pass to the node.<br><br>        https://nodejs.org/api/cli.html   | List of strings | optional | [] |


<a id="#envs_for_log_level"></a>

## envs_for_log_level

<pre>
envs_for_log_level(<a href="#envs_for_log_level-log_level">log_level</a>)
</pre>

Returns a list environment variables to set for a given log level

**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="envs_for_log_level-log_level"></a>log_level |  The log level string value   |  none |

**RETURNS**

A list of environment variables to set to turn on the js_binary runtime
  logs for the given log level. Typically, they are each set to "1".


<a id="#js_binary_lib.create_launcher"></a>

## js_binary_lib.create_launcher

<pre>
js_binary_lib.create_launcher(<a href="#js_binary_lib.create_launcher-ctx">ctx</a>, <a href="#js_binary_lib.create_launcher-log_prefix_rule_set">log_prefix_rule_set</a>, <a href="#js_binary_lib.create_launcher-log_prefix_rule">log_prefix_rule</a>, <a href="#js_binary_lib.create_launcher-fixed_args">fixed_args</a>)
</pre>



**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="js_binary_lib.create_launcher-ctx"></a>ctx |  <p align="center"> - </p>   |  none |
| <a id="js_binary_lib.create_launcher-log_prefix_rule_set"></a>log_prefix_rule_set |  <p align="center"> - </p>   |  none |
| <a id="js_binary_lib.create_launcher-log_prefix_rule"></a>log_prefix_rule |  <p align="center"> - </p>   |  none |
| <a id="js_binary_lib.create_launcher-fixed_args"></a>fixed_args |  <p align="center"> - </p>   |  <code>[]</code> |


<a id="#js_binary_lib.implementation"></a>

## js_binary_lib.implementation

<pre>
js_binary_lib.implementation(<a href="#js_binary_lib.implementation-ctx">ctx</a>)
</pre>



**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="js_binary_lib.implementation-ctx"></a>ctx |  <p align="center"> - </p>   |  none |


