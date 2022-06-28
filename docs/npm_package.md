<!-- Generated with Stardoc: http://skydoc.bazel.build -->


Rules for linking npm dependencies and packaging and linking first-party deps.

Load these with,

```starlark
load("@aspect_rules_js//npm:defs.bzl", "npm_package")
```


<a id="#npm_package"></a>

## npm_package

<pre>
npm_package(<a href="#npm_package-name">name</a>, <a href="#npm_package-allow_overwrites">allow_overwrites</a>, <a href="#npm_package-exclude_prefixes">exclude_prefixes</a>, <a href="#npm_package-include_external_repositories">include_external_repositories</a>, <a href="#npm_package-out">out</a>, <a href="#npm_package-package">package</a>,
            <a href="#npm_package-replace_prefixes">replace_prefixes</a>, <a href="#npm_package-root_paths">root_paths</a>, <a href="#npm_package-srcs">srcs</a>, <a href="#npm_package-version">version</a>)
</pre>

A rule that packages sources into a TreeArtifact or forwards a tree artifact and provides a NpmPackageInfo.

This target can be used as the src attribute to npm_link_package.

A DeclarationInfo is also provided so that the target can be used as an input to rules that expect one such as ts_project.

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="npm_package-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/docs/build-ref.html#name">Name</a> | required |  |
| <a id="npm_package-allow_overwrites"></a>allow_overwrites |  If True, allow files to be overwritten if the same output file is copied to twice.<br><br>        If set, then the order of srcs matters as the last copy of a particular file will win.<br><br>        This setting has no effect on Windows where overwrites are always allowed.   | Boolean | optional | False |
| <a id="npm_package-exclude_prefixes"></a>exclude_prefixes |  List of path prefixes to exclude from output directory.<br><br>        If the output directory path for a file or directory starts with or is equal to         a path in the list then that file is not copied to the output directory.<br><br>        Exclude prefixes are matched *before* replace_prefixes are applied.   | List of strings | optional | [] |
| <a id="npm_package-include_external_repositories"></a>include_external_repositories |  List of external repository names to include in the output directory.<br><br>        Files from external repositories are not copied into the output directory unless         the external repository they come from is listed here.<br><br>        When copied from an external repository, the file path in the output directory         defaults to the file's path within the external repository. The external repository         name is _not_ included in that path.<br><br>        For example, the following copies <code>@external_repo//path/to:file</code> to         <code>path/to/file</code> within the output directory.<br><br>        <pre><code>         copy_to_directory(             name = "dir",             include_external_repositories = ["external_repo"],             srcs = ["@external_repo//path/to:file"],         )         </code></pre><br><br>        Files from external repositories are subject to <code>root_paths</code>, <code>exclude_prefixes</code>         and <code>replace_prefixes</code> in the same way as files form the main repository.   | List of strings | optional | [] |
| <a id="npm_package-out"></a>out |  Path of the output directory, relative to this package.<br><br>        If not set, the name of the target is used.   | String | optional | "" |
| <a id="npm_package-package"></a>package |  The package name. If set, should match the <code>name</code> field in the <code>package.json</code> file for this package.<br><br>If set, the package name set here will be used for linking if a npm_link_package does not specify a package name. A  npm_link_package target that specifies a package name will override the value here when linking.<br><br>If unset, a npm_link_package target that references this npm_package must define the package name must be for linking.   | String | optional | "" |
| <a id="npm_package-replace_prefixes"></a>replace_prefixes |  Map of paths prefixes to replace in the output directory path when copying files.<br><br>        If the output directory path for a file or directory starts with or is equal to         a key in the dict then the matching portion of the output directory path is         replaced with the dict value for that key.<br><br>        Forward slashes (<code>/</code>) should be used as path separators. The final path segment         of the key can be a partial match in the corresponding segment of the output         directory path.<br><br>        If there are multiple keys that match, the longest match wins.   | <a href="https://bazel.build/docs/skylark/lib/dict.html">Dictionary: String -> String</a> | optional | {} |
| <a id="npm_package-root_paths"></a>root_paths |  List of paths that are roots in the output directory.<br><br>        "." values indicate the targets package path.<br><br>        If a file or directory being copied is in one of the listed paths or one of its subpaths,         the output directory path is the path relative to the root path instead of the path         relative to the file's workspace.<br><br>        Forward slashes (<code>/</code>) should be used as path separators. Partial matches         on the final path segment of a root path against the corresponding segment         in the full workspace relative path of a file are not matched.<br><br>        If there are multiple root paths that match, the longest match wins.<br><br>        Defaults to [package_name()] so that the output directory path of files in the         target's package and and sub-packages are relative to the target's package and         files outside of that retain their full workspace relative paths.   | List of strings | optional | ["."] |
| <a id="npm_package-srcs"></a>srcs |  Files and/or directories or targets that provide DirectoryPathInfo to copy         into the output directory.   | <a href="https://bazel.build/docs/build-ref.html#labels">List of labels</a> | optional | [] |
| <a id="npm_package-version"></a>version |  The package version. If set, should match the <code>version</code> field in the <code>package.json</code> file for this package.<br><br>If set, a npm_link_package may omit the package version and the package version set here will be used for linking. A  npm_link_package target that specifies a package version will override the value here when linking.<br><br>If unset, a npm_link_package target that references this npm_package must define the package version must be for linking.   | String | optional | "0.0.0" |


<a id="#NpmPackageInfo"></a>

## NpmPackageInfo

<pre>
NpmPackageInfo(<a href="#NpmPackageInfo-label">label</a>, <a href="#NpmPackageInfo-package">package</a>, <a href="#NpmPackageInfo-version">version</a>, <a href="#NpmPackageInfo-directory">directory</a>)
</pre>

A provider that carries the output directory (a TreeArtifact) of an npm package which contains the packages sources along with the package name and version

**FIELDS**


| Name  | Description |
| :------------- | :------------- |
| <a id="NpmPackageInfo-label"></a>label |  the label of the target the created this provider    |
| <a id="NpmPackageInfo-package"></a>package |  name of this node package    |
| <a id="NpmPackageInfo-version"></a>version |  version of this node package    |
| <a id="NpmPackageInfo-directory"></a>directory |  the output directory (a TreeArtifact) that contains the package sources    |


<a id="#npm_package_lib.implementation"></a>

## npm_package_lib.implementation

<pre>
npm_package_lib.implementation(<a href="#npm_package_lib.implementation-ctx">ctx</a>)
</pre>



**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="npm_package_lib.implementation-ctx"></a>ctx |  <p align="center"> - </p>   |  none |


