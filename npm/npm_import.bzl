"""Repository rules to fetch third-party npm packages

Load these with,

```starlark
load("@aspect_rules_js//npm:npm_import.bzl", "npm_translate_lock", "npm_import")
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

Advanced users may want to directly fetch a package from npm rather than start from a lockfile.
[`npm_import`](#npm_import) does this.
"""

load("@bazel_skylib//lib:dicts.bzl", "dicts")
load("//npm/private:npm_import.bzl", _npm_import_lib = "npm_import", _npm_import_links_lib = "npm_import_links")
load("//npm/private:versions.bzl", "PNPM_VERSIONS")
load("//npm/private:utils.bzl", _utils = "utils")
load("//npm/private:npm_translate_lock.bzl", _npm_translate_lock = "npm_translate_lock")
load("@aspect_bazel_lib//lib:repositories.bzl", _register_copy_to_directory_toolchains = "register_copy_to_directory_toolchains")

LATEST_PNPM_VERSION = PNPM_VERSIONS.keys()[-1]

def pnpm_repository(name, pnpm_version = LATEST_PNPM_VERSION):
    """Import https://npmjs.com/package/pnpm and provide a js_binary to run the tool.

    Useful as a way to run exactly the same pnpm as Bazel does, for example with:
    bazel run -- @pnpm//:pnpm --dir $PWD

    Args:
        name: name of the resulting external repository
        pnpm_version: version of pnpm, see https://www.npmjs.com/package/pnpm?activeTab=versions
    """

    if not native.existing_rule(name):
        npm_import(
            name = name,
            integrity = PNPM_VERSIONS[pnpm_version],
            package = "pnpm",
            root_package = "",
            version = pnpm_version,
            extra_build_content = [
                """load("@aspect_rules_js//js:defs.bzl", "js_binary")""",
                """js_binary(name = "pnpm", entry_point = "package/dist/pnpm.cjs", visibility = ["//visibility:public"])""",
            ],
            register_copy_to_directory_toolchains = False,  # this code path should work for both WORKSPACE and bzlmod
        )

