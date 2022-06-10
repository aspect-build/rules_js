"""Adapt repository rules in npm_import.bzl to be called from MODULE.bazel
See https://bazel.build/docs/bzlmod#extension-definition
"""

load("//npm/private:utils.bzl", "utils")
load("//npm/private:npm_translate_lock.bzl", npm_translate_lock_lib = "npm_translate_lock")
load("//npm/private:npm_import.bzl", npm_import_lib = "npm_import")
load("//npm:npm_import.bzl", "npm_import", "npm_translate_lock")
load("//npm/private:transitive_closure.bzl", "translate_to_transitive_closure")

def _extension_impl(module_ctx):
    for mod in module_ctx.modules:
        for attr in mod.tags.npm_translate_lock:
            lockfile = utils.parse_pnpm_lock(module_ctx.read(attr.pnpm_lock))
            trans = translate_to_transitive_closure(lockfile, attr.prod, attr.dev, attr.no_optional)
            imports = npm_translate_lock_lib.gen_npm_imports(trans, attr)
            for i in imports:
                npm_import(
                    name = i.name,
                    package = i.package,
                    version = i.version,
                    link_packages = i.link_packages,
                    custom_postinstall = i.custom_postinstall,
                    deps = i.deps,
                    integrity = i.integrity,
                    patch_args = i.patch_args,
                    patches = i.patches,
                    root_package = i.root_package,
                    run_lifecycle_hooks = i.run_lifecycle_hooks,
                    transitive_closure = i.transitive_closure,
                    url = i.url,
                )
            npm_translate_lock(
                name = "npm",
                pnpm_lock = attr.pnpm_lock,
            )
        for i in mod.tags.npm_package:
            npm_import(
                name = i.name,
                package = i.package,
                version = i.version,
                link_packages = i.link_packages,
                integrity = i.integrity,
                patch_args = i.patch_args,
                patches = i.patches,
                run_lifecycle_hooks = i.run_lifecycle_hooks,
                custom_postinstall = i.custom_postinstall,
                link_workspace = i.link_workspace,
                url = i.url,
                root_package = i.root_package,
            )

npm = module_extension(
    implementation = _extension_impl,
    tag_classes = {
        "npm_translate_lock": tag_class(attrs = dict({"name": attr.string()}, **npm_translate_lock_lib.attrs)),
        "npm_package": tag_class(attrs = dict({"name": attr.string()}, **npm_import_lib.attrs)),
    },
)
