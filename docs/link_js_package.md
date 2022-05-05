<!-- Generated with Stardoc: http://skydoc.bazel.build -->

link_js_package rule

<a id="#link_js_package_direct"></a>

## link_js_package_direct

<pre>
link_js_package_direct(<a href="#link_js_package_direct-name">name</a>, <a href="#link_js_package_direct-src">src</a>)
</pre>

Defines a node package that is linked into a node_modules tree as a direct dependency.

This is used in co-ordination with link_js_package that links into the virtual store in
with a pnpm style symlinked node_modules output tree.

The term "package" is defined at
<https://nodejs.org/docs/latest-v16.x/api/packages.html>

See https://pnpm.io/symlinked-node-modules-structure for more information on
the symlinked node_modules structure.
Npm may also support a symlinked node_modules structure called
"Isolated mode" in the future:
https://github.com/npm/rfcs/blob/main/accepted/0042-isolated-mode.md.


**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="link_js_package_direct-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/docs/build-ref.html#name">Name</a> | required |  |
| <a id="link_js_package_direct-src"></a>src |  The link_js_package target to link as a direct dependency.   | <a href="https://bazel.build/docs/build-ref.html#labels">Label</a> | required |  |


<a id="#link_js_package_store"></a>

## link_js_package_store

<pre>
link_js_package_store(<a href="#link_js_package_store-name">name</a>, <a href="#link_js_package_store-deps">deps</a>, <a href="#link_js_package_store-package">package</a>, <a href="#link_js_package_store-src">src</a>, <a href="#link_js_package_store-version">version</a>)
</pre>

Defines a node package that is linked into a node_modules tree.

The node package is linked with a pnpm style symlinked node_modules output tree.

The term "package" is defined at
<https://nodejs.org/docs/latest-v16.x/api/packages.html>

See https://pnpm.io/symlinked-node-modules-structure for more information on
the symlinked node_modules structure.
Npm may also support a symlinked node_modules structure called
"Isolated mode" in the future:
https://github.com/npm/rfcs/blob/main/accepted/0042-isolated-mode.md.


**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="link_js_package_store-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/docs/build-ref.html#name">Name</a> | required |  |
| <a id="link_js_package_store-deps"></a>deps |  Other node packages this one depends on.<br><br>        This should include *all* modules the program may need at runtime.<br><br>        &gt; In typical usage, a node.js program sometimes requires modules which were         &gt; never declared as dependencies.         &gt; This pattern is typically used when the program has conditional behavior         &gt; that is enabled when the module is found (like a plugin) but the program         &gt; also runs without the dependency.         &gt;          &gt; This is possible because node.js doesn't enforce the dependencies are sound.         &gt; All files under <code>node_modules</code> are available to any program.         &gt; In contrast, Bazel makes it possible to make builds hermetic, which means that         &gt; all dependencies of a program must be declared when running in Bazel's sandbox.   | <a href="https://bazel.build/docs/build-ref.html#labels">List of labels</a> | optional | [] |
| <a id="link_js_package_store-package"></a>package |  The package name to link to.<br><br>If unset, the package name in the JsPackageInfo src must be set. If set, takes precendance over the package name in the JsPackageInfo src.   | String | optional | "" |
| <a id="link_js_package_store-src"></a>src |  A js_package target or or any other target that provides a JsPackageInfo.   | <a href="https://bazel.build/docs/build-ref.html#labels">Label</a> | required |  |
| <a id="link_js_package_store-version"></a>version |  The package version being linked.<br><br>If unset, the package name in the JsPackageInfo src must be set. If set, takes precendance over the package name in the JsPackageInfo src.   | String | optional | "" |


<a id="#link_js_package_direct_lib.implementation"></a>

## link_js_package_direct_lib.implementation

<pre>
link_js_package_direct_lib.implementation(<a href="#link_js_package_direct_lib.implementation-ctx">ctx</a>)
</pre>



**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="link_js_package_direct_lib.implementation-ctx"></a>ctx |  <p align="center"> - </p>   |  none |


<a id="#link_js_package_store_lib.implementation"></a>

## link_js_package_store_lib.implementation

<pre>
link_js_package_store_lib.implementation(<a href="#link_js_package_store_lib.implementation-ctx">ctx</a>)
</pre>



**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="link_js_package_store_lib.implementation-ctx"></a>ctx |  <p align="center"> - </p>   |  none |