def npm_translate_lock(
        name,
        pnpm_lock = None,
        npm_package_lock = None,
        yarn_lock = None,
        update_pnpm_lock = None,
        preupdate = [],
        npmrc = None,
        use_home_npmrc = None,
        data = [],
        patches = {},
        patch_args = {"*": ["-p0"]},
        custom_postinstalls = {},
        prod = False,
        public_hoist_packages = {},
        dev = False,
        no_optional = False,
        run_lifecycle_hooks = True,
        lifecycle_hooks = {},
        lifecycle_hooks_envs = {},
        lifecycle_hooks_exclude = [],
        lifecycle_hooks_execution_requirements = {},
        lifecycle_hooks_no_sandbox = True,
        bins = {},
        verify_node_modules_ignored = None,
        quiet = True,
        link_workspace = None,
        pnpm_version = LATEST_PNPM_VERSION,
        register_copy_to_directory_toolchains = True,
        # TODO(2.0): remove package_json
        package_json = None,
        # TODO(2.0): remove warn_on_unqualified_tarball_url
        # buildifier: disable=unused-variable
        warn_on_unqualified_tarball_url = None,
        **kwargs):
    """Repository macro to generate starlark code from a lock file.

    In most repositories, it would be an impossible maintenance burden to manually declare all
    of the [`npm_import`](#npm_import) rules. This helper generates an external repository
    containing a helper starlark module `repositories.bzl`, which supplies a loadable macro
    `npm_repositories`. That macro creates an `npm_import` for each package.

    The generated repository also contains `BUILD` files declaring targets for the packages
    listed as `dependencies` or `devDependencies` in `package.json`, so you can declare
    dependencies on those packages without having to repeat version information.

    This macro creates a `pnpm` external repository, if the user didn't create a repository named
    "pnpm" prior to calling `npm_translate_lock`.
    `rules_js` currently only uses this repository when `npm_package_lock` or `yarn_lock` are used.
    Set `pnpm_version` to `None` to inhibit this repository creation.

    For more about how to use npm_translate_lock, read [pnpm and rules_js](/docs/pnpm.md).

    Args:
        name: The repository rule name

        pnpm_lock: The `pnpm-lock.yaml` file.

        npm_package_lock: The `package-lock.json` file written by `npm install`.

            Only one of `npm_package_lock` or `yarn_lock` may be set.

        yarn_lock: The `yarn.lock` file written by `yarn install`.

            Only one of `npm_package_lock` or `yarn_lock` may be set.

        update_pnpm_lock: When True, the pnpm lock file will be updated automatically when any of its inputs
            have changed since the last update.

            Defaults to True when one of `npm_package_lock` or `yarn_lock` are set.
            Otherwise it defaults to False.

            Read more: [using update_pnpm_lock](/docs/pnpm.md#update_pnpm_lock)

        preupdate: Node.js scripts to run in this repository rule before auto-updating the pnpm lock file.

            Scripts are run sequentially in the order they are listed. The working directory is set to the root of the
            external repository. Make sure all files required by preupdate scripts are added to the `data` attribute.

            A preupdate script could, for example, transform `resolutions` in the root `package.json` file from a format
            that yarn understands such as `@foo/**/bar` to the equivalent `@foo/*>bar` that pnpm understands so that
            `resolutions` are compatible with pnpm when running `pnpm import` to update the pnpm lock file.

            Only needed when `update_pnpm_lock` is True.
            Read more: [using update_pnpm_lock](/docs/pnpm.md#update_pnpm_lock)

        npmrc: The `.npmrc` file, if any, to use.

            When set, the `.npmrc` file specified is parsed and npm auth tokens and basic authentication configuration
            specified in the file are passed to the Bazel downloader for authentication with private npm registries.

            In a future release, pnpm settings such as public-hoist-patterns will be used.

        use_home_npmrc: Use the `$HOME/.npmrc` file (or `$USERPROFILE/.npmrc` when on Windows) if it exists.

            Settings from home `.npmrc` are merged with settings loaded from the `.npmrc` file specified
            in the `npmrc` attribute, if any. Where there are conflicting settings, the home `.npmrc` values
            will take precedence.

            WARNING: The repository rule will not be invalidated by changes to the home `.npmrc` file since there
            is no way to specify this file as an input to the repository rule. If changes are made to the home
            `.npmrc` you can force the repository rule to re-run and pick up the changes by running:
            `bazel sync --only={name}` where `name` is the name of the `npm_translate_lock` you want to re-run.

            Because of the repository rule invalidation issue, using the home `.npmrc` is not recommended.
            `.npmrc` settings should generally go in the `npmrc` in your repository so they are shared by all
            developers. The home `.npmrc` should be reserved for authentication settings for private npm repositories.

        data: Data files required by this repository rule when auto-updating the pnpm lock file.

            Only needed when `update_pnpm_lock` is True.
            Read more: [using update_pnpm_lock](/docs/pnpm.md#update_pnpm_lock)

        patches: A map of package names or package names with their version (e.g., "my-package" or "my-package@v1.2.3")
            to a label list of patches to apply to the downloaded npm package. Multiple matches are additive.

            Read more: [patching](/docs/pnpm.md#patching)

        patch_args: A map of package names or package names with their version (e.g., "my-package" or "my-package@v1.2.3")
            to a label list arguments to pass to the patch tool. The most specific match wins.

            Read more: [patching](/docs/pnpm.md#patching)

        custom_postinstalls: A map of package names or package names with their version (e.g., "my-package" or "my-package@v1.2.3")
            to a custom postinstall script to apply to the downloaded npm package after its lifecycle scripts runs.
            If the version is left out of the package name, the script will run on every version of the npm package. If
            a custom postinstall scripts exists for a package as well as for a specific version, the script for the versioned package
            will be appended with `&&` to the non-versioned package script.

            For example,

            ```
            custom_postinstalls = {
                "@foo/bar": "echo something > somewhere.txt",
                "fum@0.0.1": "echo something_else > somewhere_else.txt",
            },
            ```

            Custom postinstalls are additive and joined with ` && ` when there are multiple matches for a package.
            More specific matches are appended to previous matches.

        prod: If True, only install `dependencies` but not `devDependencies`.

        public_hoist_packages: A map of package names or package names with their version (e.g., "my-package" or "my-package@v1.2.3")
            to a list of Bazel packages in which to hoist the package to the top-level of the node_modules tree when linking.

            This is similar to setting https://pnpm.io/npmrc#public-hoist-pattern in an .npmrc file outside of Bazel, however,
            wild-cards are not yet supported and npm_translate_lock will fail if there are multiple versions of a package that
            are to be hoisted.

            ```
            public_hoist_packages = {
                "@foo/bar": [""] # link to the root package in the WORKSPACE
                "fum@0.0.1": ["some/sub/package"]
            },
            ```

            List of public hoist packages are additive when there are multiple matches for a package. More specific matches
            are appended to previous matches.

        dev: If True, only install `devDependencies`

        no_optional: If True, `optionalDependencies` are not installed.

            Currently `npm_translate_lock` behaves differently from pnpm in that is downloads all `optionaDependencies`
            while pnpm doesn't download `optionalDependencies` that are not needed for the platform pnpm is run on.
            See https://github.com/pnpm/pnpm/pull/3672 for more context.

        run_lifecycle_hooks: Sets a default value for `lifecycle_hooks` if `*` not already set.
            Set this to `False` to disable lifecycle hooks.

        lifecycle_hooks: A dict of package names to list of lifecycle hooks to run for that package.

            By default the `preinstall`, `install` and `postinstall` hooks are run if they exist. This attribute allows
            the default to be overridden for packages to run `prepare`.

            List of hooks are not additive. The most specific match wins.

            Read more: [lifecycles](/docs/pnpm.md#lifecycles)

        lifecycle_hooks_exclude: A list of package names or package names with their version (e.g., "my-package" or "my-package@v1.2.3")
            to not run any lifecycle hooks on.

            Equivalent to adding `<value>: []` to `lifecycle_hooks`.

            Read more: [lifecycles](/docs/pnpm.md#lifecycles)

        lifecycle_hooks_envs: Environment variables set for the lifecycle hooks actions on npm packages.
            The environment variables can be defined per package by package name or globally using "*".
            Variables are declared as key/value pairs of the form "key=value".
            Multiple matches are additive.

            Read more: [lifecycles](/docs/pnpm.md#lifecycles)

        lifecycle_hooks_execution_requirements: Execution requirements applied to the preinstall, install and postinstall
            lifecycle hooks on npm packages.

            The execution requirements can be defined per package by package name or globally using "*".

            Execution requirements are not additive. The most specific match wins.

            Read more: [lifecycles](/docs/pnpm.md#lifecycles)

        lifecycle_hooks_no_sandbox: If True, a "no-sandbox" execution requirement is added to all lifecycle hooks
            unless overridden by `lifecycle_hooks_execution_requirements`.

            Equivalent to adding `"*": ["no-sandbox"]` to `lifecycle_hooks_execution_requirements`.

            This defaults to True to limit the overhead of sandbox creation and copying the output
            TreeArtifacts out of the sandbox.

            Read more: [lifecycles](/docs/pnpm.md#lifecycles)

        bins: Binary files to create in `node_modules/.bin` for packages in this lock file.

            For a given package, this is typically derived from the "bin" attribute in
            the package.json file of that package.

            For example:

            ```
            bins = {
                "@foo/bar": {
                    "foo": "./foo.js",
                    "bar": "./bar.js"
                },
            }
            ```

            Dicts of bins not additive. The most specific match wins.

            In the future, this field may be automatically populated from information in the pnpm lock
            file. That feature is currently blocked on https://github.com/pnpm/pnpm/issues/5131.

        verify_node_modules_ignored: node_modules folders in the source tree should be ignored by Bazel.

            This points to a `.bazelignore` file to verify that all nested node_modules directories
            pnpm will create are listed.

            See https://github.com/bazelbuild/bazel/issues/8106

        quiet: Set to False to print info logs and output stdout & stderr of pnpm lock update actions to the console.

        link_workspace: The workspace name where links will be created for the packages in this lock file.


            This is typically set in rule sets and libraries that vendor the starlark generated by npm_translate_lock
            so the link_workspace passed to npm_import is set correctly so that links are created in the external
            repository and not the user workspace.

            Can be left unspecified if the link workspace is the user workspace.

        pnpm_version: pnpm version to use when generating the @pnpm repository. Set to None to not create this repository.

        register_copy_to_directory_toolchains: if True, `@aspect_bazel_lib//lib:repositories.bzl` `register_copy_to_directory_toolchains()` is called if the toolchain is not already registered

        package_json: Deprecated.

            Add all `package.json` files that are part of the workspace to `data` instead.

        warn_on_unqualified_tarball_url: Deprecated. Will be removed in next major release.

        **kwargs: Internal use only
    """

    # TODO(2.0): move this to a new required rules_js_repositories() WORKSPACE function
    if register_copy_to_directory_toolchains and not native.existing_rule("copy_to_directory_toolchains"):
        _register_copy_to_directory_toolchains()

    # Gather undocumented attributes
    root_package = kwargs.pop("root_package", None)
    additional_file_contents = kwargs.pop("additional_file_contents", {})
    repositories_bzl_filename = kwargs.pop("repositories_bzl_filename", None)
    defs_bzl_filename = kwargs.pop("defs_bzl_filename", None)
    generate_bzl_library_targets = kwargs.pop("generate_bzl_library_targets", None)

    if len(kwargs):
        msg = "Invalid npm_translate_lock parameter '{}'".format(kwargs.keys()[0])
        fail(msg)

    if pnpm_version != None:
        pnpm_repository(name = "pnpm", pnpm_version = pnpm_version)

    if package_json:
        data = data + [package_json]

        # buildifier: disable=print
        print("""
WARNING: `package_json` attribute in `npm_translate_lock(name = "{name}")` is deprecated. Add all package.json files to the `data` attribute instead.
""".format(name = name))

    # convert bins to a string_list_dict to satisfy attr type in repository rule
    bins_string_list_dict = {}
    if type(bins) != "dict":
        fail("Expected bins to be a dict")
    for key, value in bins.items():
        if type(value) != "dict":
            fail("Expected values in bins to be a dicts")
        if key not in bins_string_list_dict:
            bins_string_list_dict[key] = []
        for value_key, value_value in value.items():
            bins_string_list_dict[key].append("{}={}".format(value_key, value_value))

    # Default update_pnpm_lock to True if npm_package_lock or yarn_lock is set to
    # preserve pre-update_pnpm_lock `pnpm import` behavior.
    if update_pnpm_lock == None and (npm_package_lock or yarn_lock):
        update_pnpm_lock = True

    if not update_pnpm_lock and preupdate:
        fail("expected update_pnpm_lock to be True when preupdate are specified")

    # lifecycle_hooks_exclude is a convenience attribute to set `<value>: []` in `lifecycle_hooks`
    lifecycle_hooks = dict(lifecycle_hooks)
    for p in lifecycle_hooks_exclude:
        if p in lifecycle_hooks:
            fail("expected '{}' to be in only one of lifecycle_hooks or lifecycle_hooks_exclude".format(p))
        lifecycle_hooks[p] = []

    # run_lifecycle_hooks is a convenience attribute to set `"*": ["preinstall", "install", "postinstall"]` in `lifecycle_hooks`
    if run_lifecycle_hooks:
        if "*" not in lifecycle_hooks:
            lifecycle_hooks = dicts.add(lifecycle_hooks, {"*": ["preinstall", "install", "postinstall"]})

    # lifecycle_hooks_no_sandbox is a convenience attribute to set `"*": ["no-sandbox"]` in `lifecycle_hooks_execution_requirements`
    if lifecycle_hooks_no_sandbox:
        if "*" not in lifecycle_hooks_execution_requirements:
            lifecycle_hooks_execution_requirements = dicts.add(lifecycle_hooks_execution_requirements, {"*": []})
        if "no-sandbox" not in lifecycle_hooks_execution_requirements["*"]:
            lifecycle_hooks_execution_requirements["*"].append("no-sandbox")

    _npm_translate_lock(
        name = name,
        pnpm_lock = pnpm_lock,
        npm_package_lock = npm_package_lock,
        yarn_lock = yarn_lock,
        update_pnpm_lock = update_pnpm_lock,
        npmrc = npmrc,
        use_home_npmrc = use_home_npmrc,
        patches = patches,
        patch_args = patch_args,
        custom_postinstalls = custom_postinstalls,
        prod = prod,
        public_hoist_packages = public_hoist_packages,
        dev = dev,
        no_optional = no_optional,
        lifecycle_hooks = lifecycle_hooks,
        lifecycle_hooks_envs = lifecycle_hooks_envs,
        lifecycle_hooks_execution_requirements = lifecycle_hooks_execution_requirements,
        bins = bins_string_list_dict,
        verify_node_modules_ignored = verify_node_modules_ignored,
        link_workspace = link_workspace,
        root_package = root_package,
        additional_file_contents = additional_file_contents,
        repositories_bzl_filename = repositories_bzl_filename,
        defs_bzl_filename = defs_bzl_filename,
        generate_bzl_library_targets = generate_bzl_library_targets,
        data = data,
        preupdate = preupdate,
        quiet = quiet,
    )

