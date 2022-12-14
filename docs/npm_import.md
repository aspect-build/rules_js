<!-- Generated with Stardoc: http://skydoc.bazel.build -->

Repository rules to fetch third-party npm packages

Load these with,

```starlark
load("@aspect_rules_js//npm:npm_import.bzl", "npm_translate_lock", "npm_import")
```

These use Bazel's downloader to fetch the packages.
You can use this to redirect all fetches through a store like Artifactory.

See &lt;https://blog.aspect.dev/configuring-bazels-downloader&gt; for more info about how it works
and how to configure it.

[`npm_translate_lock`](#npm_translate_lock) is the primary user-facing API.
It uses the lockfile format from [pnpm](https://pnpm.io/motivation) because it gives us reliable
semantics for how to dynamically lay out `node_modules` trees on disk in bazel-out.

To create `pnpm-lock.yaml`, consider using [`pnpm import`](https://pnpm.io/cli/import)
to preserve the versions pinned by your existing `package-lock.json` or `yarn.lock` file.

If you don't have an existing lock file, you can run `npx pnpm install --lockfile-only`.

Advanced users may want to directly fetch a package from npm rather than start from a lockfile.
[`npm_import`](#npm_import) does this.


<a id="npm_import"></a>

## npm_import

<pre>
npm_import(<a href="#npm_import-name">name</a>, <a href="#npm_import-package">package</a>, <a href="#npm_import-version">version</a>, <a href="#npm_import-deps">deps</a>, <a href="#npm_import-extra_build_content">extra_build_content</a>, <a href="#npm_import-transitive_closure">transitive_closure</a>, <a href="#npm_import-root_package">root_package</a>,
           <a href="#npm_import-link_workspace">link_workspace</a>, <a href="#npm_import-link_packages">link_packages</a>, <a href="#npm_import-lifecycle_hooks">lifecycle_hooks</a>, <a href="#npm_import-lifecycle_hooks_execution_requirements">lifecycle_hooks_execution_requirements</a>,
           <a href="#npm_import-lifecycle_hooks_env">lifecycle_hooks_env</a>, <a href="#npm_import-integrity">integrity</a>, <a href="#npm_import-url">url</a>, <a href="#npm_import-commit">commit</a>, <a href="#npm_import-patch_args">patch_args</a>, <a href="#npm_import-patches">patches</a>, <a href="#npm_import-custom_postinstall">custom_postinstall</a>,
           <a href="#npm_import-npm_auth">npm_auth</a>, <a href="#npm_import-npm_auth_basic">npm_auth_basic</a>, <a href="#npm_import-npm_auth_username">npm_auth_username</a>, <a href="#npm_import-npm_auth_password">npm_auth_password</a>, <a href="#npm_import-bins">bins</a>, <a href="#npm_import-run_lifecycle_hooks">run_lifecycle_hooks</a>,
           <a href="#npm_import-lifecycle_hooks_no_sandbox">lifecycle_hooks_no_sandbox</a>, <a href="#npm_import-kwargs">kwargs</a>)
</pre>

Import a single npm package into Bazel.

Normally you'd want to use `npm_translate_lock` to import all your packages at once.
It generates `npm_import` rules.
You can create these manually if you want to have exact control.

Bazel will only fetch the given package from an external registry if the package is
required for the user-requested targets to be build/tested.

This is a repository rule, which should be called from your `WORKSPACE` file
or some `.bzl` file loaded from it. For example, with this code in `WORKSPACE`:

```starlark
npm_import(
    name = "npm__at_types_node_15.12.2",
    package = "@types/node",
    version = "15.12.2",
    integrity = "sha512-zjQ69G564OCIWIOHSXyQEEDpdpGl+G348RAKY0XXy9Z5kU9Vzv1GMNnkar/ZJ8dzXB3COzD9Mo9NtRZ4xfgUww==",
)
```

&gt; This is similar to Bazel rules in other ecosystems named "_import" like
&gt; `apple_bundle_import`, `scala_import`, `java_import`, and `py_import`.
&gt; `go_repository` is also a model for this rule.

The name of this repository should contain the version number, so that multiple versions of the same
package don't collide.
(Note that the npm ecosystem always supports multiple versions of a library depending on where
it is required, unlike other languages like Go or Python.)

To consume the downloaded package in rules, it must be "linked" into the link package in the
package's `BUILD.bazel` file:

```
load("@npm__at_types_node__15.12.2__links//:defs.bzl", npm_link_types_node = "npm_link_imported_package")

npm_link_types_node(name = "node_modules")
```

This links `@types/node` into the `node_modules` of this package with the target name `:node_modules/@types/node`.

A `:node_modules/@types/node/dir` filegroup target is also created that provides the the directory artifact of the npm package.
This target can be used to create entry points for binary target or to access files within the npm package.

NB: You can choose any target name for the link target but we recommend using the `node_modules/@scope/name` and
`node_modules/name` convention for readability.

When using `npm_translate_lock`, you can link all the npm dependencies in the lock file for a package:

```
load("@npm//:defs.bzl", "npm_link_all_packages")

npm_link_all_packages(name = "node_modules")
```

This creates `:node_modules/name` and `:node_modules/@scope/name` targets for all direct npm dependencies in the package.
It also creates `:node_modules/name/dir` and `:node_modules/@scope/name/dir` filegroup targets that provide the the directory artifacts of their npm packages.
These target can be used to create entry points for binary target or to access files within the npm package.

If you have a mix of `npm_link_all_packages` and `npm_link_imported_package` functions to call you can pass the
`npm_link_imported_package` link functions to the `imported_links` attribute of `npm_link_all_packages` to link
them all in one call. For example,

```
load("@npm//:defs.bzl", "npm_link_all_packages")
load("@npm__at_types_node__15.12.2__links//:defs.bzl", npm_link_types_node = "npm_link_imported_package")

npm_link_all_packages(
    name = "node_modules",
    imported_links = [
        npm_link_types_node,
    ]
)
```

This has the added benefit of adding the `imported_links` to the convienence `:node_modules` target which
includes all direct dependencies in that package.

NB: You can pass an name to npm_link_all_packages and this will change the targets generated to "{name}/@scope/name" and
"{name}/name". We recommend using "node_modules" as the convention for readability.

To change the proxy URL we use to fetch, configure the Bazel downloader:

1. Make a file containing a rewrite rule like

    `rewrite (registry.nodejs.org)/(.*) artifactory.build.internal.net/artifactory/$1/$2`

1. To understand the rewrites, see [UrlRewriterConfig] in Bazel sources.

1. Point bazel to the config with a line in .bazelrc like
common --experimental_downloader_config=.bazel_downloader_config

Read more about the downloader config: &lt;https://blog.aspect.dev/configuring-bazels-downloader&gt;

[UrlRewriterConfig]: https://github.com/bazelbuild/bazel/blob/4.2.1/src/main/java/com/google/devtools/build/lib/bazel/repository/downloader/UrlRewriterConfig.java#L66


**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="npm_import-name"></a>name |  Name for this repository rule   |  none |
| <a id="npm_import-package"></a>package |  Name of the npm package, such as <code>acorn</code> or <code>@types/node</code>   |  none |
| <a id="npm_import-version"></a>version |  Version of the npm package, such as <code>8.4.0</code>   |  none |
| <a id="npm_import-deps"></a>deps |  A dict other npm packages this one depends on where the key is the package name and value is the version   |  <code>{}</code> |
| <a id="npm_import-extra_build_content"></a>extra_build_content |  Additional content to append on the generated BUILD file at the root of the created repository, either as a string or a list of lines similar to &lt;https://github.com/bazelbuild/bazel-skylib/blob/main/docs/write_file_doc.md&gt;.   |  <code>""</code> |
| <a id="npm_import-transitive_closure"></a>transitive_closure |  A dict all npm packages this one depends on directly or transitively where the key is the package name and value is a list of version(s) depended on in the closure.   |  <code>{}</code> |
| <a id="npm_import-root_package"></a>root_package |  The root package where the node_modules virtual store is linked to. Typically this is the package that the pnpm-lock.yaml file is located when using <code>npm_translate_lock</code>.   |  <code>""</code> |
| <a id="npm_import-link_workspace"></a>link_workspace |  The workspace name where links will be created for this package.<br><br>This is typically set in rule sets and libraries that are to be consumed as external repositories so links are created in the external repository and not the user workspace.<br><br>Can be left unspecified if the link workspace is the user workspace.   |  <code>""</code> |
| <a id="npm_import-link_packages"></a>link_packages |  Dict of paths where links may be created at for this package to a list of link aliases to link as in each package. If aliases are an empty list this indicates to link as the package name.<br><br>Defaults to {} which indicates that links may be created in any package as specified by the <code>direct</code> attribute of the generated npm_link_package.   |  <code>{}</code> |
| <a id="npm_import-lifecycle_hooks"></a>lifecycle_hooks |  List of lifecycle hook <code>package.json</code> scripts to run for this package if they exist.   |  <code>[]</code> |
| <a id="npm_import-lifecycle_hooks_execution_requirements"></a>lifecycle_hooks_execution_requirements |  Execution requirements when running the lifecycle hooks.<br><br>For example:<br><br><pre><code> lifecycle_hooks_execution_requirements: ["no-sandbox', "requires-network"] </code></pre><br><br>This defaults to ["no-sandbox"] to limit the overhead of sandbox creation and copying the output TreeArtifact out of the sandbox.   |  <code>["no-sandbox"]</code> |
| <a id="npm_import-lifecycle_hooks_env"></a>lifecycle_hooks_env |  Environment variables set for the lifecycle hooks action for this npm package if there is one.<br><br>Environment variables are defined by providing an array of "key=value" entries.<br><br>For example:<br><br><pre><code> lifecycle_hooks_env: ["PREBULT_BINARY=https://downloadurl"], </code></pre>   |  <code>[]</code> |
| <a id="npm_import-integrity"></a>integrity |  Expected checksum of the file downloaded, in Subresource Integrity format. This must match the checksum of the file downloaded.<br><br>This is the same as appears in the pnpm-lock.yaml, yarn.lock or package-lock.json file.<br><br>It is a security risk to omit the checksum as remote files can change.<br><br>At best omitting this field will make your build non-hermetic.<br><br>It is optional to make development easier but should be set before shipping.   |  <code>""</code> |
| <a id="npm_import-url"></a>url |  Optional url for this package. If unset, a default npm registry url is generated from the package name and version.<br><br>May start with <code>git+ssh://</code> to indicate a git repository. For example,<br><br><pre><code> git+ssh://git@github.com/org/repo.git </code></pre><br><br>If url is configured as a git repository, the commit attribute must be set to the desired commit.   |  <code>""</code> |
| <a id="npm_import-commit"></a>commit |  Specific commit to be checked out if url is a git repository.   |  <code>""</code> |
| <a id="npm_import-patch_args"></a>patch_args |  Arguments to pass to the patch tool. <code>-p1</code> will usually be needed for patches generated by git.   |  <code>["-p0"]</code> |
| <a id="npm_import-patches"></a>patches |  Patch files to apply onto the downloaded npm package.   |  <code>[]</code> |
| <a id="npm_import-custom_postinstall"></a>custom_postinstall |  Custom string postinstall script to run on the installed npm package. Runs after any existing lifecycle hooks if <code>run_lifecycle_hooks</code> is True.   |  <code>""</code> |
| <a id="npm_import-npm_auth"></a>npm_auth |  Auth token to authenticate with npm. When using Bearer authentication.   |  <code>""</code> |
| <a id="npm_import-npm_auth_basic"></a>npm_auth_basic |  Auth token to authenticate with npm. When using Basic authentication.<br><br>This is typically the base64 encoded string "username:password".   |  <code>""</code> |
| <a id="npm_import-npm_auth_username"></a>npm_auth_username |  Auth username to authenticate with npm. When using Basic authentication.   |  <code>""</code> |
| <a id="npm_import-npm_auth_password"></a>npm_auth_password |  Auth password to authenticate with npm. When using Basic authentication.   |  <code>""</code> |
| <a id="npm_import-bins"></a>bins |  Dictionary of <code>node_modules/.bin</code> binary files to create mapped to their node entry points.<br><br>This is typically derived from the "bin" attribute in the package.json file of the npm package being linked.<br><br>For example:<br><br><pre><code> bins = {     "foo": "./foo.js",     "bar": "./bar.js", } </code></pre><br><br>In the future, this field may be automatically populated by npm_translate_lock from information in the pnpm lock file. That feature is currently blocked on https://github.com/pnpm/pnpm/issues/5131.   |  <code>{}</code> |
| <a id="npm_import-run_lifecycle_hooks"></a>run_lifecycle_hooks |  If True, runs <code>preinstall</code>, <code>install</code>, <code>postinstall</code> and 'prepare' lifecycle hooks declared in this package.<br><br>Deprecated. Use <code>lifecycle_hooks</code> instead.   |  <code>False</code> |
| <a id="npm_import-lifecycle_hooks_no_sandbox"></a>lifecycle_hooks_no_sandbox |  If True, adds "no-sandbox" to <code>lifecycle_hooks_execution_requirements</code>.<br><br>Deprecated. Add "no-sandbox" to <code>lifecycle_hooks_execution_requirements</code> instead.   |  <code>True</code> |
| <a id="npm_import-kwargs"></a>kwargs |  Internal use only   |  none |


<a id="npm_translate_lock"></a>

## npm_translate_lock

<pre>
npm_translate_lock(<a href="#npm_translate_lock-name">name</a>, <a href="#npm_translate_lock-pnpm_lock">pnpm_lock</a>, <a href="#npm_translate_lock-npm_package_lock">npm_package_lock</a>, <a href="#npm_translate_lock-yarn_lock">yarn_lock</a>, <a href="#npm_translate_lock-update_pnpm_lock">update_pnpm_lock</a>, <a href="#npm_translate_lock-npmrc">npmrc</a>,
                   <a href="#npm_translate_lock-use_home_npmrc">use_home_npmrc</a>, <a href="#npm_translate_lock-data">data</a>, <a href="#npm_translate_lock-patches">patches</a>, <a href="#npm_translate_lock-patch_args">patch_args</a>, <a href="#npm_translate_lock-custom_postinstalls">custom_postinstalls</a>, <a href="#npm_translate_lock-prod">prod</a>,
                   <a href="#npm_translate_lock-public_hoist_packages">public_hoist_packages</a>, <a href="#npm_translate_lock-dev">dev</a>, <a href="#npm_translate_lock-no_optional">no_optional</a>, <a href="#npm_translate_lock-run_lifecycle_hooks">run_lifecycle_hooks</a>, <a href="#npm_translate_lock-lifecycle_hooks">lifecycle_hooks</a>,
                   <a href="#npm_translate_lock-lifecycle_hooks_envs">lifecycle_hooks_envs</a>, <a href="#npm_translate_lock-lifecycle_hooks_exclude">lifecycle_hooks_exclude</a>,
                   <a href="#npm_translate_lock-lifecycle_hooks_execution_requirements">lifecycle_hooks_execution_requirements</a>, <a href="#npm_translate_lock-lifecycle_hooks_no_sandbox">lifecycle_hooks_no_sandbox</a>, <a href="#npm_translate_lock-bins">bins</a>,
                   <a href="#npm_translate_lock-verify_node_modules_ignored">verify_node_modules_ignored</a>, <a href="#npm_translate_lock-quiet">quiet</a>, <a href="#npm_translate_lock-link_workspace">link_workspace</a>, <a href="#npm_translate_lock-pnpm_version">pnpm_version</a>, <a href="#npm_translate_lock-package_json">package_json</a>,
                   <a href="#npm_translate_lock-warn_on_unqualified_tarball_url">warn_on_unqualified_tarball_url</a>, <a href="#npm_translate_lock-kwargs">kwargs</a>)
</pre>

Repository rule to generate npm_import rules from pnpm lock file or from a package.json and yarn/npm lock file.

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
Thus it is performant to convert a very large pnpm-lock.yaml file without concern for
users needing to fetch many unnecessary packages.

**Compatabilty with pnpm***

The `node_modules` tree laid out by `rules_js` should be bug-for-bug compatible with the `node_modules` tree that
pnpm lays out with [hoisting](https://pnpm.io/npmrc#hoist) disabled (`hoist=false` set in your `.npmrc`).

We recommend adding `hoist=false` to your `.npmrc`:

```
echo "hoist=false" &gt;&gt; .npmrc
```

This will prevent pnpm from creating the hidden `node_modules/.pnpm/node_modules` folder with hoisted
dependencies which allow for packages to depend on "phantom" undeclared dependencies. In most cases,
if you hit import/require runtime failures in 3rd party npm packages when using `rules_js`, the failure
will be reproducible with pnpm outside of Bazel when hoisting is disabled.

`rules_js` does not and will not support pnpm "phantom" [hoisting](https://pnpm.io/npmrc#hoist) which allows for
packages to depend on undeclared dependencies. All dependencies between packages must be declared under
`rules_js` in order to support lazy fetching and lazy linking of npm dependencies.

If a 3rd party npm package is relying on "phantom" dependencies to work, the recommended fix for `rules_js` is to
use [pnpm.packageExtensions](https://pnpm.io/package_json#pnpmpackageextensions) in your `package.json` to add the
missing `dependencies` or `peerDependencies`. For example,
https://github.com/aspect-build/rules_js/blob/a8c192eed0e553acb7000beee00c60d60a32ed82/package.json#L12.

NB: We plan to add support for the `.npmrc` `public-hoist-pattern` setting to `rules_js` in a future release.
For now, you can emulate public-hoist-pattern in `rules_js` using the `public_hoist_packages` attribute
of `npm_translate_lock`.

**Setup**

In `WORKSPACE`, call the repository rule pointing to your pnpm-lock.yaml file:

```starlark
load("@aspect_rules_js//npm:npm_import.bzl", "npm_translate_lock")

# Read the pnpm-lock.yaml file to automate creation of remaining npm_import rules
npm_translate_lock(
    # Creates a new repository named "@npm_deps"
    name = "npm_deps",
    pnpm_lock = "//:pnpm-lock.yaml",
    # Recommended attribute that also checks the .bazelignore file
    verify_node_modules_ignored = "//:.bazelignore",
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
However it causes Bazel to eagerly evaluate the `npm_translate_lock` rule for every build,
even if the user didn't ask for anything JavaScript-related.

```starlark
# Following our example above, we named this "npm_deps"
load("@npm_deps//:repositories.bzl", "npm_repositories")

npm_repositories()
```

2. Check in the `repositories.bzl` file to version control, and load that instead.
This makes it easier to ship a ruleset that has its own npm dependencies, as users don't
have to install those dependencies. It also avoids eager-evaluation of `npm_translate_lock`
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

This macro creates a "pnpm" repository. `rules_js` currently only uses this repository
when npm_package_lock or yarn_lock are used rather than pnpm_lock.
Set pnpm_version to None to inhibit this repository creation.

The user can create a "pnpm" repository before calling this in order to override.


**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="npm_translate_lock-name"></a>name |  The repository rule name   |  none |
| <a id="npm_translate_lock-pnpm_lock"></a>pnpm_lock |  The <code>pnpm-lock.yaml</code> file.   |  <code>None</code> |
| <a id="npm_translate_lock-npm_package_lock"></a>npm_package_lock |  The <code>package-lock.json</code> file written by <code>npm install</code>.<br><br>Only one of [npm_package_lock, yarn_lock] may be set.   |  <code>None</code> |
| <a id="npm_translate_lock-yarn_lock"></a>yarn_lock |  The <code>yarn.lock</code> file written by <code>yarn install</code>.<br><br>Only one of [npm_package_lock, yarn_lock] may be set.   |  <code>None</code> |
| <a id="npm_translate_lock-update_pnpm_lock"></a>update_pnpm_lock |  When True, the pnpm lock file wil be updated automatically when any of its inputs have changed since the last update.<br><br>Defaults to False unless <code>npm_package_lock</code> or <code>yarn_lock</code> are set, in which case it defaults to True.<br><br>A <code>.aspect/rules/external_repository_action_cache/npm_translate_lock_&lt;hash&gt;</code> file will be created and used to determine when the <code>pnpm-lock.yaml</code> file should be updated. This file should be checked into the source control along with the <code>pnpm-lock.yaml</code> file.<br><br>When the <code>pnpm-lock.yaml</code> file needs updating, <code>npm_translate_lock</code> will run either <code>pnpm install --lockfile-only</code> or <code>pnpm import</code>. The latter will be used if there is a <code>npm_package_lock</code> or <code>yarn_lock</code> specified.<br><br>To update the <code>pnpm-lock.yaml</code> file manually either [install pnpm](https://pnpm.io/installation) and run <code>pnpm install --lockfile-only</code> or <code>pnpm import</code> use the Bazel-managed pnpm by running <code>bazel run -- @pnpm//:pnpm --dir $PWD install --lockfile-only</code> or <code>bazel run -- @pnpm//:pnpm --dir $PWD import</code><br><br>If the ASPECT_RULES_JS_FROZEN_PNPM_LOCK environment variable is set and <code>update_pnpm_lock</code> is True, the build will fail if the pnpm lock file needs updating. It is recommended to set this environment variable on CI when <code>update_pnpm_lock</code> is True.   |  <code>None</code> |
| <a id="npm_translate_lock-npmrc"></a>npmrc |  The <code>.npmrc</code> file, if any, to use.<br><br>When set, the <code>.npmrc</code> file specified is parsed and npm auth tokens and basic authentication configuration specified in the file are passed to the Bazel downloader for authentication with private npm registries.<br><br>In a future release, pnpm settings such as public-hoist-patterns will be used.   |  <code>None</code> |
| <a id="npm_translate_lock-use_home_npmrc"></a>use_home_npmrc |  Use the <code>$HOME/.npmrc</code> file (or <code>$USERPROFILE/.npmrc</code> when on Windows) if it exists.<br><br>Settings from home <code>.npmrc</code> are merged with settings loaded from the <code>.npmrc</code> file specified in the <code>npmrc</code> attribute, if any. Where there are conflicting settings, the home <code>.npmrc</code> values will take precedence.<br><br>WARNING: The repository rule will not be invalidated by changes to the home <code>.npmrc</code> file since there is no way to specify this file as an input to the repository rule. If changes are made to the home <code>.npmrc</code> you can force the repository rule to re-run and pick up the changes by running: <code>bazel sync --only={name}</code> where <code>name</code> is the name of the <code>npm_translate_lock</code> you want to re-run.<br><br>Because of the repository rule invalidation issue, using the home <code>.npmrc</code> is not recommended. <code>.npmrc</code> settings should generally go in the <code>npmrc</code> in your repository so they are shared by all developers. The home <code>.npmrc</code> should be reserved for authentication settings for private npm repositories.   |  <code>None</code> |
| <a id="npm_translate_lock-data"></a>data |  Data files required by this repository rule when auto-updating the pnpm lock file.<br><br>Only needed when <code>update_pnpm_lock</code> is True.<br><br>This should include the <code>pnpm-workspace.yaml</code> file as well as all <code>package.json</code> files in the pnpm workspace. The pnpm lock file update will fail if <code>data</code> is missing any files required to run <code>pnpm install --lockfile-only</code> or <code>pnpm import</code>.<br><br>To list all local <code>package.json</code> files that pnpm needs to read, you can run <code>pnpm recursive ls --depth -1 --porcelain</code>.   |  <code>[]</code> |
| <a id="npm_translate_lock-patches"></a>patches |  A map of package names or package names with their version (e.g., "my-package" or "my-package@v1.2.3") to a label list of patches to apply to the downloaded npm package. Paths in the patch file must be relative to the root of the package. If the version is left out of the package name, the patch will be applied to every version of the npm package.<br><br>For example,<br><br><pre><code> patches = {     "@foo/bar": ["//:patches/foo+bar.patch"],     "fum@0.0.1": ["//:patches/fum@0.0.1.patch"], }, </code></pre><br><br>List of patches are additive when there are multiple matches for a package. More specific matches are appended to previous matches.   |  <code>{}</code> |
| <a id="npm_translate_lock-patch_args"></a>patch_args |  A map of package names or package names with their version (e.g., "my-package" or "my-package@v1.2.3") to a label list arguments to pass to the patch tool. Defaults to -p0, but -p1 will usually be needed for patches generated by git. If patch args exists for a package as well as a package version, then the version-specific args will be appended to the args for the package.<br><br><pre><code> patch_args = {     "*": ["-p1"]     "@foo/bar": ["-p0"]     "fum@0.0.1": ["-p2"] }, </code></pre><br><br>List of patch args are not additive. More specific name matches take precedence.   |  <code>{"*": ["-p0"]}</code> |
| <a id="npm_translate_lock-custom_postinstalls"></a>custom_postinstalls |  A map of package names or package names with their version (e.g., "my-package" or "my-package@v1.2.3") to a custom postinstall script to apply to the downloaded npm package after its lifecycle scripts runs. If the version is left out of the package name, the script will run on every version of the npm package. If a custom postinstall scripts exists for a package as well as for a specific version, the script for the versioned package will be appended with <code>&&</code> to the non-versioned package script.<br><br>For example,<br><br><pre><code> custom_postinstalls = {     "@foo/bar": "echo something &gt; somewhere.txt",     "fum@0.0.1": "echo something_else &gt; somewhere_else.txt", }, </code></pre><br><br>Custom postinstalls are additive and joined with <code> && </code> when there are multiple matches for a package. More specific matches are appended to previous matches.   |  <code>{}</code> |
| <a id="npm_translate_lock-prod"></a>prod |  If True, only install <code>dependencies</code> but not <code>devDependencies</code>.   |  <code>False</code> |
| <a id="npm_translate_lock-public_hoist_packages"></a>public_hoist_packages |  A map of package names or package names with their version (e.g., "my-package" or "my-package@v1.2.3") to a list of Bazel packages in which to hoist the package to the top-level of the node_modules tree when linking.<br><br>This is similar to setting https://pnpm.io/npmrc#public-hoist-pattern in an .npmrc file outside of Bazel, however, wild-cards are not yet supported and npm_translate_lock will fail if there are multiple versions of a package that are to be hoisted.<br><br><pre><code> public_hoist_packages = {     "@foo/bar": [""] # link to the root package in the WORKSPACE     "fum@0.0.1": ["some/sub/package"] }, </code></pre><br><br>List of public hoist packages are additive when there are multiple matches for a package. More specific matches are appended to previous matches.   |  <code>{}</code> |
| <a id="npm_translate_lock-dev"></a>dev |  If True, only install <code>devDependencies</code>   |  <code>False</code> |
| <a id="npm_translate_lock-no_optional"></a>no_optional |  If True, <code>optionalDependencies</code> are not installed.<br><br>Currently <code>npm_translate_lock</code> behaves differently from pnpm in that is downloads all <code>optionaDependencies</code> while pnpm doesn't download <code>optionalDependencies</code> that are not needed for the platform pnpm is run on. See https://github.com/pnpm/pnpm/pull/3672 for more context.   |  <code>False</code> |
| <a id="npm_translate_lock-run_lifecycle_hooks"></a>run_lifecycle_hooks |  Sets <code>"*": ["preinstall", "install", "postinstall"]</code> in <code>lifecycle_hooks</code> if <code>*</code> not already set.   |  <code>True</code> |
| <a id="npm_translate_lock-lifecycle_hooks"></a>lifecycle_hooks |  A dict of package names to list of lifecycle hooks to run for that package.<br><br>By default the <code>preinstall</code>, <code>install</code> and <code>postinstall</code> hooks are run if they exist. This attribute allows the default to be overridden for packages to run <code>prepare</code> for example,<br><br><pre><code> lifecycle_hooks = {     "*": ["preinstall", "install", "postinstall"],     "@kubernetes/client-node": ["prepare"],     "fum@0.0.1": ["postinstall"], } </code></pre><br><br>List of hooks are not additive. More specific name matches take precedence. In the above example, only the <code>prepare</code> lifecycle hook will be run for the <code>@kubernetes/client-node</code> npm package.   |  <code>{}</code> |
| <a id="npm_translate_lock-lifecycle_hooks_envs"></a>lifecycle_hooks_envs |  Environment variables set for the lifecycle hooks actions on npm packages. The environment variables can be defined per package by package name or globally using "*". Variables are declared as key/value pairs of the form "key=value".<br><br>For example:<br><br><pre><code> lifecycle_hooks_envs: {     "*": ["GLOBAL_KEY1=value1", "GLOBAL_KEY2=value2"],     "@foo/bar": ["GLOBAL_KEY2=", "PREBULT_BINARY=http://downloadurl"], } </code></pre><br><br>Execution variables are additive when there are multiple matches for a package. More specific matches are appended to previous matches.<br><br>In the above example, <code>@foo/bar</code> will have the environment variables <code>["GLOBAL_KEY1=value1", "GLOBAL_KEY2=value2", "GLOBAL_KEY2=", "PREBULT_BINARY=http://downloadurl"]</code> set where the 2nd <code>GLOBAL_KEY</code> environment value will override the first.   |  <code>{}</code> |
| <a id="npm_translate_lock-lifecycle_hooks_exclude"></a>lifecycle_hooks_exclude |  A list of package names or package names with their version (e.g., "my-package" or "my-package@v1.2.3") to not run any lifecycle hooks on.<br><br>Equivalent to adding <code>&lt;value&gt;: []</code> to <code>lifecycle_hooks</code>.   |  <code>[]</code> |
| <a id="npm_translate_lock-lifecycle_hooks_execution_requirements"></a>lifecycle_hooks_execution_requirements |  Execution requirements applied to the preinstall, install and postinstall lifecycle hooks on npm packages.<br><br>The execution requirements can be defined per package by package name or globally using "*". For example,<br><br><pre><code> lifecycle_hooks_execution_requirements = {     "*": ["no-sandbox"],     "@foo/bar": [], # @foo/bar lifecycle hooks action will be run in the sandbox     "fum@0.0.1": ["no-sandbox", "no-remote-exec"], } </code></pre><br><br>Execution requirements are not additive. More specific name matches take precedence.   |  <code>{}</code> |
| <a id="npm_translate_lock-lifecycle_hooks_no_sandbox"></a>lifecycle_hooks_no_sandbox |  If True, a "no-sandbox" execution requirement is added to all lifecycle hooks unless overridden by <code>lifecycle_hooks_execution_requirements</code>.<br><br>Equivalent to adding <code>"*": ["no-sandbox"]</code> to <code>lifecycle_hooks_execution_requirements</code>.<br><br>This defaults to True to limit the overhead of sandbox creation and copying the output TreeArtifacts out of the sandbox.   |  <code>True</code> |
| <a id="npm_translate_lock-bins"></a>bins |  Binary files to create in <code>node_modules/.bin</code> for packages in this lock file.<br><br>For a given package, this is typically derived from the "bin" attribute in the package.json file of that package.<br><br>For example:<br><br><pre><code> bins = {     "@foo/bar": {         "foo": "./foo.js",         "bar": "./bar.js"     }, } </code></pre><br><br>Dicts of bins not additive. More specific name matches take precedence.<br><br>In the future, this field may be automatically populated from information in the pnpm lock file. That feature is currently blocked on https://github.com/pnpm/pnpm/issues/5131.   |  <code>{}</code> |
| <a id="npm_translate_lock-verify_node_modules_ignored"></a>verify_node_modules_ignored |  node_modules folders in the source tree should be ignored by Bazel.<br><br>This points to a <code>.bazelignore</code> file to verify that all nested node_modules directories pnpm will create are listed.<br><br>See https://github.com/bazelbuild/bazel/issues/8106   |  <code>None</code> |
| <a id="npm_translate_lock-quiet"></a>quiet |  Set to False to print info logs and output stdout & stderr of pnpm lock update actions to the console.   |  <code>True</code> |
| <a id="npm_translate_lock-link_workspace"></a>link_workspace |  The workspace name where links will be created for the packages in this lock file.<br><br>This is typically set in rule sets and libraries that vendor the starlark generated by npm_translate_lock so the link_workspace passed to npm_import is set correctly so that links are created in the external repository and not the user workspace.<br><br>Can be left unspecified if the link workspace is the user workspace.   |  <code>None</code> |
| <a id="npm_translate_lock-pnpm_version"></a>pnpm_version |  pnpm version to use when generating the @pnpm repository. Set to None to not create this repository.   |  <code>"7.17.1"</code> |
| <a id="npm_translate_lock-package_json"></a>package_json |  Deprecated.<br><br>Add all <code>package.json</code> files that are part of the workspace to <code>data</code> instead.   |  <code>None</code> |
| <a id="npm_translate_lock-warn_on_unqualified_tarball_url"></a>warn_on_unqualified_tarball_url |  Deprecated. Will be removed in next major release.   |  <code>None</code> |
| <a id="npm_translate_lock-kwargs"></a>kwargs |  Internal use only   |  none |


<a id="pnpm_repository"></a>

## pnpm_repository

<pre>
pnpm_repository(<a href="#pnpm_repository-name">name</a>, <a href="#pnpm_repository-pnpm_version">pnpm_version</a>)
</pre>

Import https://npmjs.com/package/pnpm and provide a js_binary to run the tool.

Useful as a way to run exactly the same pnpm as Bazel does, for example with:
bazel run -- @pnpm//:pnpm --dir $PWD


**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="pnpm_repository-name"></a>name |  name of the resulting external repository   |  none |
| <a id="pnpm_repository-pnpm_version"></a>pnpm_version |  version of pnpm, see https://www.npmjs.com/package/pnpm?activeTab=versions   |  <code>"7.17.1"</code> |


