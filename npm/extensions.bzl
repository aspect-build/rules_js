"""Adapt repository rules in npm_import.bzl to be called from MODULE.bazel
See https://bazel.build/docs/bzlmod#extension-definition
"""

load("//npm/private:utils.bzl", "utils")
load("//npm/private:translate_pnpm_lock.bzl", translate_pnpm_lock_lib = "translate_pnpm_lock")
load("//npm:npm_import.bzl", "npm_import", "translate_pnpm_lock")
load("//npm/private:transitive_closure.bzl", "translate_to_transitive_closure")

def _extension_impl(module_ctx):
    for mod in module_ctx.modules:
        for attr in mod.tags.translate_pnpm_lock:
            lockfile = utils.parse_pnpm_lock(module_ctx.read(attr.pnpm_lock))
            trans = translate_to_transitive_closure(lockfile, attr.prod, attr.dev, attr.no_optional)
            imports = translate_pnpm_lock_lib.gen_npm_imports(trans, attr)
            for i in imports:
                # fixme: pass the rest of the kwargs from i
                npm_import(
                    name = i.name,
                    package = i.package,
                    version = i.pnpm_version,
                    link_packages = i.link_packages,
                )
            translate_pnpm_lock(
                name = "npm",
                pnpm_lock = attr.pnpm_lock,
            )

npm = module_extension(
    implementation = _extension_impl,
    tag_classes = {
        "translate_pnpm_lock": tag_class(attrs = dict({"name": attr.string()}, **translate_pnpm_lock_lib.attrs)),
        # todo: support individual packages as well
        # "package": tag_class(attrs = dict({"name": attr.string()}, **_npm_import.attrs)),
    },
)
