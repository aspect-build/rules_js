"""Logic to fetch npm packages for a lockfile.

These use Bazel's downloader to fetch the packages.
You can use this to redirect all fetches through a store like Artifactory.

See <https://blog.aspect.build/configuring-bazels-downloader> for more info about how it works
and how to configure it.

The [`npm_translate_lock`](#npm_translate_lock) bazel module extension tag is the primary user-facing API.
It uses the lockfile format from [pnpm](https://pnpm.io/motivation) because it gives us reliable
semantics for how to dynamically lay out `node_modules` trees on disk in bazel-out.

To create `pnpm-lock.yaml`, consider using [`pnpm import`](https://pnpm.io/cli/import)
to preserve the versions pinned by your existing `package-lock.json` or `yarn.lock` file.

If you don't have an existing lock file, you can run `npx pnpm install --lockfile-only`.

Advanced users may want to directly fetch a package from npm rather than start from a lockfile,
[`npm_import`](./npm_import) does this.
"""

load("@bazel_lib//lib:repo_utils.bzl", "repo_utils")
load("@bazel_lib//lib:write_source_files.bzl", "write_source_file")
load("@bazel_skylib//lib:paths.bzl", "paths")
load(":list_sources.bzl", "list_sources")
load(":npm_translate_lock_helpers.bzl", "helpers")
load(":npm_translate_lock_state.bzl", "DEFAULT_ROOT_PACKAGE", "npm_translate_lock_state")
load(":utils.bzl", "utils")

RULES_JS_FROZEN_PNPM_LOCK_ENV = "ASPECT_RULES_JS_FROZEN_PNPM_LOCK"

################################################################################

_ATTRS = {
    "additional_file_contents": attr.string_list_dict(),
    "bins": attr.string_list_dict(),
    "custom_postinstalls": attr.string_dict(),
    "data": attr.label_list(),
    "external_repository_action_cache": attr.string(default = utils.default_external_repository_action_cache()),
    "generate_bzl_library_targets": attr.bool(),
    "lifecycle_hooks_envs": attr.string_list_dict(),
    "lifecycle_hooks": attr.string_list_dict(),
    "lifecycle_hooks_exclude": attr.string_list(default = []),
    "lifecycle_hooks_execution_requirements": attr.string_list_dict(),
    "lifecycle_hooks_use_default_shell_env": attr.string_dict(),
    "lifecycle_hooks_no_sandbox": attr.bool(default = True),
    "link_workspace": attr.string(),
    "name": attr.string(),
    "no_dev": attr.bool(),
    "no_optional": attr.bool(),
    "node_toolchain_prefix": attr.string(default = "nodejs"),
    "npm_package_lock": attr.label(),
    "npm_package_target_name": attr.string(default = "pkg"),
    "npmrc": attr.label(),
    "package_visibility": attr.string_list_dict(),
    "patch_tool": attr.label(),
    "patch_args": attr.string_list_dict(default = {"*": ["-p0"]}),
    "patches": attr.string_list_dict(),
    "use_pnpm": attr.label(default = "@pnpm//:package/bin/pnpm.cjs"),  # bzlmod pnpm extension
    "pnpm_lock": attr.label(),
    "preupdate": attr.label_list(),
    "public_hoist_packages": attr.string_list_dict(),
    "quiet": attr.bool(default = True),
    "root_package": attr.string(default = DEFAULT_ROOT_PACKAGE),
    "run_lifecycle_hooks": attr.bool(default = True),
    "update_pnpm_lock": attr.bool(),
    "use_home_npmrc": attr.bool(),
    "verify_node_modules_ignored": attr.label(),
    "verify_patches": attr.label(),
    "yarn_lock": attr.label(),
}