_npm_import_links = repository_rule(
    implementation = _npm_import_links_lib.implementation,
    attrs = _npm_import_links_lib.attrs,
)

_npm_import = repository_rule(
    implementation = _npm_import_lib.implementation,
    attrs = _npm_import_lib.attrs,
)

def npm_import(
        name,
        package,
        version,
        deps = {},
        extra_build_content = "",
        transitive_closure = {},
        root_package = "",
        link_workspace = "",
        link_packages = {},
        lifecycle_hooks = [],
        lifecycle_hooks_execution_requirements = ["no-sandbox"],
        lifecycle_hooks_env = [],
        integrity = "",
        url = "",
        commit = "",
        patch_args = ["-p0"],
        patches = [],
        custom_postinstall = "",
        npm_auth = "",
        npm_auth_basic = "",
        npm_auth_username = "",
        npm_auth_password = "",
        bins = {},
        register_copy_to_directory_toolchains = True,
        # TODO(2.0): remove run_lifecycle_hooks from npm_import
        run_lifecycle_hooks = None,
        # TODO(2.0): remove lifecycle_hooks_no_sandbox from npm_import
        lifecycle_hooks_no_sandbox = None,
        **kwargs):
    """Import a single npm package into Bazel.

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

    Read more about the downloader config: <https://blog.aspect.dev/configuring-bazels-downloader>

    [UrlRewriterConfig]: https://github.com/bazelbuild/bazel/blob/4.2.1/src/main/java/com/google/devtools/build/lib/bazel/repository/downloader/UrlRewriterConfig.java#L66

    Args:
        name: Name for this repository rule

        package: Name of the npm package, such as `acorn` or `@types/node`

        version: Version of the npm package, such as `8.4.0`

        deps: A dict other npm packages this one depends on where the key is the package name and value is the version

        transitive_closure: A dict all npm packages this one depends on directly or transitively where the key is the
            package name and value is a list of version(s) depended on in the closure.

        root_package: The root package where the node_modules virtual store is linked to.
            Typically this is the package that the pnpm-lock.yaml file is located when using `npm_translate_lock`.

        link_workspace: The workspace name where links will be created for this package.

            This is typically set in rule sets and libraries that are to be consumed as external repositories so
            links are created in the external repository and not the user workspace.

            Can be left unspecified if the link workspace is the user workspace.

        link_packages: Dict of paths where links may be created at for this package to
            a list of link aliases to link as in each package. If aliases are an
            empty list this indicates to link as the package name.

            Defaults to {} which indicates that links may be created in any package as specified by
            the `direct` attribute of the generated npm_link_package.

        lifecycle_hooks: List of lifecycle hook `package.json` scripts to run for this package if they exist.

        lifecycle_hooks_env: Environment variables set for the lifecycle hooks action for this npm
            package if there is one.

            Environment variables are defined by providing an array of "key=value" entries.

            For example:

            ```
            lifecycle_hooks_env: ["PREBULT_BINARY=https://downloadurl"],
            ```

        lifecycle_hooks_execution_requirements: Execution requirements when running the lifecycle hooks.

            For example:

            ```
            lifecycle_hooks_execution_requirements: ["no-sandbox', "requires-network"]
            ```

            This defaults to ["no-sandbox"] to limit the overhead of sandbox creation and copying the output
            TreeArtifact out of the sandbox.

        integrity: Expected checksum of the file downloaded, in Subresource Integrity format.
            This must match the checksum of the file downloaded.

            This is the same as appears in the pnpm-lock.yaml, yarn.lock or package-lock.json file.

            It is a security risk to omit the checksum as remote files can change.

            At best omitting this field will make your build non-hermetic.

            It is optional to make development easier but should be set before shipping.

        url: Optional url for this package. If unset, a default npm registry url is generated from
            the package name and version.

            May start with `git+ssh://` to indicate a git repository. For example,

            ```
            git+ssh://git@github.com/org/repo.git
            ```

            If url is configured as a git repository, the commit attribute must be set to the
            desired commit.

        commit: Specific commit to be checked out if url is a git repository.

        patch_args: Arguments to pass to the patch tool.

            `-p1` will usually be needed for patches generated by git.

        patches: Patch files to apply onto the downloaded npm package.

        custom_postinstall: Custom string postinstall script to run on the installed npm package. Runs after any
            existing lifecycle hooks if `run_lifecycle_hooks` is True.

        npm_auth: Auth token to authenticate with npm. When using Bearer authentication.

        npm_auth_basic: Auth token to authenticate with npm. When using Basic authentication.

            This is typically the base64 encoded string "username:password".

        npm_auth_username: Auth username to authenticate with npm. When using Basic authentication.

        npm_auth_password: Auth password to authenticate with npm. When using Basic authentication.

        extra_build_content: Additional content to append on the generated BUILD file at the root of
            the created repository, either as a string or a list of lines similar to
            <https://github.com/bazelbuild/bazel-skylib/blob/main/docs/write_file_doc.md>.

        bins: Dictionary of `node_modules/.bin` binary files to create mapped to their node entry points.

            This is typically derived from the "bin" attribute in the package.json
            file of the npm package being linked.

            For example:

            ```
            bins = {
                "foo": "./foo.js",
                "bar": "./bar.js",
            }
            ```

            In the future, this field may be automatically populated by npm_translate_lock
            from information in the pnpm lock file. That feature is currently blocked on
            https://github.com/pnpm/pnpm/issues/5131.

        register_copy_to_directory_toolchains: if True, `@aspect_bazel_lib//lib:repositories.bzl` `register_copy_to_directory_toolchains()` is called if the toolchain is not already registered

        run_lifecycle_hooks: If True, runs `preinstall`, `install`, `postinstall` and 'prepare' lifecycle hooks declared
            in this package.

            Deprecated. Use `lifecycle_hooks` instead.

        lifecycle_hooks_no_sandbox: If True, adds "no-sandbox" to `lifecycle_hooks_execution_requirements`.

            Deprecated. Add "no-sandbox" to `lifecycle_hooks_execution_requirements` instead.

        **kwargs: Internal use only
    """

    # TODO(2.0): move this to a new required rules_js_repositories() WORKSPACE function
    if register_copy_to_directory_toolchains and not native.existing_rule("copy_to_directory_toolchains"):
        _register_copy_to_directory_toolchains()

    npm_translate_lock_repo = kwargs.pop("npm_translate_lock_repo", None)
    generate_bzl_library_targets = kwargs.pop("generate_bzl_library_targets", None)
    if len(kwargs):
        msg = "Invalid npm_import parameter '{}'".format(kwargs.keys()[0])
        fail(msg)

    if lifecycle_hooks and run_lifecycle_hooks:
        fail("Expected only one of lifecycle_hooks or run_lifecycle_hooks")
    if run_lifecycle_hooks:
        lifecycle_hooks = ["preinstall", "install", "postinstall"]

    # By convention, the `{name}` repository contains the actual npm
    # package sources downloaded from the registry and extracted
    _npm_import(
        name = name,
        package = package,
        version = version,
        root_package = root_package,
        link_workspace = link_workspace,
        link_packages = link_packages,
        integrity = integrity,
        url = url,
        commit = commit,
        patch_args = patch_args,
        patches = patches,
        custom_postinstall = custom_postinstall,
        npm_auth = npm_auth,
        npm_auth_basic = npm_auth_basic,
        npm_auth_username = npm_auth_username,
        npm_auth_password = npm_auth_password,
        lifecycle_hooks = lifecycle_hooks,
        extra_build_content = (
            extra_build_content if type(extra_build_content) == "string" else "\n".join(extra_build_content)
        ),
        generate_bzl_library_targets = generate_bzl_library_targets,
    )

    if lifecycle_hooks_no_sandbox:
        if "no-sandbox" not in lifecycle_hooks_execution_requirements:
            lifecycle_hooks_execution_requirements.append("no-sandbox")

    has_custom_postinstall = not (not custom_postinstall)
    has_lifecycle_hooks = not (not lifecycle_hooks)

    # By convention, the `{name}{utils.links_repo_suffix}` repository contains the generated
    # code to link this npm package into one or more node_modules trees
    _npm_import_links(
        name = "{}{}".format(name, _utils.links_repo_suffix),
        package = package,
        version = version,
        root_package = root_package,
        link_packages = link_packages,
        deps = deps,
        transitive_closure = transitive_closure,
        lifecycle_build_target = has_lifecycle_hooks or has_custom_postinstall,
        lifecycle_hooks_env = lifecycle_hooks_env,
        lifecycle_hooks_execution_requirements = lifecycle_hooks_execution_requirements,
        bins = bins,
        npm_translate_lock_repo = npm_translate_lock_repo,
    )
