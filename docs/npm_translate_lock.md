<!-- Generated with Stardoc: http://skydoc.bazel.build -->

Repository rule to fetch npm packages for a lockfile.

Load this with,

```starlark
load("@aspect_rules_js//npm:repositories.bzl", "npm_translate_lock")
```

These use Bazel's downloader to fetch the packages.
You can use this to redirect all fetches through a store like Artifactory.

See <https://blog.aspect.dev/configuring-bazels-downloader> for more info about how it works
and how to configure it.

[`npm_translate_lock`](#npm_translate_lock) is the primary user-facing API.
It uses the lockfile format from [pnpm](https://pnpm.io/motivation) because it gives us reliable
semantics for how to dynamically lay out `node_modules` trees on disk in bazel-out.

To create `pnpm-lock.yaml`, consider using [`pnpm import`](https://pnpm.io/cli/import)
to preserve the versions pinned by your existing `package-lock.json` or `yarn.lock` file.

If you don't have an existing lock file, you can run `npx pnpm install --lockfile-only`.

Advanced users may want to directly fetch a package from npm rather than start from a lockfile,
[`npm_import`](./npm_import) does this.

<a id="list_patches"></a>

## list_patches

<pre>
list_patches(<a href="#list_patches-name">name</a>, <a href="#list_patches-out">out</a>, <a href="#list_patches-include_patterns">include_patterns</a>, <a href="#list_patches-exclude_patterns">exclude_patterns</a>)
</pre>

Write a file containing a list of all patches in the current folder to the source tree.

Use this together with the `verify_patches` attribute of `npm_translate_lock` to verify
that all patches in a patch folder are included. This macro stamps a test to ensure the
file stays up to date.


**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="list_patches-name"></a>name |  Name of the target   |  none |
| <a id="list_patches-out"></a>out |  Name of file to write to the source tree. If unspecified, `name` is used   |  `None` |
| <a id="list_patches-include_patterns"></a>include_patterns |  Patterns to pass to a glob of patch files   |  `["*.diff", "*.patch"]` |
| <a id="list_patches-exclude_patterns"></a>exclude_patterns |  Patterns to ignore in a glob of patch files   |  `[]` |


<a id="npm_translate_lock"></a>

## npm_translate_lock

<pre>
npm_translate_lock(<a href="#npm_translate_lock-name">name</a>, <a href="#npm_translate_lock-pnpm_lock">pnpm_lock</a>, <a href="#npm_translate_lock-npm_package_lock">npm_package_lock</a>, <a href="#npm_translate_lock-yarn_lock">yarn_lock</a>, <a href="#npm_translate_lock-update_pnpm_lock">update_pnpm_lock</a>,
                   <a href="#npm_translate_lock-node_toolchain_prefix">node_toolchain_prefix</a>, <a href="#npm_translate_lock-yq_toolchain_prefix">yq_toolchain_prefix</a>, <a href="#npm_translate_lock-preupdate">preupdate</a>, <a href="#npm_translate_lock-npmrc">npmrc</a>, <a href="#npm_translate_lock-use_home_npmrc">use_home_npmrc</a>, <a href="#npm_translate_lock-data">data</a>,
                   <a href="#npm_translate_lock-patches">patches</a>, <a href="#npm_translate_lock-patch_args">patch_args</a>, <a href="#npm_translate_lock-custom_postinstalls">custom_postinstalls</a>, <a href="#npm_translate_lock-package_visibility">package_visibility</a>, <a href="#npm_translate_lock-prod">prod</a>,
                   <a href="#npm_translate_lock-public_hoist_packages">public_hoist_packages</a>, <a href="#npm_translate_lock-dev">dev</a>, <a href="#npm_translate_lock-no_optional">no_optional</a>, <a href="#npm_translate_lock-run_lifecycle_hooks">run_lifecycle_hooks</a>, <a href="#npm_translate_lock-lifecycle_hooks">lifecycle_hooks</a>,
                   <a href="#npm_translate_lock-lifecycle_hooks_envs">lifecycle_hooks_envs</a>, <a href="#npm_translate_lock-lifecycle_hooks_exclude">lifecycle_hooks_exclude</a>,
                   <a href="#npm_translate_lock-lifecycle_hooks_execution_requirements">lifecycle_hooks_execution_requirements</a>, <a href="#npm_translate_lock-lifecycle_hooks_no_sandbox">lifecycle_hooks_no_sandbox</a>,
                   <a href="#npm_translate_lock-lifecycle_hooks_use_default_shell_env">lifecycle_hooks_use_default_shell_env</a>, <a href="#npm_translate_lock-replace_packages">replace_packages</a>, <a href="#npm_translate_lock-bins">bins</a>,
                   <a href="#npm_translate_lock-verify_node_modules_ignored">verify_node_modules_ignored</a>, <a href="#npm_translate_lock-verify_patches">verify_patches</a>, <a href="#npm_translate_lock-quiet">quiet</a>,
                   <a href="#npm_translate_lock-external_repository_action_cache">external_repository_action_cache</a>, <a href="#npm_translate_lock-link_workspace">link_workspace</a>, <a href="#npm_translate_lock-pnpm_version">pnpm_version</a>, <a href="#npm_translate_lock-use_pnpm">use_pnpm</a>,
                   <a href="#npm_translate_lock-npm_package_target_name">npm_package_target_name</a>, <a href="#npm_translate_lock-kwargs">kwargs</a>)
</pre>

Repository macro to generate starlark code from a lock file.

In most repositories, it would be an impossible maintenance burden to manually declare all
of the [`npm_import`](./npm_import) rules. This helper generates an external repository
containing a helper starlark module `repositories.bzl`, which supplies a loadable macro
`npm_repositories`. That macro creates an `npm_import` for each package.

The generated repository also contains:

- A `defs.bzl` file containing some rules such as `npm_link_all_packages`, which are [documented here](./npm_link_all_packages.md).
- `BUILD` files declaring targets for the packages listed as `dependencies` or `devDependencies` in `package.json`,
  so you can declare dependencies on those packages without having to repeat version information.

This macro creates a `pnpm` external repository, if the user didn't create a repository named
"pnpm" prior to calling `npm_translate_lock`.
`rules_js` currently only uses this repository when `npm_package_lock` or `yarn_lock` are used.
Set `pnpm_version` to `None` to inhibit this repository creation.

For more about how to use npm_translate_lock, read [pnpm and rules_js](/docs/pnpm.md).


**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="npm_translate_lock-name"></a>name |  The repository rule name   |  none |
| <a id="npm_translate_lock-pnpm_lock"></a>pnpm_lock |  The `pnpm-lock.yaml` file.   |  `None` |
| <a id="npm_translate_lock-npm_package_lock"></a>npm_package_lock |  The `package-lock.json` file written by `npm install`.<br><br>Only one of `npm_package_lock` or `yarn_lock` may be set.   |  `None` |
| <a id="npm_translate_lock-yarn_lock"></a>yarn_lock |  The `yarn.lock` file written by `yarn install`.<br><br>Only one of `npm_package_lock` or `yarn_lock` may be set.   |  `None` |
| <a id="npm_translate_lock-update_pnpm_lock"></a>update_pnpm_lock |  When True, the pnpm lock file will be updated automatically when any of its inputs have changed since the last update.<br><br>Defaults to True when one of `npm_package_lock` or `yarn_lock` are set. Otherwise it defaults to False.<br><br>Read more: [using update_pnpm_lock](/docs/pnpm.md#update_pnpm_lock)   |  `False` |
| <a id="npm_translate_lock-node_toolchain_prefix"></a>node_toolchain_prefix |  the prefix of the node toolchain to use when generating the pnpm lockfile.   |  `"nodejs"` |
| <a id="npm_translate_lock-yq_toolchain_prefix"></a>yq_toolchain_prefix |  the prefix of the yq toolchain to use for parsing the pnpm lockfile.   |  `"yq"` |
| <a id="npm_translate_lock-preupdate"></a>preupdate |  Node.js scripts to run in this repository rule before auto-updating the pnpm lock file.<br><br>Scripts are run sequentially in the order they are listed. The working directory is set to the root of the external repository. Make sure all files required by preupdate scripts are added to the `data` attribute.<br><br>A preupdate script could, for example, transform `resolutions` in the root `package.json` file from a format that yarn understands such as `@foo/**/bar` to the equivalent `@foo/*>bar` that pnpm understands so that `resolutions` are compatible with pnpm when running `pnpm import` to update the pnpm lock file.<br><br>Only needed when `update_pnpm_lock` is True. Read more: [using update_pnpm_lock](/docs/pnpm.md#update_pnpm_lock)   |  `[]` |
| <a id="npm_translate_lock-npmrc"></a>npmrc |  The `.npmrc` file, if any, to use.<br><br>When set, the `.npmrc` file specified is parsed and npm auth tokens and basic authentication configuration specified in the file are passed to the Bazel downloader for authentication with private npm registries.<br><br>In a future release, pnpm settings such as public-hoist-patterns will be used.   |  `None` |
| <a id="npm_translate_lock-use_home_npmrc"></a>use_home_npmrc |  Use the `$HOME/.npmrc` file (or `$USERPROFILE/.npmrc` when on Windows) if it exists.<br><br>Settings from home `.npmrc` are merged with settings loaded from the `.npmrc` file specified in the `npmrc` attribute, if any. Where there are conflicting settings, the home `.npmrc` values will take precedence.<br><br>WARNING: The repository rule will not be invalidated by changes to the home `.npmrc` file since there is no way to specify this file as an input to the repository rule. If changes are made to the home `.npmrc` you can force the repository rule to re-run and pick up the changes by running: `bazel run @{name}//:sync` where `name` is the name of the `npm_translate_lock` you want to re-run.<br><br>Because of the repository rule invalidation issue, using the home `.npmrc` is not recommended. `.npmrc` settings should generally go in the `npmrc` in your repository so they are shared by all developers. The home `.npmrc` should be reserved for authentication settings for private npm repositories.   |  `None` |
| <a id="npm_translate_lock-data"></a>data |  Data files required by this repository rule when auto-updating the pnpm lock file.<br><br>Only needed when `update_pnpm_lock` is True. Read more: [using update_pnpm_lock](/docs/pnpm.md#update_pnpm_lock)   |  `[]` |
| <a id="npm_translate_lock-patches"></a>patches |  A map of package names or package names with their version (e.g., "my-package" or "my-package@v1.2.3") to a label list of patches to apply to the downloaded npm package. Multiple matches are additive.<br><br>These patches are applied after any patches in [pnpm.patchedDependencies](https://pnpm.io/next/package_json#pnpmpatcheddependencies).<br><br>Read more: [patching](/docs/pnpm.md#patching)   |  `{}` |
| <a id="npm_translate_lock-patch_args"></a>patch_args |  A map of package names or package names with their version (e.g., "my-package" or "my-package@v1.2.3") to a label list arguments to pass to the patch tool. The most specific match wins.<br><br>Read more: [patching](/docs/pnpm.md#patching)   |  `{"*": ["-p0"]}` |
| <a id="npm_translate_lock-custom_postinstalls"></a>custom_postinstalls |  A map of package names or package names with their version (e.g., "my-package" or "my-package@v1.2.3") to a custom postinstall script to apply to the downloaded npm package after its lifecycle scripts runs. If the version is left out of the package name, the script will run on every version of the npm package. If a custom postinstall scripts exists for a package as well as for a specific version, the script for the versioned package will be appended with `&&` to the non-versioned package script.<br><br>For example,<br><br><pre><code>custom_postinstalls = {&#10;    "@foo/bar": "echo something &gt; somewhere.txt",&#10;    "fum@0.0.1": "echo something_else &gt; somewhere_else.txt",&#10;},</code></pre><br><br>Custom postinstalls are additive and joined with ` && ` when there are multiple matches for a package. More specific matches are appended to previous matches.   |  `{}` |
| <a id="npm_translate_lock-package_visibility"></a>package_visibility |  A map of package names or package names with their version (e.g., "my-package" or "my-package@v1.2.3") to a visibility list to use for the package's generated node_modules link targets. Multiple matches are additive. If there are no matches then the package's generated node_modules link targets default to public visibility (`["//visibility:public"]`).   |  `{}` |
| <a id="npm_translate_lock-prod"></a>prod |  If True, only install `dependencies` but not `devDependencies`.   |  `False` |
| <a id="npm_translate_lock-public_hoist_packages"></a>public_hoist_packages |  A map of package names or package names with their version (e.g., "my-package" or "my-package@v1.2.3") to a list of Bazel packages in which to hoist the package to the top-level of the node_modules tree when linking.<br><br>This is similar to setting https://pnpm.io/npmrc#public-hoist-pattern in an .npmrc file outside of Bazel, however, wild-cards are not yet supported and npm_translate_lock will fail if there are multiple versions of a package that are to be hoisted.<br><br><pre><code>public_hoist_packages = {&#10;    "@foo/bar": [""] # link to the root package in the WORKSPACE&#10;    "fum@0.0.1": ["some/sub/package"]&#10;},</code></pre><br><br>List of public hoist packages are additive when there are multiple matches for a package. More specific matches are appended to previous matches.   |  `{}` |
| <a id="npm_translate_lock-dev"></a>dev |  If True, only install `devDependencies`   |  `False` |
| <a id="npm_translate_lock-no_optional"></a>no_optional |  If True, `optionalDependencies` are not installed.<br><br>Currently `npm_translate_lock` behaves differently from pnpm in that is downloads all `optionaDependencies` while pnpm doesn't download `optionalDependencies` that are not needed for the platform pnpm is run on. See https://github.com/pnpm/pnpm/pull/3672 for more context.   |  `False` |
| <a id="npm_translate_lock-run_lifecycle_hooks"></a>run_lifecycle_hooks |  Sets a default value for `lifecycle_hooks` if `*` not already set. Set this to `False` to disable lifecycle hooks.   |  `True` |
| <a id="npm_translate_lock-lifecycle_hooks"></a>lifecycle_hooks |  A dict of package names to list of lifecycle hooks to run for that package.<br><br>By default the `preinstall`, `install` and `postinstall` hooks are run if they exist. This attribute allows the default to be overridden for packages to run `prepare`.<br><br>List of hooks are not additive. The most specific match wins.<br><br>Read more: [lifecycles](/docs/pnpm.md#lifecycles)   |  `{}` |
| <a id="npm_translate_lock-lifecycle_hooks_envs"></a>lifecycle_hooks_envs |  Environment variables set for the lifecycle hooks actions on npm packages. The environment variables can be defined per package by package name or globally using "*". Variables are declared as key/value pairs of the form "key=value". Multiple matches are additive.<br><br>Read more: [lifecycles](/docs/pnpm.md#lifecycles)   |  `{}` |
| <a id="npm_translate_lock-lifecycle_hooks_exclude"></a>lifecycle_hooks_exclude |  A list of package names or package names with their version (e.g., "my-package" or "my-package@v1.2.3") to not run any lifecycle hooks on.<br><br>Equivalent to adding `<value>: []` to `lifecycle_hooks`.<br><br>Read more: [lifecycles](/docs/pnpm.md#lifecycles)   |  `[]` |
| <a id="npm_translate_lock-lifecycle_hooks_execution_requirements"></a>lifecycle_hooks_execution_requirements |  Execution requirements applied to the preinstall, install and postinstall lifecycle hooks on npm packages.<br><br>The execution requirements can be defined per package by package name or globally using "*".<br><br>Execution requirements are not additive. The most specific match wins.<br><br>Read more: [lifecycles](/docs/pnpm.md#lifecycles)   |  `{}` |
| <a id="npm_translate_lock-lifecycle_hooks_no_sandbox"></a>lifecycle_hooks_no_sandbox |  If True, a "no-sandbox" execution requirement is added to all lifecycle hooks unless overridden by `lifecycle_hooks_execution_requirements`.<br><br>Equivalent to adding `"*": ["no-sandbox"]` to `lifecycle_hooks_execution_requirements`.<br><br>This defaults to True to limit the overhead of sandbox creation and copying the output TreeArtifacts out of the sandbox.<br><br>Read more: [lifecycles](/docs/pnpm.md#lifecycles)   |  `True` |
| <a id="npm_translate_lock-lifecycle_hooks_use_default_shell_env"></a>lifecycle_hooks_use_default_shell_env |  The `use_default_shell_env` attribute of the lifecycle hooks actions on npm packages.<br><br>See [use_default_shell_env](https://bazel.build/rules/lib/builtins/actions#run.use_default_shell_env)<br><br>Note: [--incompatible_merge_fixed_and_default_shell_env](https://bazel.build/reference/command-line-reference#flag--incompatible_merge_fixed_and_default_shell_env) is often required and not enabled by default in Bazel < 7.0.0.<br><br>This defaults to False reduce the negative effects of `use_default_shell_env`. Requires bazel-lib >= 2.4.2.<br><br>Read more: [lifecycles](/docs/pnpm.md#lifecycles)   |  `{}` |
| <a id="npm_translate_lock-replace_packages"></a>replace_packages |  A dict of package names to npm_package targets to link instead of the sources specified in the pnpm lock file for the corresponding packages.<br><br>The injected npm_package targets may optionally contribute transitive npm package dependencies on top of the transitive dependencies specified in the pnpm lock file for their respective packages, however, these transitive dependencies must not collide with pnpm lock specified transitive dependencies.<br><br>Any patches specified for the packages will be not applied to the injected npm_package targets. They will be applied, however, to the fetches sources for their respecitve packages so they can still be useful for patching the fetched `package.json` files, which are used to determine the generated bin entries for packages.<br><br>NB: lifecycle hooks and custom_postinstall scripts, if implicitly or explicitly enabled, will be run on the injected npm_package targets. These may be disabled explicitly using the `lifecycle_hooks` attribute.   |  `{}` |
| <a id="npm_translate_lock-bins"></a>bins |  Binary files to create in `node_modules/.bin` for packages in this lock file.<br><br>For a given package, this is typically derived from the "bin" attribute in the package.json file of that package.<br><br>For example:<br><br><pre><code>bins = {&#10;    "@foo/bar": {&#10;        "foo": "./foo.js",&#10;        "bar": "./bar.js"&#10;    },&#10;}</code></pre><br><br>Dicts of bins not additive. The most specific match wins.<br><br>In the future, this field may be automatically populated from information in the pnpm lock file. That feature is currently blocked on https://github.com/pnpm/pnpm/issues/5131.<br><br>Note: Bzlmod users must use an alternative syntax due to module extensions not supporting dict-of-dict attributes:<br><br><pre><code>bins = {&#10;    "@foo/bar": [&#10;        "foo=./foo.js",&#10;        "bar=./bar.js"&#10;    ],&#10;}</code></pre>   |  `{}` |
| <a id="npm_translate_lock-verify_node_modules_ignored"></a>verify_node_modules_ignored |  node_modules folders in the source tree should be ignored by Bazel.<br><br>This points to a `.bazelignore` file to verify that all nested node_modules directories pnpm will create are listed.<br><br>See https://github.com/bazelbuild/bazel/issues/8106   |  `None` |
| <a id="npm_translate_lock-verify_patches"></a>verify_patches |  Label to a patch list file.<br><br>Use this in together with the `list_patches` macro to guarantee that all patches in a patch folder are included in the `patches` attribute.<br><br>For example:<br><br><pre><code>verify_patches = "//patches:patches.list",</code></pre><br><br>In your patches folder add a BUILD.bazel file containing. <pre><code>load("@aspect_rules_js//npm:repositories.bzl", "list_patches")&#10;&#10;list_patches(&#10;    name = "patches",&#10;    out = "patches.list",&#10;)</code></pre><br><br>Once you have created this file, you need to create an empty `patches.list` file before generating the first list. You can do this by running <pre><code>touch patches/patches.list</code></pre><br><br>Finally, write the patches file at least once to make sure all patches are listed. This can be done by running `bazel run //patches:patches_update`.<br><br>See the `list_patches` documentation for further info. NOTE: if you would like to customize the patches directory location, you can set a flag in the `.npmrc`. Here is an example of what this might look like <pre><code># Set the directory for pnpm when patching&#10;# https://github.com/pnpm/pnpm/issues/6508#issuecomment-1537242124&#10;patches-dir=bazel/js/patches</code></pre> If you do this, you will have to update the `verify_patches` path to be this path instead of `//patches` like above.   |  `None` |
| <a id="npm_translate_lock-quiet"></a>quiet |  Set to False to print info logs and output stdout & stderr of pnpm lock update actions to the console.   |  `True` |
| <a id="npm_translate_lock-external_repository_action_cache"></a>external_repository_action_cache |  The location of the external repository action cache to write to when `update_pnpm_lock` = True.   |  `".aspect/rules/external_repository_action_cache"` |
| <a id="npm_translate_lock-link_workspace"></a>link_workspace |  The workspace name where links will be created for the packages in this lock file.<br><br>This is typically set in rule sets and libraries that vendor the starlark generated by npm_translate_lock so the link_workspace passed to npm_import is set correctly so that links are created in the external repository and not the user workspace.<br><br>Can be left unspecified if the link workspace is the user workspace.   |  `None` |
| <a id="npm_translate_lock-pnpm_version"></a>pnpm_version |  pnpm version to use when generating the @pnpm repository. Set to None to not create this repository.<br><br>Can be left unspecified and the rules_js default `LATEST_PNPM_VERSION` will be used.<br><br>Use `use_pnpm` for bzlmod.   |  `"8.15.3"` |
| <a id="npm_translate_lock-use_pnpm"></a>use_pnpm |  label of the pnpm extension to use.<br><br>Can be left unspecified and the rules_js default pnpm extension (with the `LATEST_PNPM_VERSION`) will be used.<br><br>Use `pnpm_version` for non-bzlmod.   |  `None` |
| <a id="npm_translate_lock-npm_package_target_name"></a>npm_package_target_name |  The name of linked `npm_package` targets. When `npm_package` targets are linked as pnpm workspace packages, the name of the target must align with this value.<br><br>The `{dirname}` placeholder is replaced with the directory name of the target.<br><br>By default the directory name of the target is used.<br><br>Default: `{dirname}`   |  `"{dirname}"` |
| <a id="npm_translate_lock-kwargs"></a>kwargs |  Internal use only   |  none |


