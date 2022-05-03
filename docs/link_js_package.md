<!-- Generated with Stardoc: http://skydoc.bazel.build -->

link_js_package rule

<a id="#link_js_package"></a>

## link_js_package

<pre>
link_js_package(<a href="#link_js_package-name">name</a>, <a href="#link_js_package-always_output_bins">always_output_bins</a>, <a href="#link_js_package-bins">bins</a>, <a href="#link_js_package-deps">deps</a>, <a href="#link_js_package-indirect">indirect</a>, <a href="#link_js_package-package">package</a>, <a href="#link_js_package-root_dir">root_dir</a>, <a href="#link_js_package-src">src</a>, <a href="#link_js_package-version">version</a>)
</pre>



**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="link_js_package-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/docs/build-ref.html#name">Name</a> | required |  |
| <a id="link_js_package-always_output_bins"></a>always_output_bins |  If True, always output bins entry points. If False, bin entry points         are only outputted when src is set.   | Boolean | optional | False |
| <a id="link_js_package-bins"></a>bins |  A dict of bin entry point names to entry point paths for this package.<br><br>        This should mirror what is in the <code>bin</code> field of the package.json of the package.         See https://docs.npmjs.com/cli/v7/configuring-npm/package-json#bin.   | <a href="https://bazel.build/docs/skylark/lib/dict.html">Dictionary: String -> String</a> | optional | {} |
| <a id="link_js_package-deps"></a>deps |  Other node packages this one depends on.<br><br>        This should include *all* modules the program may need at runtime.<br><br>        &gt; In typical usage, a node.js program sometimes requires modules which were         &gt; never declared as dependencies.         &gt; This pattern is typically used when the program has conditional behavior         &gt; that is enabled when the module is found (like a plugin) but the program         &gt; also runs without the dependency.         &gt;          &gt; This is possible because node.js doesn't enforce the dependencies are sound.         &gt; All files under <code>node_modules</code> are available to any program.         &gt; In contrast, Bazel makes it possible to make builds hermetic, which means that         &gt; all dependencies of a program must be declared when running in Bazel's sandbox.   | <a href="https://bazel.build/docs/build-ref.html#labels">List of labels</a> | optional | [] |
| <a id="link_js_package-indirect"></a>indirect |  If True, this is an indirect link_js_package which will not linked at the top-level of node_modules   | Boolean | optional | False |
| <a id="link_js_package-package"></a>package |  Must match the <code>name</code> field in the <code>package.json</code> file for this package.   | String | required |  |
| <a id="link_js_package-root_dir"></a>root_dir |  For internal use only   | String | optional | "node_modules" |
| <a id="link_js_package-src"></a>src |  A source directory or TreeArtifact containing the package files.<br><br>Can be left unspecified to allow for circular deps between <code>link_js_package</code>s.   | <a href="https://bazel.build/docs/build-ref.html#labels">Label</a> | optional | None |
| <a id="link_js_package-version"></a>version |  Must match the <code>version</code> field in the <code>package.json</code> file for this package.   | String | optional | "0.0.0" |


<a id="#link_js_package_lib.impl"></a>

## link_js_package_lib.impl

<pre>
link_js_package_lib.impl(<a href="#link_js_package_lib.impl-ctx">ctx</a>)
</pre>



**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="link_js_package_lib.impl-ctx"></a>ctx |  <p align="center"> - </p>   |  none |