_DOCS = """Repository macro to generate starlark code from a lock file.

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

    node_toolchain_prefix: the prefix of the node toolchain to use when generating the pnpm lockfile.

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
        `bazel run @{name}//:sync` where `name` is the name of the `npm_translate_lock` you want to re-run.

        Because of the repository rule invalidation issue, using the home `.npmrc` is not recommended.
        `.npmrc` settings should generally go in the `npmrc` in your repository so they are shared by all
        developers. The home `.npmrc` should be reserved for authentication settings for private npm repositories.

    data: Data files required by this repository rule when auto-updating the pnpm lock file.

        Only needed when `update_pnpm_lock` is True.
        Read more: [using update_pnpm_lock](/docs/pnpm.md#update_pnpm_lock)

    patches: A map of package names or package names with their version (e.g., "my-package" or "my-package@v1.2.3")
        to a label list of patches to apply to the downloaded npm package. Multiple matches are additive.

        These patches are applied after any patches in [pnpm.patchedDependencies](https://pnpm.io/next/package_json#pnpmpatcheddependencies).

        Read more: [patching](/docs/pnpm.md#patching)

    patch_tool: The patch tool to use. If not specified, the `patch` from `PATH` is used.

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

    package_visibility: A map of package names or package names with their version (e.g., "my-package" or "my-package@v1.2.3")
        to a visibility list to use for the package's generated node_modules link targets. Multiple matches are additive.
        If there are no matches then the package's generated node_modules link targets default to public visibility
        (`["//visibility:public"]`).

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

    no_dev: If True, `devDependencies` are not included

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

    lifecycle_hooks_use_default_shell_env: The `use_default_shell_env` attribute of the lifecycle hooks
        actions on npm packages.

        See [use_default_shell_env](https://bazel.build/rules/lib/builtins/actions#run.use_default_shell_env)

        Note: [--incompatible_merge_fixed_and_default_shell_env](https://bazel.build/reference/command-line-reference#flag--incompatible_merge_fixed_and_default_shell_env)
        is often required and not enabled by default in Bazel < 7.0.0.

        This defaults to False reduce the negative effects of `use_default_shell_env`. Requires bazel-lib >= 2.4.2.

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

        Note: Bzlmod users must use an alternative syntax due to module extensions not supporting
        dict-of-dict attributes:

        ```
        bins = {
            "@foo/bar": [
                "foo=./foo.js",
                "bar=./bar.js"
            ],
        }
        ```

    verify_node_modules_ignored: node_modules folders in the source tree should be ignored by Bazel.

        This points to a `.bazelignore` file to verify that all nested node_modules directories
        pnpm will create are listed.

        See https://github.com/bazelbuild/bazel/issues/8106

    verify_patches: Label to a patch list file.

        Use this in together with the `list_patches` macro to guarantee that all patches in a patch folder
        are included in the `patches` attribute.

        For example:

        ```
        verify_patches = "//patches:patches.list",
        ```

        In your patches folder add a BUILD.bazel file containing.
        ```
        load("@aspect_rules_js//npm:repositories.bzl", "list_patches")

        list_patches(
            name = "patches",
            out = "patches.list",
        )
        ```

        Once you have created this file, you need to create an empty `patches.list` file before generating the first list. You can do this by running
        ```
        touch patches/patches.list
        ```

        Finally, write the patches file at least once to make sure all patches are listed. This can be done by running `bazel run //patches:patches_update`.

        See the `list_patches` documentation for further info.
        NOTE: if you would like to customize the patches directory location, you can set a flag in the `.npmrc`. Here is an example of what this might look like
        ```
        # Set the directory for pnpm when patching
        # https://github.com/pnpm/pnpm/issues/6508#issuecomment-1537242124
        patches-dir=bazel/js/patches
        ```
        If you do this, you will have to update the `verify_patches` path to be this path instead of `//patches` like above.

    quiet: Set to False to print info logs and output stdout & stderr of pnpm lock update actions to the console.

    external_repository_action_cache: The location of the external repository action cache to write to when `update_pnpm_lock` = True.

    link_workspace: The workspace name where links will be created for the packages in this lock file.

        This is typically set in rule sets and libraries that vendor the starlark generated by npm_translate_lock
        so the link_workspace passed to npm_import is set correctly so that links are created in the external
        repository and not the user workspace.

        Can be left unspecified if the link workspace is the user workspace.

    use_pnpm: label of the pnpm entry point to use.

    npm_package_target_name: The name of linked `js_library`, `npm_package` or `JsInfo` producing targets.

        When targets are linked as pnpm workspace packages, the name of the target must align with this value.

        The `{dirname}` placeholder is replaced with the directory name of the target.

    **kwargs: Internal use only
"""

