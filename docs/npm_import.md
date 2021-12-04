<!-- Generated with Stardoc: http://skydoc.bazel.build -->

repository rules for importing packages from npm

<a id="#translate_package_lock"></a>

## translate_package_lock

<pre>
translate_package_lock(<a href="#translate_package_lock-name">name</a>, <a href="#translate_package_lock-package_lock">package_lock</a>, <a href="#translate_package_lock-repo_mapping">repo_mapping</a>)
</pre>

Repository rule to generate npm_import rules from package-lock.json file.

The npm lockfile format includes all the information needed to define npm_import rules,
including the integrity hash, as calculated by the package manager.

Instead of manually declaring the `npm_imports`, this helper generates an external repository
containing a helper starlark module `repositories.bzl`, which supplies a loadable macro
`npm_repositories`. This macro creates an `npm_import` for each package.

The generated repository also contains BUILD files declaring targets for the packages
listed as `dependencies` or `devDependencies` in `package.json`, so you can declare
dependencies on those packages without having to repeat version information.

Bazel will only fetch the packages which are required for the requested targets to be analyzed.
Thus it is performant to convert a very large package-lock.json file without concern for
users needing to fetch many unnecessary packages.

Typical usage:
```starlark
load("@aspect_rules_js//js:npm_import.bzl", "translate_package_lock")

# Read the package-lock.json file to automate creation of remaining npm_import rules
translate_package_lock(
    name = "npm_deps",
    package_lock = "//:package-lock.json",
)

load("@npm_deps//:repositories.bzl", "npm_repositories")

npm_repositories()
```

Next, in your BUILD files you can declare dependencies on the packages using the same external repository.

Following the same example, this might look like:

```starlark
nodejs_test(
    name = "test_test",
    data = ["@npm_deps//@types/node"],
    entry_point = "test.js",
)
```


**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="translate_package_lock-name"></a>name |  A unique name for this repository.   | <a href="https://bazel.build/docs/build-ref.html#name">Name</a> | required |  |
| <a id="translate_package_lock-package_lock"></a>package_lock |  The package-lock.json file.<br><br>        It should use the lockfileVersion 2, which is produced from npm 7 or higher.   | <a href="https://bazel.build/docs/build-ref.html#labels">Label</a> | required |  |
| <a id="translate_package_lock-repo_mapping"></a>repo_mapping |  A dictionary from local repository name to global repository name. This allows controls over workspace dependency resolution for dependencies of this repository.&lt;p&gt;For example, an entry <code>"@foo": "@bar"</code> declares that, for any time this repository depends on <code>@foo</code> (such as a dependency on <code>@foo//some:target</code>, it should actually resolve that dependency within globally-declared <code>@bar</code> (<code>@bar//some:target</code>).   | <a href="https://bazel.build/docs/skylark/lib/dict.html">Dictionary: String -> String</a> | required |  |


<a id="#npm_import"></a>

## npm_import

<pre>
npm_import(<a href="#npm_import-integrity">integrity</a>, <a href="#npm_import-package">package</a>, <a href="#npm_import-version">version</a>, <a href="#npm_import-deps">deps</a>, <a href="#npm_import-name">name</a>, <a href="#npm_import-patches">patches</a>)
</pre>

Import a single npm package into Bazel.

Normally you'd want to use `translate_package_lock` to import all your packages at once.
It generates `npm_import` rules.
You can create these manually if you want to have exact control.

Bazel will only fetch the given package from an external registry if the package is
required for the user-requested targets to be build/tested.
The package will be exposed as a [`nodejs_package`](./nodejs_package) rule in a repository
with a default name `@npm_[package name]-[version]`, as the default target in that repository.
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
| <a id="npm_import-deps"></a>deps |  other npm packages this one depends on.   |  <code>[]</code> |
| <a id="npm_import-name"></a>name |  the external repository generated to contain the package content. This argument may be omitted to get the default name documented above.   |  <code>None</code> |
| <a id="npm_import-patches"></a>patches |  patch files to apply onto the downloaded npm package. Paths in the patch file must start with <code>extract_tmp/package</code> where <code>package</code> is the top-level folder in the archive on npm.   |  <code>[]</code> |


