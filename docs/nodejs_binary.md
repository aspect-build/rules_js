<!-- Generated with Stardoc: http://skydoc.bazel.build -->

nodejs_binary and nodejs_test rules

<a id="#nodejs_binary"></a>

## nodejs_binary

<pre>
nodejs_binary(<a href="#nodejs_binary-name">name</a>, <a href="#nodejs_binary-data">data</a>, <a href="#nodejs_binary-enable_runfiles">enable_runfiles</a>, <a href="#nodejs_binary-entry_point">entry_point</a>, <a href="#nodejs_binary-is_windows">is_windows</a>)
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

TODO: link to rule_js nodejs_package linker design doc

This rules requires that Bazel was run with
[`--enable_runfiles`](https://docs.bazel.build/versions/main/command-line-reference.html#flag--enable_runfiles). 


**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="nodejs_binary-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/docs/build-ref.html#name">Name</a> | required |  |
| <a id="nodejs_binary-data"></a>data |  Runtime dependencies of the program.<br><br>        The transitive closure of the <code>data</code> dependencies will be available in         the .runfiles folder for this binary/test.<br><br>        You can use the <code>@bazel/runfiles</code> npm library to access these files         at runtime.<br><br>        npm packages are also linked into the <code>.runfiles/node_modules</code> folder         so they may be resolved directly from runfiles.   | <a href="https://bazel.build/docs/build-ref.html#labels">List of labels</a> | optional | [] |
| <a id="nodejs_binary-enable_runfiles"></a>enable_runfiles |  Whether runfiles are enabled in the current build configuration.<br><br>        Typical usage of this rule is via a macro which automatically sets this         attribute based on a <code>config_setting</code> rule.   | Boolean | required |  |
| <a id="nodejs_binary-entry_point"></a>entry_point |  The main script which is evaluated by node.js<br><br>        This is the module referenced by the <code>require.main</code> property in the runtime.   | <a href="https://bazel.build/docs/build-ref.html#labels">Label</a> | required |  |
| <a id="nodejs_binary-is_windows"></a>is_windows |  Whether the build is being performed on a Windows host platform.<br><br>        Typical usage of this rule is via a macro which automatically sets this         attribute based on a <code>select()</code> on <code>@bazel_tools//src/conditions:host_windows</code>.   | Boolean | required |  |


<a id="#nodejs_binary_lib.nodejs_binary_impl"></a>

## nodejs_binary_lib.nodejs_binary_impl

<pre>
nodejs_binary_lib.nodejs_binary_impl(<a href="#nodejs_binary_lib.nodejs_binary_impl-ctx">ctx</a>)
</pre>



**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="nodejs_binary_lib.nodejs_binary_impl-ctx"></a>ctx |  <p align="center"> - </p>   |  none |


