<!-- Generated with Stardoc: http://skydoc.bazel.build -->


Rules for linking npm dependencies and packaging and linking first-party deps.

Load these with,

```starlark
load("@aspect_rules_js//npm:defs.bzl", "npm_package")
```


<a id="npm_package"></a>

## npm_package

<pre>
npm_package(<a href="#npm_package-name">name</a>, <a href="#npm_package-allow_overwrites">allow_overwrites</a>, <a href="#npm_package-data">data</a>, <a href="#npm_package-exclude_srcs_packages">exclude_srcs_packages</a>, <a href="#npm_package-exclude_srcs_patterns">exclude_srcs_patterns</a>,
            <a href="#npm_package-include_external_repositories">include_external_repositories</a>, <a href="#npm_package-include_srcs_packages">include_srcs_packages</a>, <a href="#npm_package-include_srcs_patterns">include_srcs_patterns</a>, <a href="#npm_package-out">out</a>, <a href="#npm_package-package">package</a>,
            <a href="#npm_package-replace_prefixes">replace_prefixes</a>, <a href="#npm_package-root_paths">root_paths</a>, <a href="#npm_package-srcs">srcs</a>, <a href="#npm_package-version">version</a>)
</pre>

A rule that packages sources into a directory (a tree artifact) and provides an `NpmPackageInfo`.

This target can be used as the `src` attribute to `npm_link_package`.

