<!-- Generated with Stardoc: http://skydoc.bazel.build -->

`js_library` is similar to [`filegroup`](https://docs.bazel.build/versions/main/be/general.html#filegroup); there are no Bazel actions to run.

It only groups JS files together, and propagates their dependencies, along with a DeclarationInfo so that it can be a dep of ts_project.

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


<a id="#js_library"></a>

## js_library

<pre>
js_library(<a href="#js_library-name">name</a>, <a href="#js_library-deps">deps</a>, <a href="#js_library-npm_linked_package_deps">npm_linked_package_deps</a>, <a href="#js_library-srcs">srcs</a>)
</pre>

Copies all sources to the output tree and expose some files with DeclarationInfo.

Can be used as a dep for rules that expect a DeclarationInfo such as ts_project.

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="js_library-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/docs/build-ref.html#name">Name</a> | required |  |
| <a id="js_library-deps"></a>deps |  Direct dependencies of this library. This may include         other js_library targets as well as npm dependencies.   | <a href="https://bazel.build/docs/build-ref.html#labels">List of labels</a> | optional | [] |
| <a id="js_library-npm_linked_package_deps"></a>npm_linked_package_deps |  A list of targets that provide NpmLinkedPackageStoreInfo and/or NpmLinkedPackageStoreDepsInfo.<br><br>        These can be direct npm links targets from any directly linked npm package such as //:node_modules/foo         or virtual store npm link targets such as //.aspect_rules_js/node_modules/foo/1.2.3.         When a direct npm link target is passed, the underlying virtual store npm link target is used.         They can also be targets from rules that have also npm_linked_package_deps attributes and follow the same         pattern of re-exporting all NpmLinkedPackageStoreInfo providers found with a NpmLinkedPackageStoreDepsInfo provider.<br><br>        The transitive closure of NpmLinkedPackageStoreInfo providers found in this list of targets is         collected and re-exported by this target with a NpmLinkedPackageStoreDepsInfo provider.<br><br>        These are typically accumulated and re-exported by a downstream NpmPackage target to be used when         linking that package.   | <a href="https://bazel.build/docs/build-ref.html#labels">List of labels</a> | optional | [] |
| <a id="js_library-srcs"></a>srcs |  The list of source files that are processed to create the target.<br><br>        This includes all your checked-in code and any generated source files.<br><br>        Other js_library targets and npm dependencies belong in <code>deps</code>.   | <a href="https://bazel.build/docs/build-ref.html#labels">List of labels</a> | optional | [] |


<a id="#js_library_lib.implementation"></a>

## js_library_lib.implementation

<pre>
js_library_lib.implementation(<a href="#js_library_lib.implementation-ctx">ctx</a>)
</pre>



**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="js_library_lib.implementation-ctx"></a>ctx |  <p align="center"> - </p>   |  none |


