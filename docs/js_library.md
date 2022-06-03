<!-- Generated with Stardoc: http://skydoc.bazel.build -->

Expose some files with DeclarationInfo, like filegroup but can be a dep of ts_project.

Load this with,

```starlark
load("@aspect_rules_js//js:defs.bzl", "js_library")
```


<a id="#js_library"></a>

## js_library

<pre>
js_library(<a href="#js_library-name">name</a>, <a href="#js_library-deps">deps</a>, <a href="#js_library-srcs">srcs</a>)
</pre>

Copies all sources to the output tree and expose some files with DeclarationInfo.

Can be used as a dep for rules that expect a DeclarationInfo such as ts_project.

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="js_library-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/docs/build-ref.html#name">Name</a> | required |  |
| <a id="js_library-deps"></a>deps |  -   | <a href="https://bazel.build/docs/build-ref.html#labels">List of labels</a> | optional | [] |
| <a id="js_library-srcs"></a>srcs |  -   | <a href="https://bazel.build/docs/build-ref.html#labels">List of labels</a> | optional | [] |


<a id="#js_library_lib.implementation"></a>

## js_library_lib.implementation

<pre>
js_library_lib.implementation(<a href="#js_library_lib.implementation-ctx">ctx</a>)
</pre>



**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="js_library_lib.implementation-ctx"></a>ctx |  <p align="center"> - </p>   |  none |


