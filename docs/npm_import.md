<!-- Generated with Stardoc: http://skydoc.bazel.build -->

npm_import repository rule

<a id="#npm_import"></a>

## npm_import

<pre>
npm_import(<a href="#npm_import-integrity">integrity</a>, <a href="#npm_import-package">package</a>, <a href="#npm_import-version">version</a>, <a href="#npm_import-deps">deps</a>)
</pre>

Import a single npm package into Bazel.

Bazel will only fetch the package from an external registry if the package is
required for the user-requested targets to be build/tested.
The package will be exposed as a [`nodejs_package`](./nodejs_package) rule in a repository
named `@npm_[package name]-[version]`, as the default target in that repository.
(Characters in the package name which are not legal in Bazel repository names are converted to underscore.)

This is a repository rule, which should be called from your `WORKSPACE` file
or some `.bzl` file loaded from it. For example, with this code in `WORKSPACE`:

```starlark
npm_import(
    integrity = "sha512-zjQ69G564OCIWIOHSXyQEEDpdpGl+G348RAKY0XXy9Z5kU9Vzv1GMNnkar/ZJ8dzXB3COzD9Mo9NtRZ4xfgUww==",
    package = "@types/node",
    version = "15.12.2",
)
```

you can use the label `@npm__types_node-15.12.2` in your BUILD files to reference the package.

> This is similar to Bazel rules in other ecosystems named "_import" like
> `apple_bundle_import`, `scala_import`, `java_import`, and `py_import`
> `go_repository` is also a model for this rule.

The name of this repository should contain the version number, so that multiple versions of the same
package don't collide.
(Note that the npm ecosystem always supports multiple versions of a library depending on where
it is required, unlike other languages like Go or Python.)

To change the proxy URL we use to fetch, configure the Bazel downloader:
1. Make a file containing a rewrite rule like

   rewrite (registry.nodejs.org)/(.*) artifactory.build.internal.net/artifactory/$1/$2

1. To understand the rewrites, see [UrlRewriterConfig] in Bazel sources.

1. Point bazel to the config with a line in .bazelrc like
    common --experimental_downloader_config=.bazel_downloader_config

[UrlRewriterConfig]: https://github.com/bazelbuild/bazel/blob/4.2.1/src/main/java/com/google/devtools/build/lib/bazel/repository/downloader/UrlRewriterConfig.java#L66


**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="npm_import-integrity"></a>integrity |  Expected checksum of the file downloaded, in Subresource Integrity format. This must match the checksum of the file downloaded.<br><br>This is the same as appears in the yarn.lock or package-lock.json file.<br><br>It is a security risk to omit the checksum as remote files can change. At best omitting this field will make your build non-hermetic. It is optional to make development easier but should be set before shipping.   |  none |
| <a id="npm_import-package"></a>package |  npm package name, such as <code>acorn</code> or <code>@types/node</code>   |  none |
| <a id="npm_import-version"></a>version |  version of the npm package, such as <code>8.4.0</code>   |  none |
| <a id="npm_import-deps"></a>deps |  other npm packages this one depends on   |  <code>[]</code> |


