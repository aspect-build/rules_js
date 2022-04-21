<!-- Generated with Stardoc: http://skydoc.bazel.build -->

node_package rule

<a id="#node_package"></a>

## node_package

<pre>
node_package(<a href="#node_package-name">name</a>, <a href="#node_package-deps">deps</a>, <a href="#node_package-indirect">indirect</a>, <a href="#node_package-is_windows">is_windows</a>, <a href="#node_package-package">package</a>, <a href="#node_package-src">src</a>, <a href="#node_package-version">version</a>)
</pre>



**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="node_package-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/docs/build-ref.html#name">Name</a> | required |  |
| <a id="node_package-deps"></a>deps |  Other node packages this one depends on.<br><br>        This should include *all* modules the program may need at runtime.<br><br>        &gt; In typical usage, a node.js program sometimes requires modules which were         &gt; never declared as dependencies.         &gt; This pattern is typically used when the program has conditional behavior         &gt; that is enabled when the module is found (like a plugin) but the program         &gt; also runs without the dependency.         &gt;          &gt; This is possible because node.js doesn't enforce the dependencies are sound.         &gt; All files under <code>node_modules</code> are available to any program.         &gt; In contrast, Bazel makes it possible to make builds hermetic, which means that         &gt; all dependencies of a program must be declared when running in Bazel's sandbox.   | <a href="https://bazel.build/docs/build-ref.html#labels">List of labels</a> | optional | [] |
| <a id="node_package-indirect"></a>indirect |  If True, this is an indirect node_package which will not linked at the top-level of node_modules   | Boolean | optional | False |
| <a id="node_package-is_windows"></a>is_windows |  -   | Boolean | required |  |
| <a id="node_package-package"></a>package |  Must match the <code>name</code> field in the <code>package.json</code> file for this package.   | String | required |  |
| <a id="node_package-src"></a>src |  A source directory or TreeArtifact containing the package files.<br><br>Can be left unspecified to allow for circular deps between <code>node_package</code>s.   | <a href="https://bazel.build/docs/build-ref.html#labels">Label</a> | optional | None |
| <a id="node_package-version"></a>version |  Must match the <code>version</code> field in the <code>package.json</code> file for this package.   | String | optional | "0.0.0" |


<a id="#node_package_lib.impl"></a>

## node_package_lib.impl

<pre>
node_package_lib.impl(<a href="#node_package_lib.impl-ctx">ctx</a>)
</pre>



**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="node_package_lib.impl-ctx"></a>ctx |  <p align="center"> - </p>   |  none |


