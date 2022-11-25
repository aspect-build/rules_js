"""Adapt repository rules in npm_import.bzl to be called from MODULE.bazel
See https://bazel.build/docs/bzlmod#extension-definition
"""

load("//npm/private:utils.bzl", "utils")
load("//npm/private:npm_translate_lock.bzl", "DEFAULT_REGISTRY", npm_translate_lock_lib = "npm_translate_lock")
load("//npm/private:npm_import.bzl", npm_import_lib = "npm_import")
load("//npm:npm_import.bzl", "npm_import", "npm_translate_lock")
load("//npm/private:transitive_closure.bzl", "translate_to_transitive_closure")
load("//npm/private:npmrc.bzl", "parse_npmrc")

def _extension_impl(module_ctx):
    for mod in module_ctx.modules:
        for attr in mod.tags.npm_translate_lock:
            lockfile = utils.parse_pnpm_lock(module_ctx.read(attr.pnpm_lock))
            trans = translate_to_transitive_closure(lockfile, attr.prod, attr.dev, attr.no_optional)

            registries = {}
            default_registry = DEFAULT_REGISTRY
            npm_tokens = {}
            if attr.npmrc:
                npmrc_path = module_ctx.read(attr.npmrc)
                npmrc = parse_npmrc(npmrc_path)

                (npm_tokens, registries) = npm_translate_lock_lib.get_npm_auth(npmrc, npmrc_path, module_ctx.os.environ)
                if "registry" in npmrc:
                    default_registry = npm_translate_lock_lib.to_registry_url(npmrc["registry"])

            imports = npm_translate_lock_lib.gen_npm_imports(trans, attr.pnpm_lock.package, attr, registries, default_registry, npm_tokens)
            for i in imports:
                npm_import(
                    name = i.name,
                    commit = i.commit,
                    custom_postinstall = i.custom_postinstall,
                    deps = i.deps,
                    integrity = i.integrity,
                    lifecycle_hooks_no_sandbox = attr.lifecycle_hooks_no_sandbox,
                    link_packages = i.link_packages,
                    link_workspace = attr.link_workspace,
                    npm_auth = i.npm_auth,
                    npm_translate_lock_repo = attr.name,
                    package = i.package,
                    patches = i.patches,
                    patch_args = i.patch_args,
                    root_package = i.root_package,
                    run_lifecycle_hooks = i.run_lifecycle_hooks,
                    transitive_closure = i.transitive_closure,
                    url = i.url,
                    version = i.version,
                )

            npm_translate_lock(
                name = attr.name,
                bins = attr.bins,
                custom_postinstalls = attr.custom_postinstalls,
                data = attr.data,
                dev = attr.dev,
                lifecycle_hooks_envs = attr.lifecycle_hooks_envs,
                lifecycle_hooks_exclude = attr.lifecycle_hooks_exclude,
                lifecycle_hooks_execution_requirements = attr.lifecycle_hooks_execution_requirements,
                lifecycle_hooks_no_sandbox = attr.lifecycle_hooks_no_sandbox,
                link_workspace = attr.link_workspace,
                no_optional = attr.no_optional,
                npmrc = attr.npmrc,
                npm_package_lock = attr.npm_package_lock,
                package_json = attr.package_json,
                patches = attr.patches,
                patch_args = attr.patch_args,
                public_hoist_packages = attr.public_hoist_packages,
                pnpm_lock = attr.pnpm_lock,
                pnpm_version = attr.pnpm_version,
                prod = attr.prod,
                run_lifecycle_hooks = attr.run_lifecycle_hooks,
                verify_node_modules_ignored = attr.verify_node_modules_ignored,
                yarn_lock = attr.yarn_lock,
            )

        for i in mod.tags.npm_import:
            npm_import(
                name = i.name,
                commit = i.commit,
                custom_postinstall = i.custom_postinstall,
                extra_build_content = i.extra_build_content,
                integrity = i.integrity,
                lifecycle_hooks_no_sandbox = i.lifecycle_hooks_no_sandbox,
                link_packages = i.link_packages,
                link_workspace = i.link_workspace,
                npm_auth = i.npm_auth,
                package = i.package,
                patches = i.patches,
                patch_args = i.patch_args,
                root_package = i.root_package,
                run_lifecycle_hooks = i.run_lifecycle_hooks,
                url = i.url,
                version = i.version,
            )


def _npm_translate_lock_attrs():
    attrs = dict(**npm_translate_lock_lib.attrs)
    
    # Add macro attrs that aren't in the rule attrs.
    attrs["name"] = attr.string()
    attrs["pnpm_version"] = attr.string() # Defaulting done in macro

    return attrs

def _npm_import_attrs():
    attrs = dict(**npm_import_lib.attrs)
    
    # Add macro attrs that aren't in the rule attrs.
    attrs["name"] = attr.string()
    attrs["lifecycle_hooks_no_sandbox"] = attr.bool(default = True)

    return attrs

npm = module_extension(
    implementation = _extension_impl,
    tag_classes = {
        "npm_translate_lock": tag_class(attrs = _npm_translate_lock_attrs()),
        "npm_import": tag_class(attrs = _npm_import_attrs()),
    },
)
