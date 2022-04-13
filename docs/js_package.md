<!-- Generated with Stardoc: http://skydoc.bazel.build -->

js_package rule

<a id="#js_package"></a>

## js_package

<pre>
js_package(<a href="#js_package-name">name</a>, <a href="#js_package-deps">deps</a>, <a href="#js_package-indirect">indirect</a>, <a href="#js_package-is_windows">is_windows</a>, <a href="#js_package-package_name">package_name</a>, <a href="#js_package-package_version">package_version</a>, <a href="#js_package-src">src</a>)
</pre>

Defines a nodejs package that is linked into a node_modules tree.

The term "package" is defined at
<https://nodejs.org/docs/latest-v16.x/api/packages.html>

The nodejs package is linked with a pnpm style symlinked node_modules output tree.

See https://pnpm.io/symlinked-node-modules-structure for more information on
the symlinked node_modules structure.
Npm may also support a symlinked node_modules structure called
"Isolated mode" in the future:
https://github.com/npm/rfcs/blob/main/accepted/0042-isolated-mode.md.


**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="js_package-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/docs/build-ref.html#name">Name</a> | required |  |
| <a id="js_package-deps"></a>deps |  Other nodejs packages this one depends on.<br><br>        This should include *all* modules the program may need at runtime.<br><br>        &gt; In typical usage, a node.js program sometimes requires modules which were         &gt; never declared as dependencies.         &gt; This pattern is typically used when the program has conditional behavior         &gt; that is enabled when the module is found (like a plugin) but the program         &gt; also runs without the dependency.         &gt;          &gt; This is possible because node.js doesn't enforce the dependencies are sound.         &gt; All files under <code>node_modules</code> are available to any program.         &gt; In contrast, Bazel makes it possible to make builds hermetic, which means that         &gt; all dependencies of a program must be declared when running in Bazel's sandbox.   | <a href="https://bazel.build/docs/build-ref.html#labels">List of labels</a> | optional | [] |
| <a id="js_package-indirect"></a>indirect |  If True, this is an indirect js_package which will not linked as a top-level node_module   | Boolean | optional | False |
| <a id="js_package-is_windows"></a>is_windows |  -   | Boolean | required |  |
| <a id="js_package-package_name"></a>package_name |  Must match the <code>name</code> field in the <code>package.json</code> file for this package.   | String | required |  |
| <a id="js_package-package_version"></a>package_version |  Must match the <code>version</code> field in the <code>package.json</code> file for this package.   | String | optional | "0.0.0" |
| <a id="js_package-src"></a>src |  A source directory or TreeArtifact containing the package files.<br><br>Can be left unspecified to allow for circular deps between js_packages.   | <a href="https://bazel.build/docs/build-ref.html#labels">Label</a> | optional | None |


<a id="#js_package_lib.impl"></a>

## js_package_lib.impl

<pre>
js_package_lib.impl(<a href="#js_package_lib.impl-ctx">ctx</a>)
</pre>



**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="js_package_lib.impl-ctx"></a>ctx |  <p align="center"> - </p>   |  none |


