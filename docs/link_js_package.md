<!-- Generated with Stardoc: http://skydoc.bazel.build -->

link_js_package rule

<a id="#link_js_package"></a>

## link_js_package

<pre>
link_js_package(<a href="#link_js_package-name">name</a>, <a href="#link_js_package-deps">deps</a>, <a href="#link_js_package-indirect">indirect</a>, <a href="#link_js_package-src">src</a>)
</pre>

Defines a node package that is linked into a node_modules tree.

The term "package" is defined at
<https://nodejs.org/docs/latest-v16.x/api/packages.html>

The node package is linked with a pnpm style symlinked node_modules output tree.

See https://pnpm.io/symlinked-node-modules-structure for more information on
the symlinked node_modules structure.
Npm may also support a symlinked node_modules structure called
"Isolated mode" in the future:
https://github.com/npm/rfcs/blob/main/accepted/0042-isolated-mode.md.


**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="link_js_package-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/docs/build-ref.html#name">Name</a> | required |  |
| <a id="link_js_package-deps"></a>deps |  Other node packages this one depends on.<br><br>        This should include *all* modules the program may need at runtime.<br><br>        &gt; In typical usage, a node.js program sometimes requires modules which were         &gt; never declared as dependencies.         &gt; This pattern is typically used when the program has conditional behavior         &gt; that is enabled when the module is found (like a plugin) but the program         &gt; also runs without the dependency.         &gt;          &gt; This is possible because node.js doesn't enforce the dependencies are sound.         &gt; All files under <code>node_modules</code> are available to any program.         &gt; In contrast, Bazel makes it possible to make builds hermetic, which means that         &gt; all dependencies of a program must be declared when running in Bazel's sandbox.   | <a href="https://bazel.build/docs/build-ref.html#labels">List of labels</a> | optional | [] |
| <a id="link_js_package-indirect"></a>indirect |  If True, this is an indirect link_js_package which will not linked at the top-level of node_modules   | Boolean | optional | False |
| <a id="link_js_package-src"></a>src |  A js_package target or or any other target that provides a JsPackageInfo.   | <a href="https://bazel.build/docs/build-ref.html#labels">Label</a> | required |  |


<a id="#link_js_package_lib.implementation"></a>

## link_js_package_lib.implementation

<pre>
link_js_package_lib.implementation(<a href="#link_js_package_lib.implementation-ctx">ctx</a>)
</pre>



**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="link_js_package_lib.implementation-ctx"></a>ctx |  <p align="center"> - </p>   |  none |


