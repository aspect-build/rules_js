<!-- Generated with Stardoc: http://skydoc.bazel.build -->

nodejs_binary and nodejs_test rules

<a id="#nodejs_binary"></a>

## nodejs_binary

<pre>
nodejs_binary(<a href="#nodejs_binary-name">name</a>, <a href="#nodejs_binary-data">data</a>, <a href="#nodejs_binary-enable_runfiles">enable_runfiles</a>, <a href="#nodejs_binary-entry_point">entry_point</a>, <a href="#nodejs_binary-is_windows">is_windows</a>)
</pre>



**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="nodejs_binary-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/docs/build-ref.html#name">Name</a> | required |  |
| <a id="nodejs_binary-data"></a>data |  Runtime dependencies of the program.<br><br>            The transitive closure of the <code>data</code> dependencies will be available in             the .runfiles folder for this binary/test.<br><br>            You can use the <code>@bazel/runfiles</code> npm library to access these files             at runtime.<br><br>            npm packages are also linked into the <code>.runfiles/node_modules</code> folder             so they may be resolved directly from runfiles.   | <a href="https://bazel.build/docs/build-ref.html#labels">List of labels</a> | optional | [] |
| <a id="nodejs_binary-enable_runfiles"></a>enable_runfiles |  Whether runfiles are enabled in the current build configuration.<br><br>            Typical usage of this rule is via a macro which automatically sets this             attribute based on a config_setting rule.   | Boolean | required |  |
| <a id="nodejs_binary-entry_point"></a>entry_point |  The main script which is evaluated by node.js<br><br>            This is the module referenced by the <code>require.main</code> property in the runtime.   | <a href="https://bazel.build/docs/build-ref.html#labels">Label</a> | optional | None |
| <a id="nodejs_binary-is_windows"></a>is_windows |  Whether the build is being performed on a Windows host platform.<br><br>            Typical usage of this rule is via a macro which automatically sets this             attribute based on a select() on @bazel_tools//src/conditions:host_windows   | Boolean | required |  |


<a id="#nodejs_binary_lib.nodejs_binary_impl"></a>

## nodejs_binary_lib.nodejs_binary_impl

<pre>
nodejs_binary_lib.nodejs_binary_impl(<a href="#nodejs_binary_lib.nodejs_binary_impl-ctx">ctx</a>)
</pre>



**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="nodejs_binary_lib.nodejs_binary_impl-ctx"></a>ctx |  <p align="center"> - </p>   |  none |


