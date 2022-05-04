<!-- Generated with Stardoc: http://skydoc.bazel.build -->

js_package rule

<a id="#js_package"></a>

## js_package

<pre>
js_package(<a href="#js_package-name">name</a>, <a href="#js_package-exclude_prefixes">exclude_prefixes</a>, <a href="#js_package-include_external_repositories">include_external_repositories</a>, <a href="#js_package-package">package</a>, <a href="#js_package-replace_prefixes">replace_prefixes</a>,
           <a href="#js_package-root_paths">root_paths</a>, <a href="#js_package-src">src</a>, <a href="#js_package-srcs">srcs</a>, <a href="#js_package-version">version</a>)
</pre>

A rule that packages sources into a TreeArtifact or forwards a tree artifact and provides a JsPackageInfo.

This target can be used as the src attribute to link_js_package.

A DeclarationInfo is also provided so that the target can be used as an input to rules that expect one such as ts_project.

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="js_package-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/docs/build-ref.html#name">Name</a> | required |  |
| <a id="js_package-exclude_prefixes"></a>exclude_prefixes |  List of path prefixes to exclude from output directory.<br><br>        If the output directory path for a file or directory starts with or is equal to         a path in the list then that file is not copied to the output directory.<br><br>        Exclude prefixes are matched *before* replace_prefixes are applied.   | List of strings | optional | [] |
| <a id="js_package-include_external_repositories"></a>include_external_repositories |  List of external repository names to include in the output directory.<br><br>        Files from external repositories are not copied into the output directory unless         the external repository they come from is listed here.<br><br>        When copied from an external repository, the file path in the output directory         defaults to the file's path within the external repository. The external repository         name is _not_ included in that path.<br><br>        For example, the following copies <code>@external_repo//path/to:file</code> to         <code>path/to/file</code> within the output directory.<br><br>        <pre><code>         copy_to_directory(             name = "dir",             include_external_repositories = ["external_repo"],             srcs = ["@external_repo//path/to:file"],         )         </code></pre><br><br>        Files from external repositories are subject to <code>root_paths</code>, <code>exclude_prefixes</code>         and <code>replace_prefixes</code> in the same way as files form the main repository.   | List of strings | optional | [] |
| <a id="js_package-package"></a>package |  Must match the <code>name</code> field in the <code>package.json</code> file for this package.   | String | required |  |
| <a id="js_package-replace_prefixes"></a>replace_prefixes |  Map of paths prefixes to replace in the output directory path when copying files.<br><br>        If the output directory path for a file or directory starts with or is equal to         a key in the dict then the matching portion of the output directory path is         replaced with the dict value for that key.<br><br>        Forward slashes (<code>/</code>) should be used as path separators. The final path segment         of the key can be a partial match in the corresponding segment of the output         directory path.<br><br>        If there are multiple keys that match, the longest match wins.   | <a href="https://bazel.build/docs/skylark/lib/dict.html">Dictionary: String -> String</a> | optional | {} |
| <a id="js_package-root_paths"></a>root_paths |  List of paths that are roots in the output directory.<br><br>        "." values indicate the targets package path.<br><br>        If a file or directory being copied is in one of the listed paths or one of its subpaths,         the output directory path is the path relative to the root path instead of the path         relative to the file's workspace.<br><br>        Forward slashes (<code>/</code>) should be used as path separators. Partial matches         on the final path segment of a root path against the corresponding segment         in the full workspace relative path of a file are not matched.<br><br>        If there are multiple root paths that match, the longest match wins.<br><br>        Defaults to [package_name()] so that the output directory path of files in the         target's package and and sub-packages are relative to the target's package and         files outside of that retain their full workspace relative paths.   | List of strings | optional | ["."] |
| <a id="js_package-src"></a>src |  A source directory or output directory to use for this package. For specifying a list of files, use <code>srcs</code> instead.   | <a href="https://bazel.build/docs/build-ref.html#labels">Label</a> | optional | None |
| <a id="js_package-srcs"></a>srcs |  Files and/or directories or targets that provide DirectoryPathInfo to copy         into the output directory.   | <a href="https://bazel.build/docs/build-ref.html#labels">List of labels</a> | optional | [] |
| <a id="js_package-version"></a>version |  Must match the <code>version</code> field in the <code>package.json</code> file for this package.   | String | optional | "0.0.0" |


<a id="#JsPackageInfo"></a>

## JsPackageInfo

<pre>
JsPackageInfo(<a href="#JsPackageInfo-label">label</a>, <a href="#JsPackageInfo-package">package</a>, <a href="#JsPackageInfo-version">version</a>, <a href="#JsPackageInfo-directory">directory</a>)
</pre>

A provider that carries the output directory (a TreeArtifact) of a js_package which contains the packages sources along with the package name and version

**FIELDS**


| Name  | Description |
| :------------- | :------------- |
| <a id="JsPackageInfo-label"></a>label |  the label of the target the created this provider    |
| <a id="JsPackageInfo-package"></a>package |  name of this node package    |
| <a id="JsPackageInfo-version"></a>version |  version of this node package    |
| <a id="JsPackageInfo-directory"></a>directory |  the output directory (a TreeArtifact) that contains the package sources    |


<a id="#js_package_lib.implementation"></a>

## js_package_lib.implementation

<pre>
js_package_lib.implementation(<a href="#js_package_lib.implementation-ctx">ctx</a>)
</pre>



**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="js_package_lib.implementation-ctx"></a>ctx |  <p align="center"> - </p>   |  none |


