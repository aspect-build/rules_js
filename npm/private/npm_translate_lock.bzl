"Convert pnpm lock file into starlark Bazel fetches"

load("@bazel_skylib//lib:paths.bzl", "paths")
load(":npm_translate_lock_generate.bzl", "helpers")
load(":npm_translate_lock_state.bzl", "DEFAULT_ROOT_PACKAGE", "npm_translate_lock_state")
load(":utils.bzl", "utils")
load(":transitive_closure.bzl", "translate_to_transitive_closure")

RULES_JS_FROZEN_PNPM_LOCK_ENV = "ASPECT_RULES_JS_FROZEN_PNPM_LOCK"

################################################################################
DEFAULT_REPOSITORIES_BZL_FILENAME = "repositories.bzl"
DEFAULT_DEFS_BZL_FILENAME = "defs.bzl"

_ATTRS = {
    "pnpm_lock": attr.label(),
    "npm_package_lock": attr.label(),
    "yarn_lock": attr.label(),
    "update_pnpm_lock": attr.bool(),
    "npmrc": attr.label(),
    "patches": attr.string_list_dict(),
    "patch_args": attr.string_list_dict(),
    "custom_postinstalls": attr.string_dict(),
    "prod": attr.bool(),
    "public_hoist_packages": attr.string_list_dict(),
    "dev": attr.bool(),
    "no_optional": attr.bool(),
    "lifecycle_hooks_exclude": attr.string_list(),
    "run_lifecycle_hooks": attr.bool(default = True),
    "lifecycle_hooks_envs": attr.string_list_dict(),
    "lifecycle_hooks_execution_requirements": attr.string_list_dict(),
    "bins": attr.string_list_dict(),
    "lifecycle_hooks_no_sandbox": attr.bool(default = True),
    "verify_node_modules_ignored": attr.label(),
    "link_workspace": attr.string(),
    "root_package": attr.string(default = DEFAULT_ROOT_PACKAGE),
    "additional_file_contents": attr.string_list_dict(),
    "repositories_bzl_filename": attr.string(default = DEFAULT_REPOSITORIES_BZL_FILENAME),
    "defs_bzl_filename": attr.string(default = DEFAULT_DEFS_BZL_FILENAME),
    "generate_bzl_library_targets": attr.bool(),
    "data": attr.label_list(),
    "quiet": attr.bool(default = True),
    "use_home_npmrc": attr.bool(),
}

npm_translate_lock_lib = struct(
    attrs = _ATTRS,
)

################################################################################
def _impl(rctx):
    rctx.report_progress("Initializing")

    state = npm_translate_lock_state.new(rctx)

    # If a pnpm lock file has not been specified then we need to bootstrap by running `pnpm
    # import` in the user's repository
    if not rctx.attr.pnpm_lock:
        _bootstrap_import(rctx, state)

    if state.should_update_pnpm_lock():
        # Run `pnpm install --lockfile-only` or `pnpm import` if its inputs have changed since last update
        if state.action_cache_miss():
            _fail_if_frozen_pnpm_lock(rctx, state)
            if _update_pnpm_lock(rctx, state):
                # If the pnpm lock file was changed then reload it before translation
                state.reload_lockfile()

    helpers.verify_node_modules_ignored(rctx, state.importers(), state.root_package())

    rctx.report_progress("Translating {}".format(state.label_store.relative_path("pnpm_lock")))

    importers, packages = translate_to_transitive_closure(
        state.importers(),
        state.packages(),
        rctx.attr.prod,
        rctx.attr.dev,
        rctx.attr.no_optional,
    )

    rctx.report_progress("Generating starlark for npm dependencies")

    helpers.generate_repository_files(
        rctx,
        state.label_store.label("pnpm_lock"),
        importers,
        packages,
        state.root_package(),
        state.default_registry(),
        state.npm_registries(),
        state.npm_auth(),
        state.link_workspace(),
    )

npm_translate_lock = repository_rule(
    implementation = _impl,
    attrs = _ATTRS,
)