npm_translate_lock_lib = struct(
    attrs = _ATTRS,
    doc = _DOCS,
)

def parse_and_verify_lock(rctx, rctx_name, attr):
    """Helper to parse and validate the lockfile

    Args:
        rctx: repository context
        rctx_name: repository/hub name
        attr: attributes
    Returns:
        state, importers, and packages
    """

    state = npm_translate_lock_state.new(rctx_name, rctx, attr)

    # If a pnpm lock file has not been specified then we need to bootstrap by running `pnpm
    # import` in the user's repository
    if not attr.pnpm_lock:
        _bootstrap_import(rctx, rctx_name, attr, state)

    if state.should_update_pnpm_lock():
        # Run `pnpm install --lockfile-only` or `pnpm import` if its inputs have changed since last update
        if state.action_cache_miss():
            _fail_if_frozen_pnpm_lock(rctx, rctx_name, state)
            if _update_pnpm_lock(rctx, rctx_name, attr, state):
                msg = """

INFO: {} file updated. Please run your build again.

See https://github.com/aspect-build/rules_js/issues/1445
""".format(state.label_store.relative_path("pnpm_lock"))
                fail(msg)

    helpers.verify_node_modules_ignored(rctx, attr, state.importers(), state.root_package())

    helpers.verify_patches(rctx, attr, state)

    helpers.verify_lifecycle_hooks_specified(rctx, state)

    return state

################################################################################

def list_patches(name, out = None, include_patterns = ["*.diff", "*.patch"], exclude_package_contents = []):
    """Write a file containing a list of all patches in the current folder to the source tree.

    Use this together with the `verify_patches` attribute of `npm_translate_lock` to verify
    that all patches in a patch folder are included. This macro stamps a test to ensure the
    file stays up to date.

    Args:
        name: Name of the target
        out: Name of file to write to the source tree. If unspecified, `name` is used
        include_patterns: Patterns to pass to a glob of patch files
        exclude_package_contents: Patterns to ignore in a glob of patch files
    """
    outfile = out if out else name

    # Ignore the patch list file we generate
    exclude_package_contents = exclude_package_contents[:]
    exclude_package_contents.append(outfile)

    list_sources(
        name = "%s_list" % name,
        srcs = native.glob(include_patterns, exclude = exclude_package_contents),
    )

    write_source_file(
        name = "%s_update" % name,
        in_file = ":%s_list" % name,
        out_file = outfile,
    )

################################################################################
def _host_node_path(rctx, attr):
    # Note that we must reference the node binary under the platform-specific node
    # toolchain repository rather than under @nodejs_host since running rctx.path
    # (called outside this function) on the alias in the host repo fails under bzlmod.
    # It appears to fail because the platform-specific repository does not exist
    # unless we reference the label here.
    #
    # TODO: Try to understand this better and see if we can go back to using
    #  Label("@nodejs_host//:bin/node")
    return rctx.path(Label("@{}_{}//:bin/node".format(attr.node_toolchain_prefix, repo_utils.platform(rctx))))

