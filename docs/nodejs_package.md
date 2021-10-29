<!-- Generated with Stardoc: http://skydoc.bazel.build -->

nodejs_package rule

<a id="#nodejs_package"></a>

## nodejs_package

<pre>
nodejs_package(<a href="#nodejs_package-name">name</a>, <a href="#nodejs_package-src">src</a>, <a href="#nodejs_package-srcs">srcs</a>, <a href="#nodejs_package-remap_paths">remap_paths</a>, <a href="#nodejs_package-kwargs">kwargs</a>)
</pre>

Copies all source files to an an output directory.

NB: This rule is not yet tested on Windows


**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="nodejs_package-name"></a>name |  Name of the rule.   |  none |
| <a id="nodejs_package-src"></a>src |  a single TreeArtifact produced by a copy_file rule containing the package files   |  <code>None</code> |
| <a id="nodejs_package-srcs"></a>srcs |  List of files and/or directories to copy.   |  <code>[]</code> |
| <a id="nodejs_package-remap_paths"></a>remap_paths |  Path mappings from source to destination   |  <code>None</code> |
| <a id="nodejs_package-kwargs"></a>kwargs |  further keyword arguments, e.g. <code>visibility</code>   |  none |


