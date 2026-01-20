"""Repository rules to fetch third-party npm packages"""

load("//npm/private:npm_import.bzl", _npm_import = "npm_import")
load("//npm/private:npm_translate_lock.bzl", _list_patches = "list_patches")
load("//npm/private:pnpm_repository.bzl", _DEFAULT_PNPM_VERSION = "DEFAULT_PNPM_VERSION", _LATEST_PNPM_VERSION = "LATEST_PNPM_VERSION", _pnpm_repository = "pnpm_repository")

DEFAULT_PNPM_VERSION = _DEFAULT_PNPM_VERSION
LATEST_PNPM_VERSION = _LATEST_PNPM_VERSION

# PRIVATE: exposed only for ruleset-internal use.

list_patches = _list_patches
pnpm_repository = _pnpm_repository

# A trivial wrapper for fetching a single standalone package.
# buildifier: disable=function-docstring
def npm_import(name, package, integrity, version, **kwargs):
    # rules_esbuild specifies empty hooks
    lifecycle_hooks = kwargs.pop("lifecycle_hooks", None)
    if len(lifecycle_hooks) != 0:
        fail("Minimal repositories.bzl npm_import does not support lifecycle_hooks")

    if len(kwargs) != 0:
        fail("Minimal repositories.bzl npm_import received unexpected keyword arguments: %s" % ", ".join(kwargs.keys()))

    _npm_import(
        name = name,
        key = name,
        package = package,
        integrity = integrity,
        version = version,
        deps = {},
        deps_constraints = {},
        extra_build_content = None,
        transitive_closure = None,
        root_package = "",
        lifecycle_hooks = lifecycle_hooks,
        lifecycle_hooks_execution_requirements = None,
        lifecycle_hooks_env = None,
        lifecycle_hooks_use_default_shell_env = None,
        url = None,
        commit = None,
        replace_package = None,
        package_visibility = None,
        patch_tool = None,
        patch_args = None,
        patches = None,
        custom_postinstall = None,
        npm_auth = None,
        npm_auth_basic = None,
        npm_auth_username = None,
        npm_auth_password = None,
        bins = None,
        generate_bzl_library_targets = None,
        generate_package_json_bzl = None,
        extract_full_archive = None,
        exclude_package_contents = None,
        exclude_package_contents_presets = [],
    )
