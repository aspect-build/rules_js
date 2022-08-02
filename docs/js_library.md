<!-- Generated with Stardoc: http://skydoc.bazel.build -->

js_library groups together JS sources and arranges them and their transitive and npm dependencies into a provided
`JsInfo`. There are no Bazel actions to run.

For example, this `BUILD` file groups a pair of `.js/.d.ts` files along with the `package.json`.
The latter is needed because it contains a `typings` key that allows downstream
users of this library to resolve the `one.d.ts` file.
The `main` key is another commonly used field in `package.json` which would require including it in the library.

```starlark
load("@aspect_rules_js//js:defs.bzl", "js_library")

js_library(
    name = "one",
    srcs = [
        "one.d.ts",
        "one.js",
        "package.json",
    ],
)
```

| This is similar to [`py_library`](https://docs.bazel.build/versions/main/be/python.html#py_library) which depends on
| Python sources and provides a `PyInfo`.


<a id="#js_library"></a>

## js_library

<pre>
js_library(<a href="#js_library-name">name</a>, <a href="#js_library-data">data</a>, <a href="#js_library-deps">deps</a>, <a href="#js_library-srcs">srcs</a>)
</pre>

A library of JavaScript sources. Provides JsInfo, the primary provider used in rules_js
and derivative rule sets.

Declaration files are handled separately from sources since they are generally not needed at
runtime and build rules, such as ts_project, are optimal in their build graph if they only depend
on declarations from 'deps' since these they don't need the JavaScript source files from deps to
typecheck.

Linked npm dependences are also handled separately from sources since not all rules require them and it
is optimal for these rules to not depend on them in the build graph.

NB: 'js_library' copies all source files to the output tree before providing them in JsInfo. See
https://github.com/aspect-build/rules_js/tree/dbb5af0d2a9a2bb50e4cf4a96dbc582b27567155/docs#javascript
for more context on why we do this.

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="js_library-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/docs/build-ref.html#name">Name</a> | required |  |
| <a id="js_library-data"></a>data |  Runtime dependencies to include in binaries/tests that depend on this library.<br><br>        If this list contains linked npm packages, npm package store targets or other targets that provide 'JsInfo',         'NpmPackageStoreInfo' providers are gathered from 'JsInfo'. This is done directly from 'npm_package_stores' and         'transitive_npm_package_stores' fields of these and for linked npm package targets, from the underlying         npm_package_store target(s) that back the links via 'npm_linked_packages' and 'transitive_npm_linked_packages'.<br><br>        Gathered 'NpmPackageStoreInfo' providers are used downstream as direct dependencies when linking a downstream         'npm_package' target with 'npm_link_package'.   | <a href="https://bazel.build/docs/build-ref.html#labels">List of labels</a> | optional | [] |
| <a id="js_library-deps"></a>deps |  Dependencies of this library.<br><br>        The default outputs and runfiles of targets in the data attribute should appear in the '*.runfiles' area of any         executable which is output by or has a runtime dependency on this target.<br><br>        This may include other js_library targets or other targets that provide.   | <a href="https://bazel.build/docs/build-ref.html#labels">List of labels</a> | optional | [] |
| <a id="js_library-srcs"></a>srcs |  Source files that are included in this library.<br><br>        This includes all your checked-in code and any generated source files.   | <a href="https://bazel.build/docs/build-ref.html#labels">List of labels</a> | optional | [] |


<a id="#js_library_lib.implementation"></a>

## js_library_lib.implementation

<pre>
js_library_lib.implementation(<a href="#js_library_lib.implementation-ctx">ctx</a>)
</pre>



**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="js_library_lib.implementation-ctx"></a>ctx |  <p align="center"> - </p>   |  none |