def _bootstrap_import(rctx, rctx_name, attr, state):
    pnpm_lock_label = state.label_store.label("pnpm_lock")
    pnpm_lock_path = state.label_store.path("pnpm_lock")

    # Check if the pnpm lock file already exists and copy it over if it does.
    # When we do this, warn the user that we do.
    if utils.exists(rctx, pnpm_lock_path):
        # buildifier: disable=print
        print("""
WARNING: Implicitly using pnpm-lock.yaml file `{pnpm_lock}` that is expected to be the result of running `pnpm import` on the `{lock}` lock file.
         Set the `pnpm_lock` attribute of `npm_translate_lock(name = "{rctx_name}")` to `{pnpm_lock}` suppress this warning.
""".format(pnpm_lock = pnpm_lock_label, lock = state.label_store.label("lock"), rctx_name = rctx_name))
        return

    # No pnpm lock file exists and the user has specified a yarn or npm lock file. Bootstrap
    # the pnpm lock file by running `pnpm import` in the source tree. We run in the source tree
    # because at this point the user has likely not added all package.json and data files that
    # pnpm import depends on to `npm_translate_lock`. In order to get a complete initial pnpm lock
    # file with all workspace package imports listed we likely need to run in the source tree.
    bootstrap_working_directory = paths.dirname(pnpm_lock_path)

    if not attr.quiet:
        # buildifier: disable=print
        print("""
INFO: Running initial `pnpm import` in `{wd}` to bootstrap the pnpm-lock.yaml file required by rules_js.
      It is recommended that you check the generated pnpm-lock.yaml file into source control and add it to the pnpm_lock
      attribute of `npm_translate_lock(name = "{rctx_name}")` so subsequent invocations of the repository
      rule do not need to run `pnpm import` unless an input has changed.""".format(wd = bootstrap_working_directory, rctx_name = rctx_name))

    rctx.report_progress("Bootstrapping pnpm-lock.yaml file with `pnpm import`")

    result = rctx.execute(
        [
            _host_node_path(rctx, attr),
            rctx.path(attr.use_pnpm),
            "import",
        ],
        working_directory = bootstrap_working_directory,
        quiet = attr.quiet,
    )
    if result.return_code:
        msg = """ERROR: 'pnpm import' exited with status {status}:
STDOUT:
{stdout}
STDERR:
{stderr}
""".format(status = result.return_code, stdout = result.stdout, stderr = result.stderr)
        fail(msg)

    if not utils.exists(rctx, pnpm_lock_path):
        msg = """

ERROR: Running `pnpm import` did not generate the {path} file.
       Try installing pnpm (https://pnpm.io/installation) and running `pnpm import` manually
       to generate the pnpm-lock.yaml file.""".format(path = pnpm_lock_path)
        fail(msg)

    msg = """

INFO: Initial pnpm-lock.yaml file generated. Please add the generated pnpm-lock.yaml file into
      source control and set the `pnpm_lock` attribute in `npm_translate_lock(name = "{rctx_name}")` to `{pnpm_lock}`
      and then run your build again.""".format(
        rctx_name = rctx_name,
        pnpm_lock = pnpm_lock_label,
    )
    fail(msg)

################################################################################
def _execute_preupdate_scripts(rctx, attr, state):
    for i in range(len(attr.preupdate)):
        script_key = "preupdate_{}".format(i)

        rctx.report_progress("Executing preupdate Node.js script `{script}`".format(
            script = state.label_store.relative_path(script_key),
        ))

        result = rctx.execute(
            [
                _host_node_path(rctx, attr),
                state.label_store.path(script_key),
            ],
            # To keep things simple, run at the root of the external repository
            working_directory = state.label_store.repo_root,
            quiet = attr.quiet,
        )
        if result.return_code:
            msg = """

ERROR: `node {script}` exited with status {status}.

       Make sure all package.json and other data files required for the running `node {script}` are added to
       the data attribute of `npm_translate_lock(name = "{rctx_name}")`.

STDOUT:
{stdout}
STDERR:
{stderr}
""".format(
                script = state.label_store.relative_path(script_key),
                rctx_name = rctx.name,
                status = result.return_code,
                stderr = result.stderr,
                stdout = result.stdout,
            )
            fail(msg)

