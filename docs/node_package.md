<!-- Generated with Stardoc: http://skydoc.bazel.build -->

node_package rule

<a id="#node_package"></a>

## node_package

<pre>
node_package(<a href="#node_package-name">name</a>, <a href="#node_package-deps">deps</a>, <a href="#node_package-is_windows">is_windows</a>, <a href="#node_package-package_name">package_name</a>, <a href="#node_package-remap_paths">remap_paths</a>, <a href="#node_package-src">src</a>, <a href="#node_package-srcs">srcs</a>)
</pre>

Defines a library that executes in a node.js runtime.
    
The term "package" is defined at
<https://nodejs.org/docs/latest-v16.x/api/packages.html>

To be compatible with Bazel's remote execution protocol,
all source files are copied to an an output directory,
which is 

NB: This rule is not yet tested on Windows


**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="node_package-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/docs/build-ref.html#name">Name</a> | required |  |
| <a id="node_package-deps"></a>deps |  Other packages this one depends on.<br><br>        This should include *all* modules the program may need at runtime.<br><br>        &gt; In typical usage, a node.js program sometimes requires modules which were         &gt; never declared as dependencies.         &gt; This pattern is typically used when the program has conditional behavior         &gt; that is enabled when the module is found (like a plugin) but the program         &gt; also runs without the dependency.         &gt;          &gt; This is possible because node.js doesn't enforce the dependencies are sound.         &gt; All files under <code>node_modules</code> are available to any program.         &gt; In contrast, Bazel makes it possible to make builds hermetic, which means that         &gt; all dependencies of a program must be declared when running in Bazel's sandbox.   | <a href="https://bazel.build/docs/build-ref.html#labels">List of labels</a> | optional | [] |
| <a id="node_package-is_windows"></a>is_windows |  -   | Boolean | required |  |
| <a id="node_package-package_name"></a>package_name |  Must match the <code>name</code> field in the <code>package.json</code> file for this package.   | String | required |  |
| <a id="node_package-remap_paths"></a>remap_paths |  -   | <a href="https://bazel.build/docs/skylark/lib/dict.html">Dictionary: String -> String</a> | optional | {} |
| <a id="node_package-src"></a>src |  A TreeArtifact containing the npm package files.<br><br>        Exactly one of <code>src</code> or <code>srcs</code> should be set.   | <a href="https://bazel.build/docs/build-ref.html#labels">Label</a> | optional | None |
| <a id="node_package-srcs"></a>srcs |  Files to copy into the package directory.<br><br>        Exactly one of <code>src</code> or <code>srcs</code> should be set.   | <a href="https://bazel.build/docs/build-ref.html#labels">List of labels</a> | optional | [] |


<a id="#node_package_lib.node_package_impl"></a>

## node_package_lib.node_package_impl

<pre>
node_package_lib.node_package_impl(<a href="#node_package_lib.node_package_impl-ctx">ctx</a>)
</pre>



**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="node_package_lib.node_package_impl-ctx"></a>ctx |  <p align="center"> - </p>   |  none |


