<!-- Generated with Stardoc: http://skydoc.bazel.build -->

Helper rule to gather files from JsInfo providers of targets and provide them as default outputs

<a id="js_info_files"></a>

## js_info_files

<pre>
js_info_files(<a href="#js_info_files-name">name</a>, <a href="#js_info_files-include_declarations">include_declarations</a>, <a href="#js_info_files-include_npm_sources">include_npm_sources</a>, <a href="#js_info_files-include_sources">include_sources</a>,
              <a href="#js_info_files-include_transitive_declarations">include_transitive_declarations</a>, <a href="#js_info_files-include_transitive_sources">include_transitive_sources</a>, <a href="#js_info_files-srcs">srcs</a>)
</pre>

Gathers files from the JsInfo providers from targets in srcs and provides them as default outputs.

This helper rule is used by the `js_run_binary` macro.


**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="js_info_files-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="js_info_files-include_declarations"></a>include_declarations |  When True, <code>declarations</code> from <code>JsInfo</code> providers in srcs targets are included in the default outputs of the target.<br><br>            Defaults to False since declarations are generally not needed at runtime and introducing them could slow down developer round trip             time due to having to generate typings on source file changes.   | Boolean | optional | <code>False</code> |
| <a id="js_info_files-include_npm_sources"></a>include_npm_sources |  When True, files in <code>npm_sources</code> from <code>JsInfo</code> providers in srcs targets are included in the default outputs of the target.<br><br>            <code>transitive_files</code> from <code>NpmPackageStoreInfo</code> providers in data targets are also included in the default outputs of the target.   | Boolean | optional | <code>True</code> |
| <a id="js_info_files-include_sources"></a>include_sources |  When True, <code>sources</code> from <code>JsInfo</code> providers in <code>srcs</code> targets are included in the default outputs of the target.   | Boolean | optional | <code>True</code> |
| <a id="js_info_files-include_transitive_declarations"></a>include_transitive_declarations |  When True, <code>transitive_declarations</code> from <code>JsInfo</code> providers in srcs targets are included in the default outputs of the target.<br><br>            Defaults to False since declarations are generally not needed at runtime and introducing them could slow down developer round trip             time due to having to generate typings on source file changes.   | Boolean | optional | <code>False</code> |
| <a id="js_info_files-include_transitive_sources"></a>include_transitive_sources |  When True, <code>transitive_sources</code> from <code>JsInfo</code> providers in <code>srcs</code> targets are included in the default outputs of the target.   | Boolean | optional | <code>True</code> |
| <a id="js_info_files-srcs"></a>srcs |  List of targets to gather files from.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional | <code>[]</code> |