################################################################################
def _bootstrap_import(rctx, state):
    pnpm_lock_label = state.label_store.label("pnpm_lock")
    pnpm_lock_path = state.label_store.path("pnpm_lock")

    # Check if the pnpm lock file already exists and copy it over if it does.
    # When we do this, warn the user that we do.
    if utils.exists(rctx, pnpm_lock_path):
        # buildifier: disable=print
        print("""
WARNING: Implicitly using pnpm-lock.yaml file `{pnpm_lock}` that is expected to be the result of running `pnpm import` on the `{lock}` lock file.
         Set the `pnpm_lock` attribute of `npm_translate_lock(name = "{rctx_name}")` to `{pnpm_lock}` suppress this warning.
""".format(pnpm_lock = pnpm_lock_label, lock = state.label_store.label("lock"), rctx_name = rctx.name))
        return

    # No pnpm lock file exists and the user has specified a yarn or npm lock file. Bootstrap
    # the pnpm lock file by running `pnpm import` in the source tree. We run in the source tree
    # because at this point the user has likely not added all package.json and data files that
    # pnpm import depends on to `npm_translate_lock`. In order to get a complete initial pnpm lock
    # file with all workspace package imports listed we likely need to run in the source tree.
    bootstrap_working_directory = paths.dirname(pnpm_lock_path)

    if not rctx.attr.quiet:
        # buildifier: disable=print
        print("""
INFO: Running initial `pnpm import` in `{wd}` to bootstrap the pnpm-lock.yaml file required by rules_js.
      It is recommended that you check the generated pnpm-lock.yaml file into source control and add it to the pnpm_lock
      attribute of `npm_translate_lock(name = "{rctx_name}")` so subsequent invocations of the repository
      rule do not need to run `pnpm import` unless an input has changed.""".format(wd = bootstrap_working_directory, rctx_name = rctx.name))

    rctx.report_progress("Bootstrapping pnpm-lock.yaml file with `pnpm import`")

    result = rctx.execute(
        [
            state.label_store.path("host_node"),
            state.label_store.path("pnpm_entry"),
            "import",
        ],
        working_directory = bootstrap_working_directory,
        quiet = rctx.attr.quiet,
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
        rctx_name = rctx.name,
        pnpm_lock = pnpm_lock_label,
    )
    fail(msg)

################################################################################
def _update_pnpm_lock(rctx, state):
    pnpm_lock_label = state.label_store.label("pnpm_lock")
    pnpm_lock_relative_path = state.label_store.relative_path("pnpm_lock")

    update_cmd = ["import"] if rctx.attr.npm_package_lock or rctx.attr.yarn_lock else ["install", "--lockfile-only"]
    update_working_directory = paths.dirname(state.label_store.repository_path("pnpm_lock"))

    pnpm_cmd = " ".join(update_cmd)

    if not rctx.attr.quiet:
        # buildifier: disable=print
        print("""
INFO: Updating `{pnpm_lock}` file as its inputs have changed since the last update.
      Running `pnpm {pnpm_cmd}` in `{wd}`.
      To disable this feature set `update_pnpm_lock` to False in `npm_translate_lock(name = "{rctx_name}")`.""".format(
            pnpm_lock = pnpm_lock_relative_path,
            pnpm_cmd = pnpm_cmd,
            wd = update_working_directory,
            rctx_name = rctx.name,
        ))

    rctx.report_progress("Updating pnpm-lock.yaml with `pnpm {pnpm_cmd}`".format(pnpm_cmd = pnpm_cmd))

    result = rctx.execute(
        [
            state.label_store.path("host_node"),
            state.label_store.path("pnpm_entry"),
        ] + update_cmd,
        # Run pnpm in the external repository so that we are hermetic and all data files that are required need
        # to be specified. This requirement means that if any data file changes then the update command will be
        # re-run. For cases where all data files cannot be specified a user can simply turn off auto-updates
        # by setting update_pnpm_lock to False and update their pnpm-lock.yaml file manually.
        working_directory = update_working_directory,
        quiet = rctx.attr.quiet,
    )
    if result.return_code:
        msg = """

ERROR: `pnpm {cmd}` exited with status {status}.

       Make sure all package.json and other data files required for the running `pnpm {cmd}` are added to
       the data attribute of `npm_translate_lock(name = "{rctx_name}")`.

       If the problem persists, install pnpm (https://pnpm.io/installation) and run `pnpm {cmd}`
       manually to update the pnpm-lock.yaml file.

STDOUT:
{stdout}
STDERR:
{stderr}
""".format(
            cmd = " ".join(update_cmd),
            rctx_name = rctx.name,
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
        if not rctx.attr.quiet:
            # buildifier: disable=print
            print("""
INFO: {} file has changed""".format(pnpm_lock_relative_path))
        utils.reverse_force_copy(rctx, pnpm_lock_label)
        lockfile_changed = True

    state.write_action_cache()

    return lockfile_changed

################################################################################
def _fail_if_frozen_pnpm_lock(rctx, state):
    if RULES_JS_FROZEN_PNPM_LOCK_ENV in rctx.os.environ.keys() and rctx.os.environ[RULES_JS_FROZEN_PNPM_LOCK_ENV]:
        fail("""

ERROR: `{action_cache}` is out of date. `{pnpm_lock}` may require an update. To update run,

           bazel sync --only={rctx_name}

""".format(
            action_cache = state.label_store.relative_path("action_cache"),
            pnpm_lock = state.label_store.relative_path("pnpm_lock"),
            rctx_name = rctx.name,
        ))
