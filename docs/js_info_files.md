<!-- Generated with Stardoc: http://skydoc.bazel.build -->

Helper rule to gather files from JsInfo providers of targets and provide them as default outputs

<a id="js_info_files"></a>

## js_info_files

<pre>
load("@aspect_rules_js//js/private:js_info_files.bzl", "js_info_files")

js_info_files(<a href="#js_info_files-name">name</a>, <a href="#js_info_files-srcs">srcs</a>, <a href="#js_info_files-include_npm_sources">include_npm_sources</a>, <a href="#js_info_files-include_sources">include_sources</a>, <a href="#js_info_files-include_transitive_sources">include_transitive_sources</a>,
              <a href="#js_info_files-include_transitive_types">include_transitive_types</a>, <a href="#js_info_files-include_types">include_types</a>)
</pre>

Gathers files from the JsInfo providers from targets in srcs and provides them as default outputs.

This helper rule is used by the `js_run_binary` macro.

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="js_info_files-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="js_info_files-srcs"></a>srcs |  List of targets to gather files from.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="js_info_files-include_npm_sources"></a>include_npm_sources |  When True, files in `npm_sources` from `JsInfo` providers in `srcs` targets are included in the default outputs of the target.<br><br>`transitive_files` from `NpmPackageStoreInfo` providers in `srcs` targets are also included in the default outputs of the target.   | Boolean | optional |  `True`  |
| <a id="js_info_files-include_sources"></a>include_sources |  When True, `sources` from `JsInfo` providers in `srcs` targets are included in the default outputs of the target.   | Boolean | optional |  `True`  |
| <a id="js_info_files-include_transitive_sources"></a>include_transitive_sources |  When True, `transitive_sources` from `JsInfo` providers in `srcs` targets are included in the default outputs of the target.   | Boolean | optional |  `True`  |
| <a id="js_info_files-include_transitive_types"></a>include_transitive_types |  When True, `transitive_types` from `JsInfo` providers in `srcs` targets are included in the default outputs of the target.<br><br>Defaults to False since types are generally not needed at runtime and introducing them could slow down developer round trip time due to having to generate typings on source file changes.   | Boolean | optional |  `False`  |
| <a id="js_info_files-include_types"></a>include_types |  When True, `types` from `JsInfo` providers in `srcs` targets are included in the default outputs of the target.<br><br>Defaults to False since types are generally not needed at runtime and introducing them could slow down developer round trip time due to having to generate typings on source file changes.<br><br>NB: These are types from direct `srcs` dependencies only. You may also need to set `include_transitive_types` to True.   | Boolean | optional |  `False`  |


