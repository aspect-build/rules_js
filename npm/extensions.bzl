"""Adapt repository rules in npm_import.bzl to be called from MODULE.bazel
See https://bazel.build/docs/bzlmod#extension-definition
"""

load("//npm/private:utils.bzl", "utils")
load("//npm/private:npm_translate_lock_generate.bzl", npm_translate_lock_helpers = "helpers")
load("//npm/private:npm_translate_lock.bzl", "npm_translate_lock_lib")
load("//npm/private:npm_import.bzl", npm_import_lib = "npm_import")
load("//npm:npm_import.bzl", "npm_import", "npm_translate_lock")
load("//npm/private:transitive_closure.bzl", "translate_to_transitive_closure")
load("//npm/private:versions.bzl", "PNPM_VERSIONS")

LATEST_PNPM_VERSION = PNPM_VERSIONS.keys()[-1]

def _extension_impl(module_ctx):
    for mod in module_ctx.modules:
        for attr in mod.tags.npm_translate_lock:
            # npm_translate_lock MUST run before parse_pnpm_lock below since it may update
            # the pnpm-lock.yaml file when update_pnpm_lock is True.
            npm_translate_lock(
                name = attr.name,
                pnpm_lock = attr.pnpm_lock,
                pnpm_version =  attr.pnpm_version,
                # TODO: get this working with bzlmod
                # update_pnpm_lock = attr.update_pnpm_lock,
            )

        for attr in mod.tags.npm_translate_lock:
            # TODO: registries was introduced in https://github.com/aspect-build/rules_js/pull/503
            # but not added to bzlmod. For now, not supported here.
            registries = {}
            lock_importers, lock_packages = utils.parse_pnpm_lock(module_ctx.read(attr.pnpm_lock))
            importers, packages = translate_to_transitive_closure(lock_importers, lock_packages, attr.prod, attr.dev, attr.no_optional)
            imports = npm_translate_lock_helpers.gen_npm_imports(importers, packages, attr.pnpm_lock.package, attr.name, attr, registries, utils.default_registry())
            for i in imports:
                npm_import(
                    name = i.name,
                    custom_postinstall = i.custom_postinstall,
                    deps = i.deps,
                    integrity = i.integrity,
                    lifecycle_hooks = i.lifecycle_hooks,
                    link_packages = i.link_packages,
                    npm_translate_lock_repo = attr.name,
                    package = i.package,
                    patch_args = i.patch_args,
                    patches = i.patches,
                    root_package = i.root_package,
                    transitive_closure = i.transitive_closure,
                    url = i.url,
                    version = i.version,
                )

        for i in mod.tags.npm_import:
            npm_import(
                name = i.name,
                custom_postinstall = i.custom_postinstall,
                integrity = i.integrity,
                lifecycle_hooks = i.lifecycle_hooks,
                link_packages = i.link_packages,
                link_workspace = i.link_workspace,
                package = i.package,
                patch_args = i.patch_args,
                patches = i.patches,
                root_package = i.root_package,
                url = i.url,
                version = i.version,
            )

def _npm_translate_lock_attrs():
    attrs = dict(**npm_translate_lock_lib.attrs)

    # Add macro attrs that aren't in the rule attrs.
    attrs["name"] = attr.string()
    attrs["pnpm_version"] = attr.string(default = LATEST_PNPM_VERSION)

    return attrs

def _npm_import_attrs():
    attrs = dict(**npm_import_lib.attrs)

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
