<!-- Generated with Stardoc: http://skydoc.bazel.build -->

contains container helper functions for js_binary

<a id="runfiles"></a>

## runfiles

<pre>
runfiles(<a href="#runfiles-name">name</a>, <a href="#runfiles-binary">binary</a>, <a href="#runfiles-exclude">exclude</a>, <a href="#runfiles-include">include</a>, <a href="#runfiles-root">root</a>)
</pre>



**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="runfiles-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="runfiles-binary"></a>binary |  -   | <a href="https://bazel.build/concepts/labels">Label</a> | required |  |
| <a id="runfiles-exclude"></a>exclude |  -   | String | optional | <code>""</code> |
| <a id="runfiles-include"></a>include |  -   | String | optional | <code>""</code> |
| <a id="runfiles-root"></a>root |  -   | String | optional | <code>""</code> |


<a id="js_image_layer"></a>

## js_image_layer

<pre>
js_image_layer(<a href="#js_image_layer-name">name</a>, <a href="#js_image_layer-binary">binary</a>, <a href="#js_image_layer-root">root</a>, <a href="#js_image_layer-kwargs">kwargs</a>)
</pre>

Creates two tar files `:&lt;name&gt;/app.tar` and `:&lt;name&gt;/node_modules.tar`

Final directory tree will look like below

/{root of js_image_layer}/{package_name() if any}/{name of js_binary}.sh -&gt; entrypoint
/{root of js_image_layer}/{package_name() if any}/{name of js_binary}.sh.runfiles -&gt; runfiles directory (almost identical to one bazel lays out)


**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="js_image_layer-name"></a>name |  name for this target. Not reflected anywhere in the final tar.   |  none |
| <a id="js_image_layer-binary"></a>binary |  label to js_image target   |  none |
| <a id="js_image_layer-root"></a>root |  Path where the js_binary will reside inside the final container image.   |  <code>None</code> |
| <a id="js_image_layer-kwargs"></a>kwargs |  Passed to pkg_tar. See: https://github.com/bazelbuild/rules_pkg/blob/main/docs/0.7.0/reference.md#pkg_tar   |  none |


