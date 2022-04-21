<!-- Generated with Stardoc: http://skydoc.bazel.build -->

wrapper macro for npm_import repository rule

<a id="#npm_import"></a>

## npm_import

<pre>
npm_import(<a href="#npm_import-name">name</a>, <a href="#npm_import-deps">deps</a>, <a href="#npm_import-experimental_reference_deps">experimental_reference_deps</a>, <a href="#npm_import-indirect">indirect</a>, <a href="#npm_import-integrity">integrity</a>, <a href="#npm_import-link_package_guard">link_package_guard</a>,
           <a href="#npm_import-package">package</a>, <a href="#npm_import-patch_args">patch_args</a>, <a href="#npm_import-patches">patches</a>, <a href="#npm_import-repo_mapping">repo_mapping</a>, <a href="#npm_import-version">version</a>)
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
    package = "@types/node",
    version = "15.12.2",
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
load("@npm__types_node-15.2.2//:node_package.bzl", node_package_types_node = "node_package")

node_package_types_node()
```

The instantiates an `js_binary` target for this package that can be referenced by the alias
`@//link/package:npm__name` and `@//link/package:npm__@scope+name` for scoped packages.
The `npm` prefix of these alias is configurable via the `namespace` attribute.

When using `translate_pnpm_lock`, you can `link` all the npm dependencies in the lock files with:

```
load("@npm//:node_modules.bzl", "node_modules")

node_modules()
```

