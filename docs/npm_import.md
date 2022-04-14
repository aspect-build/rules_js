<!-- Generated with Stardoc: http://skydoc.bazel.build -->

wrapper macro for npm_import repository rule

<a id="#npm_import"></a>

## npm_import

<pre>
npm_import(<a href="#npm_import-name">name</a>, <a href="#npm_import-deps">deps</a>, <a href="#npm_import-experimental_reference_deps">experimental_reference_deps</a>, <a href="#npm_import-indirect">indirect</a>, <a href="#npm_import-integrity">integrity</a>, <a href="#npm_import-link_package_guard">link_package_guard</a>,
           <a href="#npm_import-package_name">package_name</a>, <a href="#npm_import-package_version">package_version</a>, <a href="#npm_import-patch_args">patch_args</a>, <a href="#npm_import-patches">patches</a>, <a href="#npm_import-repo_mapping">repo_mapping</a>)
</pre>

Import a single npm package into Bazel.

Normally you'd want to use `translate_pnpm_lock` to import all your packages at once.
It generates `npm_import` rules.
You can create these manually if you want to have exact control.

Bazel will only fetch the given package from an external registry if the package is
required for the user-requested targets to be build/tested.

This is a repository rule, which should be called from your `WORKSPACE` file
or some `.bzl` file loaded from it. For example, with this code in `WORKSPACE`:

```starlark
npm_import(
    name = "npm__types_node-15.2.2",
    package_name = "@types/node",
    package_version = "15.12.2",
    integrity = "sha512-zjQ69G564OCIWIOHSXyQEEDpdpGl+G348RAKY0XXy9Z5kU9Vzv1GMNnkar/ZJ8dzXB3COzD9Mo9NtRZ4xfgUww==",
)
```

> This is similar to Bazel rules in other ecosystems named "_import" like
> `apple_bundle_import`, `scala_import`, `java_import`, and `py_import`.
> `go_repository` is also a model for this rule.

The name of this repository should contain the version number, so that multiple versions of the same
package don't collide.
(Note that the npm ecosystem always supports multiple versions of a library depending on where
it is required, unlike other languages like Go or Python.)

To consume the downloaded package in rules, it must be "linked" into the link package in the
package's `BUILD.bazel` file:

```
load("@npm__types_node-15.2.2//:nodejs_package.bzl", nodejs_package_types_node = "nodejs_package")

nodejs_package_types_node()
```

The instantiates an `nodejs_binary` target for this package that can be referenced by the alias
`@//link/package:npm__name` and `@//link/package:npm__@scope+name` for scoped packages.
The `npm` prefix of these alias is configurable via the `namespace` attribute.

When using `translate_pnpm_lock`, you can `link` all the npm dependencies in the lock files with:

```
load("@npm//:nodejs_packages.bzl", "nodejs_packages")

nodejs_packages()
```

`translate_pnpm_lock` also creates convienence aliases in the external repository that reference
the linked `nodejs_package` targets. For example, `@npm//name` and `@npm//@scope/name`.

To change the proxy URL we use to fetch, configure the Bazel downloader:

1. Make a file containing a rewrite rule like

    rewrite (registry.nodejs.org)/(.*) artifactory.build.internal.net/artifactory/$1/$2

1. To understand the rewrites, see [UrlRewriterConfig] in Bazel sources.

1. Point bazel to the config with a line in .bazelrc like
common --experimental_downloader_config=.bazel_downloader_config

[UrlRewriterConfig]: https://github.com/bazelbuild/bazel/blob/4.2.1/src/main/java/com/google/devtools/build/lib/bazel/repository/downloader/UrlRewriterConfig.java#L66


**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="npm_import-name"></a>name |  A unique name for this repository.   | <a href="https://bazel.build/docs/build-ref.html#name">Name</a> | required |  |
| <a id="npm_import-deps"></a>deps |  Other npm packages this one depends on   | List of strings | optional | [] |
| <a id="npm_import-experimental_reference_deps"></a>experimental_reference_deps |  Experimental reference deps allow dep to support circular deps between npm packages.         This feature depends on dangling symlinks, however, which is still experimental in bazel,         has issues with "host" and "exec" configurations, and does not yet work with remote exection.   | Boolean | optional | False |
| <a id="npm_import-indirect"></a>indirect |  If True, this is a indirect npm dependency which will not be linked as a top-level node_module.   | Boolean | optional | False |
| <a id="npm_import-integrity"></a>integrity |  Expected checksum of the file downloaded, in Subresource Integrity format.         This must match the checksum of the file downloaded.<br><br>        This is the same as appears in the pnpm-lock.yaml, yarn.lock or package-lock.json file.<br><br>        It is a security risk to omit the checksum as remote files can change.         At best omitting this field will make your build non-hermetic.         It is optional to make development easier but should be set before shipping.   | String | optional | "" |
| <a id="npm_import-link_package_guard"></a>link_package_guard |  When explictly set, check that the generated nodejs_package() marcro         in package.bzl is called within the specified package.<br><br>        Default value of "." implies no gaurd.<br><br>        This is set by automatically when using translate_pnpm_lock via npm_import         to guard against linking the generated nodejs_packages into the wrong         location.   | String | optional | "." |
| <a id="npm_import-package_name"></a>package_name |  Name of the npm package, such as <code>acorn</code> or <code>@types/node</code>   | String | required |  |
| <a id="npm_import-package_version"></a>package_version |  Version of the npm package, such as <code>8.4.0</code>   | String | required |  |
| <a id="npm_import-patch_args"></a>patch_args |  Arguments to pass to the patch tool.         <code>-p1</code> will usually be needed for patches generated by git.   | List of strings | optional | ["-p0"] |
| <a id="npm_import-patches"></a>patches |  Patch files to apply onto the downloaded npm package.   | <a href="https://bazel.build/docs/build-ref.html#labels">List of labels</a> | optional | [] |
| <a id="npm_import-repo_mapping"></a>repo_mapping |  A dictionary from local repository name to global repository name. This allows controls over workspace dependency resolution for dependencies of this repository.&lt;p&gt;For example, an entry <code>"@foo": "@bar"</code> declares that, for any time this repository depends on <code>@foo</code> (such as a dependency on <code>@foo//some:target</code>, it should actually resolve that dependency within globally-declared <code>@bar</code> (<code>@bar//some:target</code>).   | <a href="https://bazel.build/docs/skylark/lib/dict.html">Dictionary: String -> String</a> | required |  |


