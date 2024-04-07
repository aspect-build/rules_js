<!-- Generated with Stardoc: http://skydoc.bazel.build -->

Helper rule to gather files from JsInfo providers of targets and provide them as default outputs

<a id="js_info_files"></a>

## js_info_files

<pre>
js_info_files(<a href="#js_info_files-name">name</a>, <a href="#js_info_files-srcs">srcs</a>, <a href="#js_info_files-include_declarations">include_declarations</a>, <a href="#js_info_files-include_npm_linked_packages">include_npm_linked_packages</a>, <a href="#js_info_files-include_sources">include_sources</a>,
              <a href="#js_info_files-include_transitive_declarations">include_transitive_declarations</a>, <a href="#js_info_files-include_transitive_sources">include_transitive_sources</a>)
</pre>

Gathers files from the JsInfo providers from targets in srcs and provides them as default outputs.

This helper rule is used by the `js_run_binary` macro.

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="js_info_files-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="js_info_files-srcs"></a>srcs |  List of targets to gather files from.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="js_info_files-include_declarations"></a>include_declarations |  When True, `declarations` from `JsInfo` providers in srcs targets are included in the default outputs of the target.<br><br>Defaults to False since declarations are generally not needed at runtime and introducing them could slow down developer round trip time due to having to generate typings on source file changes.   | Boolean | optional |  `False`  |
| <a id="js_info_files-include_npm_linked_packages"></a>include_npm_linked_packages |  When True, files in `npm_linked_packages` from `JsInfo` providers in srcs targets are included in the default outputs of the target.<br><br>`transitive_files` from `NpmPackageStoreInfo` providers in data targets are also included in the default outputs of the target.   | Boolean | optional |  `True`  |
| <a id="js_info_files-include_sources"></a>include_sources |  When True, `sources` from `JsInfo` providers in `srcs` targets are included in the default outputs of the target.   | Boolean | optional |  `True`  |
| <a id="js_info_files-include_transitive_declarations"></a>include_transitive_declarations |  When True, `transitive_declarations` from `JsInfo` providers in srcs targets are included in the default outputs of the target.<br><br>Defaults to False since declarations are generally not needed at runtime and introducing them could slow down developer round trip time due to having to generate typings on source file changes.   | Boolean | optional |  `False`  |
| <a id="js_info_files-include_transitive_sources"></a>include_transitive_sources |  When True, `transitive_sources` from `JsInfo` providers in `srcs` targets are included in the default outputs of the target.   | Boolean | optional |  `True`  |