`translate_pnpm_lock` also creates convienence aliases in the external repository that reference
the linked `node_package` targets. For example, `@npm//name` and `@npm//@scope/name`.

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
| <a id="npm_import-link_package_guard"></a>link_package_guard |  When explictly set, check that the generated node_package() marcro         in package.bzl is called within the specified package.<br><br>        Default value of "." implies no gaurd.<br><br>        This is set by automatically when using translate_pnpm_lock via npm_import         to guard against linking the generated node_modules into the wrong         location.   | String | optional | "." |
| <a id="npm_import-package"></a>package |  Name of the npm package, such as <code>acorn</code> or <code>@types/node</code>   | String | required |  |
| <a id="npm_import-patch_args"></a>patch_args |  Arguments to pass to the patch tool.         <code>-p1</code> will usually be needed for patches generated by git.   | List of strings | optional | ["-p0"] |
| <a id="npm_import-patches"></a>patches |  Patch files to apply onto the downloaded npm package.   | <a href="https://bazel.build/docs/build-ref.html#labels">List of labels</a> | optional | [] |
| <a id="npm_import-repo_mapping"></a>repo_mapping |  A dictionary from local repository name to global repository name. This allows controls over workspace dependency resolution for dependencies of this repository.&lt;p&gt;For example, an entry <code>"@foo": "@bar"</code> declares that, for any time this repository depends on <code>@foo</code> (such as a dependency on <code>@foo//some:target</code>, it should actually resolve that dependency within globally-declared <code>@bar</code> (<code>@bar//some:target</code>).   | <a href="https://bazel.build/docs/skylark/lib/dict.html">Dictionary: String -> String</a> | required |  |
| <a id="npm_import-version"></a>version |  Version of the npm package, such as <code>8.4.0</code>   | String | required |  |


<a id="#translate_pnpm_lock"></a>

## translate_pnpm_lock

<pre>
translate_pnpm_lock(<a href="#translate_pnpm_lock-name">name</a>, <a href="#translate_pnpm_lock-dev">dev</a>, <a href="#translate_pnpm_lock-no_optional">no_optional</a>, <a href="#translate_pnpm_lock-package">package</a>, <a href="#translate_pnpm_lock-patch_args">patch_args</a>, <a href="#translate_pnpm_lock-patches">patches</a>, <a href="#translate_pnpm_lock-pnpm_lock">pnpm_lock</a>, <a href="#translate_pnpm_lock-prod">prod</a>,
                    <a href="#translate_pnpm_lock-repo_mapping">repo_mapping</a>)
</pre>

Repository rule to generate npm_import rules from pnpm lock file.

The pnpm lockfile format includes all the information needed to define npm_import rules,
including the integrity hash, as calculated by the package manager.

For more details see, https://github.com/pnpm/pnpm/blob/main/packages/lockfile-types/src/index.ts.

Instead of manually declaring the `npm_imports`, this helper generates an external repository
containing a helper starlark module `repositories.bzl`, which supplies a loadable macro
`npm_repositories`. This macro creates an `npm_import` for each package.

The generated repository also contains BUILD files declaring targets for the packages
listed as `dependencies` or `devDependencies` in `package.json`, so you can declare
dependencies on those packages without having to repeat version information.

Bazel will only fetch the packages which are required for the requested targets to be analyzed.
Thus it is performant to convert a very large package-lock.json file without concern for
users needing to fetch many unnecessary packages.

**Setup**

In `WORKSPACE`, call the repository rule pointing to your package-lock.json file:

```starlark
load("@aspect_rules_js//js:npm_import.bzl", "translate_pnpm_lock")

# Read the pnpm-lock.json file to automate creation of remaining npm_import rules
translate_pnpm_lock(
    # Creates a new repository named "@npm_deps"
    name = "npm_deps",
    pnpm_lock = "//:pnpm-lock.json",
)
```

Next, there are two choices, either load from the generated repo or check in the generated file.
The tradeoffs are similar to
[this rules_python thread](https://github.com/bazelbuild/rules_python/issues/608).

1. Immediately load from the generated `repositories.bzl` file in `WORKSPACE`.
This is similar to the 
[`pip_parse`](https://github.com/bazelbuild/rules_python/blob/main/docs/pip.md#pip_parse)
rule in rules_python for example.
It has the advantage of also creating aliases for simpler dependencies that don't require
spelling out the version of the packages.
However it causes Bazel to eagerly evaluate the `translate_pnpm_lock` rule for every build,
even if the user didn't ask for anything JavaScript-related.

```starlark
load("@npm_deps//:repositories.bzl", "npm_repositories")

npm_repositories()
```

In BUILD files, declare dependencies on the packages using the same external repository.

Following the same example, this might look like:

```starlark
js_test(
    name = "test_test",
    data = ["@npm_deps//@types/node"],
    entry_point = "test.js",
)
```

2. Check in the `repositories.bzl` file to version control, and load that instead.
This makes it easier to ship a ruleset that has its own npm dependencies, as users don't
have to install those dependencies. It also avoids eager-evaluation of `translate_pnpm_lock`
for builds that don't need it.
This is similar to the [`update-repos`](https://github.com/bazelbuild/bazel-gazelle#update-repos)
approach from bazel-gazelle.

In a BUILD file, use a rule like
[write_source_files](https://github.com/aspect-build/bazel-lib/blob/main/docs/write_source_files.md)
to copy the generated file to the repo and test that it stays updated:

```starlark
write_source_files(
    name = "update_repos",
    files = {
        "repositories.bzl": "@npm_deps//:repositories.bzl",
    },
)
```

Then in `WORKSPACE`, load from that checked-in copy or instruct your users to do so.
In this case, the aliases are not created, so you get only the `npm_import` behavior
and must depend on packages with their versioned label like `@npm__types_node-15.12.2`.


**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="translate_pnpm_lock-name"></a>name |  A unique name for this repository.   | <a href="https://bazel.build/docs/build-ref.html#name">Name</a> | required |  |
| <a id="translate_pnpm_lock-dev"></a>dev |  If true, only install devDependencies   | Boolean | optional | False |
| <a id="translate_pnpm_lock-no_optional"></a>no_optional |  If true, optionalDependencies are not installed   | Boolean | optional | False |
| <a id="translate_pnpm_lock-package"></a>package |  The package to "link" the generated npm dependencies to. By default, the package of the pnpm_lock         target is used.   | String | optional | "." |
| <a id="translate_pnpm_lock-patch_args"></a>patch_args |  A map of package names or package names with their version (e.g., "my-package" or "my-package@v1.2.3")         to a label list arguments to pass to the patch tool. Defaults to -p0, but -p1 will         usually be needed for patches generated by git. If patch args exists for a package         as well as a package version, then the version-specific args will be appended to the args for the package.   | <a href="https://bazel.build/docs/skylark/lib/dict.html">Dictionary: String -> List of strings</a> | optional | {} |
| <a id="translate_pnpm_lock-patches"></a>patches |  A map of package names or package names with their version (e.g., "my-package" or "my-package@v1.2.3")         to a label list of patches to apply to the downloaded npm package. Paths in the patch         file must start with <code>extract_tmp/package</code> where <code>package</code> is the top-level folder in         the archive on npm. If the version is left out of the package name, the patch will be         applied to every version of the npm package.   | <a href="https://bazel.build/docs/skylark/lib/dict.html">Dictionary: String -> List of strings</a> | optional | {} |
| <a id="translate_pnpm_lock-pnpm_lock"></a>pnpm_lock |  The pnpm-lock.json file.   | <a href="https://bazel.build/docs/build-ref.html#labels">Label</a> | required |  |
| <a id="translate_pnpm_lock-prod"></a>prod |  If true, only install dependencies   | Boolean | optional | False |
| <a id="translate_pnpm_lock-repo_mapping"></a>repo_mapping |  A dictionary from local repository name to global repository name. This allows controls over workspace dependency resolution for dependencies of this repository.&lt;p&gt;For example, an entry <code>"@foo": "@bar"</code> declares that, for any time this repository depends on <code>@foo</code> (such as a dependency on <code>@foo//some:target</code>, it should actually resolve that dependency within globally-declared <code>@bar</code> (<code>@bar//some:target</code>).   | <a href="https://bazel.build/docs/skylark/lib/dict.html">Dictionary: String -> String</a> | required |  |