`npm_package` makes use of `copy_to_directory`
(https://github.com/aspect-build/bazel-lib/blob/main/docs/copy_to_directory.md) under the hood,
adopting its API and its copy action using composition. However, unlike copy_to_directory,
npm_package includes transitive_sources and transitive_declarations files from JsInfo providers in srcs.

The default `include_srcs_packages`, `[".", "./**"]`, prevents files from outside of the target's
package and subpackages from being included.

The default `exclude_srcs_patterns`, of `["node_modules/**", "**/node_modules/**"]`, prevents
`node_modules` files from being included.

To stamp the current git tag as the "version" in the package.json file, see
[stamped_package_json](#stamped_package_json)


**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="npm_package-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="npm_package-allow_overwrites"></a>allow_overwrites |  If True, allow files to be overwritten if the same output file is copied to twice.<br><br>        If set, then the order of srcs matters as the last copy of a particular file will win.<br><br>        This setting has no effect on Windows where overwrites are always allowed.   | Boolean | optional | <code>False</code> |
| <a id="npm_package-data"></a>data |  Runtime / linktime npm dependencies of this npm package.<br><br>        <code>NpmPackageStoreInfo</code> providers are gathered from <code>JsInfo</code> of the targets specified. Targets can be linked npm         packages, npm package store targets or other targets that provide <code>JsInfo</code>. This is done directly from the         <code>npm_package_store_deps</code> field of these. For linked npm package targets, the underlying npm_package_store         target(s) that back the links is used.<br><br>        Gathered <code>NpmPackageStoreInfo</code> providers are used downstream as direct dependencies of this npm package when         linking with <code>npm_link_package</code>.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional | <code>[]</code> |
| <a id="npm_package-exclude_srcs_packages"></a>exclude_srcs_packages |  List of Bazel packages (with glob support) to exclude from output directory.<br><br>        Glob patterns <code>**</code>, <code>*</code> and <code>?</code> are supported. See <code>glob_match</code> documentation for         more details on how to use glob patterns:         https://github.com/aspect-build/bazel-lib/blob/main/docs/glob_match.md.<br><br>        Files and directories in srcs are not copied to the output directory if         the Bazel package of the file or directory matches one of the patterns specified.<br><br>        Forward slashes (<code>/</code>) should be used as path separators.<br><br>        A <code>"."</code> value means exclude srcs that are in the target's package.         It expands to the target's package path (<code>ctx.label.package</code>). This         will be an empty string <code>""</code> if the target is in the root package.<br><br>        A <code>"./**"</code> value means exclude srcs that are in subpackages of the target's package.         It expands to the target's package path followed by a slash and a         globstar (<code>"{}/**".format(ctx.label.package)</code>). If the target's package is         the root package, <code>"./**"</code> expands to <code>["?*", "?*/**"]</code> instead.<br><br>        Files and directories that have do not have matching Bazel packages are subject to subsequent         filters and transformations to determine if they are copied and what their path in the output         directory will be.<br><br>        Filters and transformations are applied in the following order:<br><br>1. <code>include_external_repositories</code><br><br>2. <code>include_srcs_packages</code><br><br>3. <code>exclude_srcs_packages</code><br><br>4. <code>root_paths</code><br><br>5. <code>include_srcs_patterns</code><br><br>6. <code>exclude_srcs_patterns</code><br><br>7. <code>replace_prefixes</code><br><br>For more information each filters / transformations applied, see the documentation for the specific filter / transformation attribute.   | List of strings | optional | <code>[]</code> |
| <a id="npm_package-exclude_srcs_patterns"></a>exclude_srcs_patterns |  List of paths (with glob support) to exclude from output directory.<br><br>        Glob patterns <code>**</code>, <code>*</code> and <code>?</code> are supported. See <code>glob_match</code> documentation for         more details on how to use glob patterns:         https://github.com/aspect-build/bazel-lib/blob/main/docs/glob_match.md.<br><br>        Files and directories in srcs are not copied to the output directory if their output         directory path, after applying <code>root_paths</code>, matches one of the patterns specified.<br><br>        Patterns do not look into files within source directory or generated directory (TreeArtifact)         targets since matches are performed in Starlark. To use <code>include_srcs_patterns</code> on files         within directories you can use the <code>make_directory_paths</code> helper to specify individual files inside         directories in <code>srcs</code>. This restriction may be fixed in a future release by performing matching         inside the copy action instead of in Starlark.<br><br>        Forward slashes (<code>/</code>) should be used as path separators.<br><br>        Defaults to ["node_modules/**", "**/node_modules/**"] which excludes all node_modules folders         from the output directory.<br><br>        Files and directories that do not have matching output directory paths are subject to subsequent         filters and transformations to determine if they are copied and what their path in the output         directory will be.<br><br>        See <code>copy_to_directory_action</code> documentation for list of order of filters and transformations:         https://github.com/aspect-build/bazel-lib/blob/main/docs/copy_to_directory.md#copy_to_directory.   | List of strings | optional | <code>["node_modules/**", "**/node_modules/**"]</code> |
| <a id="npm_package-include_external_repositories"></a>include_external_repositories |  List of external repository names (with glob support) to include in the output directory.<br><br>        Glob patterns <code>**</code>, <code>*</code> and <code>?</code> are supported. See <code>glob_match</code> documentation for         more details on how to use glob patterns:         https://github.com/aspect-build/bazel-lib/blob/main/docs/glob_match.md.<br><br>        Files from external repositories are only copied into the output directory if         the external repository they come from matches one of the external repository patterns         specified.<br><br>        When copied from an external repository, the file path in the output directory         defaults to the file's path within the external repository. The external repository         name is _not_ included in that path.<br><br>        For example, the following copies <code>@external_repo//path/to:file</code> to         <code>path/to/file</code> within the output directory.<br><br>        <pre><code>         copy_to_directory(             name = "dir",             include_external_repositories = ["external_*"],             srcs = ["@external_repo//path/to:file"],         )         </code></pre><br><br>        Files and directories that come from matching external are subject to subsequent filters and         transformations to determine if they are copied and what their path in the output         directory will be. The external repository name of the file or directory from an external         repository is not included in the output directory path and is considered in subsequent         filters and transformations.<br><br>        Filters and transformations are applied in the following order:<br><br>1. <code>include_external_repositories</code><br><br>2. <code>include_srcs_packages</code><br><br>3. <code>exclude_srcs_packages</code><br><br>4. <code>root_paths</code><br><br>5. <code>include_srcs_patterns</code><br><br>6. <code>exclude_srcs_patterns</code><br><br>7. <code>replace_prefixes</code><br><br>For more information each filters / transformations applied, see the documentation for the specific filter / transformation attribute.   | List of strings | optional | <code>[]</code> |
| <a id="npm_package-include_srcs_packages"></a>include_srcs_packages |  List of Bazel packages (with glob support) to include in output directory.<br><br>        Glob patterns <code>**</code>, <code>*</code> and <code>?</code> are supported. See <code>glob_match</code> documentation for         more details on how to use glob patterns:         https://github.com/aspect-build/bazel-lib/blob/main/docs/glob_match.md.<br><br>        Files and directories in srcs are only copied to the output directory if         the Bazel package of the file or directory matches one of the patterns specified.<br><br>        Forward slashes (<code>/</code>) should be used as path separators.<br><br>        A "." value expands to the target's package path (<code>ctx.label.package</code>).         A "./**" value expands to the target's package path followed by a slash and a         globstar (<code>"{{}}/**".format(ctx.label.package)</code>).<br><br>        Defaults to [".", "./**"] which includes sources target's package and subpackages.<br><br>        Files and directories that have matching Bazel packages are subject to subsequent filters and         transformations to determine if they are copied and what their path in the output         directory will be.<br><br>        See <code>copy_to_directory_action</code> documentation for list of order of filters and transformations:         https://github.com/aspect-build/bazel-lib/blob/main/docs/copy_to_directory.md#copy_to_directory.   | List of strings | optional | <code>[".", "./**"]</code> |
| <a id="npm_package-include_srcs_patterns"></a>include_srcs_patterns |  List of paths (with glob support) to include in output directory.<br><br>        Glob patterns <code>**</code>, <code>*</code> and <code>?</code> are supported. See <code>glob_match</code> documentation for         more details on how to use glob patterns:         https://github.com/aspect-build/bazel-lib/blob/main/docs/glob_match.md.<br><br>        Files and directories in srcs are only copied to the output directory if their output         directory path, after applying <code>root_paths</code>, matches one of the patterns specified.<br><br>        Patterns do not look into files within source directory or generated directory (TreeArtifact)         targets since matches are performed in Starlark. To use <code>include_srcs_patterns</code> on files         within directories you can use the <code>make_directory_paths</code> helper to specify individual files inside         directories in <code>srcs</code>. This restriction may be fixed in a future release by performing matching         inside the copy action instead of in Starlark.<br><br>        Forward slashes (<code>/</code>) should be used as path separators.<br><br>        Defaults to ["**"] which includes all sources.<br><br>        Files and directories that have matching output directory paths are subject to subsequent         filters and transformations to determine if they are copied and what their path in the output         directory will be.<br><br>        Filters and transformations are applied in the following order:<br><br>1. <code>include_external_repositories</code><br><br>2. <code>include_srcs_packages</code><br><br>3. <code>exclude_srcs_packages</code><br><br>4. <code>root_paths</code><br><br>5. <code>include_srcs_patterns</code><br><br>6. <code>exclude_srcs_patterns</code><br><br>7. <code>replace_prefixes</code><br><br>For more information each filters / transformations applied, see the documentation for the specific filter / transformation attribute.   | List of strings | optional | <code>["**"]</code> |
| <a id="npm_package-out"></a>out |  Path of the output directory, relative to this package.<br><br>        If not set, the name of the target is used.   | String | optional | <code>""</code> |
| <a id="npm_package-package"></a>package |  The package name. If set, should match the <code>name</code> field in the <code>package.json</code> file for this package.<br><br>If set, the package name set here will be used for linking if a npm_link_package does not specify a package name. A  npm_link_package that specifies a package name will override the value here when linking.<br><br>If unset, a npm_link_package that references this npm_package must define the package name must be for linking.   | String | optional | <code>""</code> |
| <a id="npm_package-replace_prefixes"></a>replace_prefixes |  Map of paths prefixes (with glob support) to replace in the output directory path when copying files.<br><br>        Glob patterns <code>**</code>, <code>*</code> and <code>?</code> are supported but the pattern must not end with a <code>**</code> glob         expression. See <code>glob_match</code> documentation for more details on how to use glob patterns:         https://github.com/aspect-build/bazel-lib/blob/main/docs/glob_match.md.<br><br>        If the output directory path for a file or directory starts with or fully matches a         a key in the dict then the matching portion of the output directory path is         replaced with the dict value for that key. The final path segment         matched can be a partial match of that segment and only the matching portion will         be replaced. If there are multiple keys that match, the longest match wins.<br><br>        Patterns do not look into files within source directory or generated directory (TreeArtifact)         targets since matches are performed in Starlark. To use <code>replace_prefixes</code> on files         within directories you can use the <code>make_directory_paths</code> helper to specify individual files inside         directories in <code>srcs</code>. This restriction may be fixed in a future release by performing matching         inside the copy action instead of in Starlark.<br><br>        Forward slashes (<code>/</code>) should be used as path separators. <br><br>        Replace prefix transformation are the final step in the list of filters and transformations.         The final output path of a file or directory being copied into the output directory         is determined at this step.<br><br>        Filters and transformations are applied in the following order:<br><br>1. <code>include_external_repositories</code><br><br>2. <code>include_srcs_packages</code><br><br>3. <code>exclude_srcs_packages</code><br><br>4. <code>root_paths</code><br><br>5. <code>include_srcs_patterns</code><br><br>6. <code>exclude_srcs_patterns</code><br><br>7. <code>replace_prefixes</code><br><br>For more information each filters / transformations applied, see the documentation for the specific filter / transformation attribute.   | <a href="https://bazel.build/rules/lib/dict">Dictionary: String -> String</a> | optional | <code>{}</code> |
| <a id="npm_package-root_paths"></a>root_paths |  List of paths (with glob support) that are roots in the output directory.<br><br>        Glob patterns <code>**</code>, <code>*</code> and <code>?</code> are supported. See <code>glob_match</code> documentation for         more details on how to use glob patterns:         https://github.com/aspect-build/bazel-lib/blob/main/docs/glob_match.md.<br><br>        If any parent directory of a file or directory being copied matches one of the root paths         patterns specified, the output directory path will be the path relative to the root path         instead of the path relative to the file's or directory's workspace. If there are multiple         root paths that match, the longest match wins.<br><br>        Matching is done on the parent directory of the output file path so a trailing '**' glob patterm         will match only up to the last path segment of the dirname and will not include the basename.         Only complete path segments are matched. Partial matches on the last segment of the root path         are ignored.<br><br>        Forward slashes (<code>/</code>) should be used as path separators.<br><br>        A "." value expands to the target's package path (<code>ctx.label.package</code>).<br><br>        Defaults to ["."] which results in the output directory path of files in the         target's package and and sub-packages are relative to the target's package and         files outside of that retain their full workspace relative paths.<br><br>        Filters and transformations are applied in the following order:<br><br>1. <code>include_external_repositories</code><br><br>2. <code>include_srcs_packages</code><br><br>3. <code>exclude_srcs_packages</code><br><br>4. <code>root_paths</code><br><br>5. <code>include_srcs_patterns</code><br><br>6. <code>exclude_srcs_patterns</code><br><br>7. <code>replace_prefixes</code><br><br>For more information each filters / transformations applied, see the documentation for the specific filter / transformation attribute.   | List of strings | optional | <code>["."]</code> |
| <a id="npm_package-srcs"></a>srcs |  Files and/or directories or targets that provide DirectoryPathInfo to copy         into the output directory.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional | <code>[]</code> |
| <a id="npm_package-version"></a>version |  The package version. If set, should match the <code>version</code> field in the <code>package.json</code> file for this package.<br><br>If set, a npm_link_package may omit the package version and the package version set here will be used for linking. A  npm_link_package that specifies a package version will override the value here when linking.<br><br>If unset, a npm_link_package that references this npm_package must define the package version must be for linking.   | String | optional | <code>"0.0.0"</code> |


<a id="npm_package_lib.implementation"></a>

## npm_package_lib.implementation

<pre>
npm_package_lib.implementation(<a href="#npm_package_lib.implementation-ctx">ctx</a>)
</pre>



**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="npm_package_lib.implementation-ctx"></a>ctx |  <p align="center"> - </p>   |  none |


<a id="stamped_package_json"></a>

## stamped_package_json

<pre>
stamped_package_json(<a href="#stamped_package_json-name">name</a>, <a href="#stamped_package_json-stamp_var">stamp_var</a>, <a href="#stamped_package_json-kwargs">kwargs</a>)
</pre>

Convenience wrapper to set the "version" property in package.json with the git tag.

In unstamped builds (typically those without `--stamp`) the version will be set to `0.0.0`.
This ensures that actions which use the package.json file can get cache hits.

For more information on stamping, read https://github.com/aspect-build/bazel-lib/blob/main/docs/stamping.md.

Using this rule requires that you register the jq toolchain in your WORKSPACE:

```starlark
load("@aspect_bazel_lib//lib:repositories.bzl", "register_jq_toolchains")

register_jq_toolchains()
```


**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="stamped_package_json-name"></a>name |  name of the resulting <code>jq</code> target, must be "package"   |  none |
| <a id="stamped_package_json-stamp_var"></a>stamp_var |  a key from the bazel-out/stable-status.txt or bazel-out/volatile-status.txt files   |  none |
| <a id="stamped_package_json-kwargs"></a>kwargs |  additional attributes passed to the jq rule, see https://github.com/aspect-build/bazel-lib/blob/main/docs/jq.md   |  none |