################################################################################
def _update_pnpm_lock(rctx, rctx_name, attr, state):
    _execute_preupdate_scripts(rctx, attr, state)

    pnpm_lock_label = state.label_store.label("pnpm_lock")
    pnpm_lock_relative_path = state.label_store.relative_path("pnpm_lock")

    update_cmd = ["import"] if attr.npm_package_lock or attr.yarn_lock else ["install", "--lockfile-only"]
    update_working_directory = paths.dirname(state.label_store.repository_path("pnpm_lock"))

    pnpm_cmd = " ".join(update_cmd)

    if not attr.quiet:
        # buildifier: disable=print
        print("""
INFO: Updating `{pnpm_lock}` file as its inputs have changed since the last update.
      Running `pnpm {pnpm_cmd}` in `{wd}`.
      To disable this feature set `update_pnpm_lock` to False in `npm_translate_lock(name = "{rctx_name}")`.""".format(
            pnpm_lock = pnpm_lock_relative_path,
            pnpm_cmd = pnpm_cmd,
            wd = update_working_directory,
            rctx_name = rctx_name,
        ))

    rctx.report_progress("Updating pnpm-lock.yaml with `pnpm {pnpm_cmd}`".format(pnpm_cmd = pnpm_cmd))

    result = rctx.execute(
        [
            _host_node_path(rctx, attr),
            rctx.path(attr.use_pnpm),
        ] + update_cmd,
        # Run pnpm in the external repository so that we are hermetic and all data files that are required need
        # to be specified. This requirement means that if any data file changes then the update command will be
        # re-run. For cases where all data files cannot be specified a user can simply turn off auto-updates
        # by setting update_pnpm_lock to False and update their pnpm-lock.yaml file manually.
        working_directory = update_working_directory,
        quiet = attr.quiet,
    )
    if result.return_code:
        msg = """

ERROR: `pnpm {cmd}` exited with status {status}.

       Make sure all package.json and other data files required for the running `pnpm {cmd}` are added to
       the data attribute of `npm_translate_lock(name = "{rctx_name}")`.

       If the problem persists, install pnpm (https://pnpm.io/installation) and run `pnpm {cmd}`
       manually to update the pnpm-lock.yaml file. If you have specified `preupdate` scripts in
       `npm_translate_lock(name = "{rctx_name}")` you may have to run these manually as well.

STDOUT:
{stdout}
STDERR:
{stderr}
""".format(
            cmd = " ".join(update_cmd),
            rctx_name = rctx_name,
            status = result.return_code,
            stderr = result.stderr,
            stdout = result.stdout,
        )
        fail(msg)

    lockfile_changed = False
    if state.set_input_hash(
        state.label_store.relative_path("pnpm_lock"),
        utils.hash(rctx.read(state.label_store.repository_path("pnpm_lock"))),
    ):
        # The lock file has changed
        if not attr.quiet:
            # buildifier: disable=print
            print("""
INFO: {} file has changed""".format(pnpm_lock_relative_path))
        utils.reverse_force_copy(rctx, pnpm_lock_label)
        lockfile_changed = True

    state.write_action_cache()

    return lockfile_changed

################################################################################
def _fail_if_frozen_pnpm_lock(rctx, rctx_name, state):
    if rctx.getenv(RULES_JS_FROZEN_PNPM_LOCK_ENV):
        fail("""

ERROR: `{action_cache}` is out of date. `{pnpm_lock}` may require an update. To update run,

           bazel run @@{rctx_name}//:sync

""".format(
            action_cache = state.label_store.relative_path("action_cache"),
            pnpm_lock = state.label_store.relative_path("pnpm_lock"),
            rctx_name = rctx_name,
        ))
