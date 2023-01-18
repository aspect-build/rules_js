"""Adapt repository rules in npm_import.bzl to be called from MODULE.bazel
See https://bazel.build/docs/bzlmod#extension-definition
"""

load("//npm/private:utils.bzl", "utils")
load("//npm/private:npm_translate_lock_generate.bzl", npm_translate_lock_helpers = "helpers")
load("//npm/private:npm_translate_lock.bzl", "npm_translate_lock_lib")
load("//npm/private:npm_import.bzl", npm_import_lib = "npm_import", npm_import_links_lib = "npm_import_links")
load("//npm:npm_import.bzl", "npm_import", "npm_translate_lock", "pnpm_repository")
load("//npm/private:transitive_closure.bzl", "translate_to_transitive_closure")
load("//npm/private:versions.bzl", "PNPM_VERSIONS")
load("//npm/private:npmrc.bzl", "parse_npmrc")

LATEST_PNPM_VERSION = PNPM_VERSIONS.keys()[-1]

def _extension_impl(module_ctx):
    for mod in module_ctx.modules:
        for attr in mod.tags.npm_translate_lock:
            # npm_translate_lock MUST run before parse_pnpm_lock below since it may update
            # the pnpm-lock.yaml file when update_pnpm_lock is True.
            npm_translate_lock(
                name = attr.name,
                bins = attr.bins,
                data = attr.data,
                npmrc = attr.npmrc,
                npm_package_lock = attr.npm_package_lock,
                patches = attr.patches,
                patch_args = attr.patch_args,
                pnpm_lock = attr.pnpm_lock,
                pnpm_version = attr.pnpm_version,
                preupdate = attr.preupdate,
                quiet = attr.quiet,
                register_copy_directory_toolchains = False,  # this registration is handled elsewhere with bzlmod
                register_copy_to_directory_toolchains = False,  # this registration is handled elsewhere with bzlmod
                update_pnpm_lock = attr.update_pnpm_lock,
                verify_node_modules_ignored = attr.verify_node_modules_ignored,
                verify_patches = attr.verify_patches,
                yarn_lock = attr.yarn_lock,
            )

        for attr in mod.tags.npm_translate_lock:
            # We cannot read the pnpm_lock file before it has been bootstrapped.
            # See comment in e2e/update_pnpm_lock_with_import/test.sh.
            if not attr.pnpm_lock:
                continue

            lock_importers, lock_packages = utils.parse_pnpm_lock(module_ctx.read(attr.pnpm_lock))
            importers, packages = translate_to_transitive_closure(lock_importers, lock_packages, attr.prod, attr.dev, attr.no_optional)
            registries = {}
            npm_auth = {}
            if attr.npmrc:
                npmrc = parse_npmrc(module_ctx.read(attr.npmrc))
                (registries, npm_auth) = npm_translate_lock_helpers.get_npm_auth(npmrc, module_ctx.path(attr.npmrc), module_ctx.os.environ)
            imports = npm_translate_lock_helpers.gen_npm_imports(importers, packages, attr.pnpm_lock.package, attr.name, attr, registries, utils.default_registry(), npm_auth)
            for i in imports:
                npm_import(
                    name = i.name,
                    bins = i.bins,
                    commit = i.commit,
                    custom_postinstall = i.custom_postinstall,
                    deps = i.deps,
                    integrity = i.integrity,
                    lifecycle_hooks = i.lifecycle_hooks,
                    lifecycle_hooks_env = i.lifecycle_hooks_env,
                    link_packages = i.link_packages,
                    npm_auth = i.npm_auth,
                    npm_auth_basic = i.npm_auth_basic,
                    npm_auth_password = i.npm_auth_password,
                    npm_auth_username = i.npm_auth_username,
                    npm_translate_lock_repo = attr.name,
                    package = i.package,
                    patch_args = i.patch_args,
                    patches = i.patches,
                    root_package = i.root_package,
                    transitive_closure = i.transitive_closure,
                    url = i.url,
                    version = i.version,
                    register_copy_directory_toolchains = False,  # this registration is handled elsewhere with bzlmod
                    register_copy_to_directory_toolchains = False,  # this registration is handled elsewhere with bzlmod
                )

        for i in mod.tags.npm_import:
            npm_import(
                name = i.name,
                bins = i.bins,
                commit = i.commit,
                custom_postinstall = i.custom_postinstall,
                integrity = i.integrity,
                lifecycle_hooks = i.lifecycle_hooks,
                lifecycle_hooks_env = i.lifecycle_hooks_env,
                link_packages = i.link_packages,
                link_workspace = i.link_workspace,
                package = i.package,
                patch_args = i.patch_args,
                patches = i.patches,
                root_package = i.root_package,
                url = i.url,
                version = i.version,
                register_copy_directory_toolchains = False,  # this registration is handled elsewhere with bzlmod
                register_copy_to_directory_toolchains = False,  # this registration is handled elsewhere with bzlmod
            )

def _npm_translate_lock_attrs():
    attrs = dict(**npm_translate_lock_lib.attrs)

    # Add macro attrs that aren't in the rule attrs.
    attrs["name"] = attr.string()
    attrs["pnpm_version"] = attr.string(default = LATEST_PNPM_VERSION)

    return attrs

def _npm_import_attrs():
    attrs = dict(**npm_import_lib.attrs)
    attrs.update(**npm_import_links_lib.attrs)

    # Add macro attrs that aren't in the rule attrs.
    attrs["name"] = attr.string()

    return attrs

npm = module_extension(
    implementation = _extension_impl,
    tag_classes = {
        "npm_translate_lock": tag_class(attrs = _npm_translate_lock_attrs()),
        "npm_import": tag_class(attrs = _npm_import_attrs()),
    },
)

def _pnpm_impl(module_ctx):
    for mod in module_ctx.modules:
        for attr in mod.tags.pnpm:
            pnpm_repository(
                name = attr.name,
                pnpm_version = attr.pnpm_version,
            )

pnpm = module_extension(
    implementation = _pnpm_impl,
    tag_classes = {
        "pnpm": tag_class(attrs = {"name": attr.string(), "pnpm_version": attr.string(default = LATEST_PNPM_VERSION)}),
    },
)
