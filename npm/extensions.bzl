"""Adapt npm repository rules to be called from MODULE.bazel
See https://bazel.build/docs/bzlmod#extension-definition
"""

load("@aspect_bazel_lib//lib:repo_utils.bzl", "repo_utils")
load("@aspect_bazel_lib//lib:utils.bzl", bazel_lib_utils = "utils")
load("@bazel_features//:features.bzl", "bazel_features")
load("//npm:repositories.bzl", "npm_import", "pnpm_repository", _DEFAULT_PNPM_VERSION = "DEFAULT_PNPM_VERSION", _LATEST_PNPM_VERSION = "LATEST_PNPM_VERSION")
load("//npm/private:npm_import.bzl", "npm_import_lib", "npm_import_links_lib")
load("//npm/private:npm_translate_lock.bzl", "npm_translate_lock_bzlmod_impl", "npm_translate_lock_lib", "npm_translate_lock_verify")
load("//npm/private:npm_translate_lock_helpers.bzl", npm_translate_lock_helpers = "helpers")
load("//npm/private:npm_translate_lock_macro_helpers.bzl", macro_helpers = "helpers")
load("//npm/private:npm_translate_lock_state.bzl", "npm_translate_lock_state")
load("//npm/private:npmrc.bzl", "parse_npmrc")
load("//npm/private:tar.bzl", "detect_system_tar")
load("//npm/private:transitive_closure.bzl", "translate_to_transitive_closure")

DEFAULT_PNPM_VERSION = _DEFAULT_PNPM_VERSION
LATEST_PNPM_VERSION = _LATEST_PNPM_VERSION

_DEFAULT_PNPM_REPO_NAME = "pnpm"

def _npm_extension_impl(module_ctx):
    if not bazel_lib_utils.is_bazel_6_or_greater():
        # ctx.actions.declare_symlink was added in Bazel 6
        fail("A minimum version of Bazel 6 required to use rules_js")

    for mod in module_ctx.modules:
        for attr in mod.tags.npm_translate_lock:
            _npm_translate_lock_bzlmod(module_ctx, attr)

        for i in mod.tags.npm_import:
            _npm_import_bzlmod(i)

    if bazel_features.external_deps.extension_metadata_has_reproducible:
        return module_ctx.extension_metadata(
            reproducible = True,
        )
    return module_ctx.extension_metadata()

def _npm_translate_lock_bzlmod(module_ctx, attr):
    module_ctx.report_progress("Initializing")

    state = npm_translate_lock_state.new(attr.name, module_ctx, attr, True)

    npm_translate_lock_verify(module_ctx, attr, state)

    module_ctx.report_progress("Translating {}".format(state.label_store.relative_path("pnpm_lock")))

    importers, packages = translate_to_transitive_closure(
        state.importers(),
        state.packages(),
        attr.prod,
        attr.dev,
        attr.no_optional,
    )

    npm_translate_lock_bzlmod_impl(module_ctx, attr, state, importers, packages)

    # We cannot read the pnpm_lock file before it has been bootstrapped.
    # See comment in e2e/update_pnpm_lock_with_import/test.sh.
    if attr.pnpm_lock:
        _npm_lock_imports_bzlmod(module_ctx, attr, state, importers, packages)

def _npm_lock_imports_bzlmod(module_ctx, attr, state, importers, packages):
    registries = {}
    npm_auth = {}
    if attr.npmrc:
        npmrc = parse_npmrc(module_ctx.read(attr.npmrc))
        (registries, npm_auth) = npm_translate_lock_helpers.get_npm_auth(npmrc, module_ctx.path(attr.npmrc), module_ctx.os.environ)

    if attr.use_home_npmrc:
        home_directory = repo_utils.get_home_directory(module_ctx)
        if home_directory:
            home_npmrc_path = "{}/{}".format(home_directory, ".npmrc")
            home_npmrc = parse_npmrc(module_ctx.read(home_npmrc_path))

            (registries2, npm_auth2) = npm_translate_lock_helpers.get_npm_auth(home_npmrc, home_npmrc_path, module_ctx.os.environ)
            registries.update(registries2)
            npm_auth.update(npm_auth2)
        else:
            # buildifier: disable=print
            print("""
WARNING: Cannot determine home directory in order to load home `.npmrc` file in module extension `npm_translate_lock(name = "{attr_name}")`.
""".format(attr_name = attr.name))

    lifecycle_hooks, lifecycle_hooks_execution_requirements, lifecycle_hooks_use_default_shell_env = macro_helpers.macro_lifecycle_args_to_rule_attrs(
        lifecycle_hooks = attr.lifecycle_hooks,
        lifecycle_hooks_exclude = attr.lifecycle_hooks_exclude,
        run_lifecycle_hooks = attr.run_lifecycle_hooks,
        lifecycle_hooks_no_sandbox = attr.lifecycle_hooks_no_sandbox,
        lifecycle_hooks_execution_requirements = attr.lifecycle_hooks_execution_requirements,
        lifecycle_hooks_use_default_shell_env = attr.lifecycle_hooks_use_default_shell_env,
    )
    imports = npm_translate_lock_helpers.get_npm_imports(
        importers = importers,
        packages = packages,
        patched_dependencies = state.patched_dependencies(),
        only_built_dependencies = state.only_built_dependencies(),
        root_package = attr.pnpm_lock.package,
        rctx_name = attr.name,
        attr = attr,
        all_lifecycle_hooks = lifecycle_hooks,
        all_lifecycle_hooks_execution_requirements = lifecycle_hooks_execution_requirements,
        all_lifecycle_hooks_use_default_shell_env = lifecycle_hooks_use_default_shell_env,
        registries = registries,
        default_registry = state.default_registry(),
        npm_auth = npm_auth,
    )

    system_tar = detect_system_tar(module_ctx)

    for i in imports:
        npm_import(
            name = i.name,
            bins = i.bins,
            commit = i.commit,
            custom_postinstall = i.custom_postinstall,
            deps = i.deps,
            dev = i.dev,
            integrity = i.integrity,
            generate_bzl_library_targets = attr.generate_bzl_library_targets,
            lifecycle_hooks = i.lifecycle_hooks if i.lifecycle_hooks else [],
            lifecycle_hooks_env = i.lifecycle_hooks_env,
            lifecycle_hooks_execution_requirements = i.lifecycle_hooks_execution_requirements,
            lifecycle_hooks_use_default_shell_env = i.lifecycle_hooks_use_default_shell_env,
            link_packages = i.link_packages,
            # attr.pnpm_lock.workspace_name is a canonical repository name, so it needs to be qualified with an extra '@'.
            link_workspace = attr.link_workspace if attr.link_workspace else "@" + attr.pnpm_lock.workspace_name,
            npm_auth = i.npm_auth,
            npm_auth_basic = i.npm_auth_basic,
            npm_auth_password = i.npm_auth_password,
            npm_auth_username = i.npm_auth_username,
            package = i.package,
            package_visibility = i.package_visibility,
            patch_args = i.patch_args,
            patches = i.patches,
            replace_package = i.replace_package,
            root_package = i.root_package,
            transitive_closure = i.transitive_closure,
            system_tar = system_tar,
            url = i.url,
            version = i.version,
        )

def _npm_import_bzlmod(i):
    npm_import(
        name = i.name,
        bins = i.bins,
        commit = i.commit,
        custom_postinstall = i.custom_postinstall,
        deps = i.deps,
        dev = i.dev,
        extra_build_content = i.extra_build_content,
        integrity = i.integrity,
        lifecycle_hooks = i.lifecycle_hooks,
        lifecycle_hooks_env = i.lifecycle_hooks_env,
        lifecycle_hooks_execution_requirements = i.lifecycle_hooks_execution_requirements,
        lifecycle_hooks_use_default_shell_env = i.lifecycle_hooks_use_default_shell_env,
        link_packages = i.link_packages,
        link_workspace = i.link_workspace,
        npm_auth = i.npm_auth,
        npm_auth_basic = i.npm_auth_basic,
        npm_auth_username = i.npm_auth_username,
        npm_auth_password = i.npm_auth_password,
        package = i.package,
        package_visibility = i.package_visibility,
        patch_args = i.patch_args,
        patches = i.patches,
        replace_package = i.replace_package,
        root_package = i.root_package,
        transitive_closure = i.transitive_closure,
        url = i.url,
        version = i.version,
    )

def _npm_translate_lock_attrs():
    attrs = dict(**npm_translate_lock_lib.attrs)

    # Add macro attrs that aren't in the rule attrs.
    attrs["name"] = attr.string()
    attrs["lifecycle_hooks_exclude"] = attr.string_list(default = [])
    attrs["lifecycle_hooks_no_sandbox"] = attr.bool(default = True)
    attrs["run_lifecycle_hooks"] = attr.bool(default = True)

    # Args defaulted differently by the macro
    attrs["npm_package_target_name"] = attr.string(default = "pkg")
    attrs["patch_args"] = attr.string_list_dict(default = {"*": ["-p0"]})

    # Args not supported or unnecessary in bzlmod
    attrs.pop("repositories_bzl_filename")

    return attrs

def _npm_import_attrs():
    attrs = dict(**npm_import_lib.attrs)
    attrs.update(**npm_import_links_lib.attrs)

    # Add macro attrs that aren't in the rule attrs.
    attrs["name"] = attr.string()
    attrs["lifecycle_hooks_no_sandbox"] = attr.bool(default = False)
    attrs["run_lifecycle_hooks"] = attr.bool(default = False)

    # Args defaulted differently by the macro
    attrs["lifecycle_hooks_execution_requirements"] = attr.string_list(default = ["no-sandbox"])
    attrs["patch_args"] = attr.string_list(default = ["-p0"])
    attrs["package_visibility"] = attr.string_list(default = ["//visibility:public"])

    return attrs

npm = module_extension(
    implementation = _npm_extension_impl,
    tag_classes = {
        "npm_translate_lock": tag_class(attrs = _npm_translate_lock_attrs()),
        "npm_import": tag_class(attrs = _npm_import_attrs()),
    },
)

# copied from https://github.com/bazelbuild/bazel-skylib/blob/b459822483e05da514b539578f81eeb8a705d600/lib/versions.bzl#L60
# to avoid taking a dependency on skylib here
def _parse_version(version):
    return tuple([int(n) for n in version.split(".")])

def _pnpm_extension_impl(module_ctx):
    registrations = {}
    integrity = {}
    for mod in module_ctx.modules:
        for attr in mod.tags.pnpm:
            if attr.name != _DEFAULT_PNPM_REPO_NAME and not mod.is_root:
                fail("""\
                Only the root module may override the default name for the pnpm repository.
                This prevents conflicting registrations in the global namespace of external repos.
                """)
            if attr.name not in registrations.keys():
                registrations[attr.name] = []
            registrations[attr.name].append(attr.pnpm_version)
            if attr.pnpm_version_integrity:
                integrity[attr.pnpm_version] = attr.pnpm_version_integrity
    for name, versions in registrations.items():
        # Use "Minimal Version Selection" like bzlmod does for resolving module conflicts
        # Note, the 'sorted(list)' function in starlark doesn't allow us to provide a custom comparator
        if len(versions) > 1:
            selected = versions[0]
            selected_tuple = _parse_version(selected)
            for idx in range(1, len(versions)):
                if _parse_version(versions[idx]) > selected_tuple:
                    selected = versions[idx]
                    selected_tuple = _parse_version(selected)

            # buildifier: disable=print
            print("NOTE: repo '{}' has multiple versions {}; selected {}".format(name, versions, selected))
        else:
            selected = versions[0]

        pnpm_repository(
            name = name,
            pnpm_version = (selected, integrity[selected]) if selected in integrity.keys() else selected,
        )

pnpm = module_extension(
    implementation = _pnpm_extension_impl,
    tag_classes = {
        "pnpm": tag_class(
            attrs = {
                "name": attr.string(
                    doc = """Name of the generated repository, allowing more than one pnpm version to be registered.
                        Overriding the default is only permitted in the root module.""",
                    default = _DEFAULT_PNPM_REPO_NAME,
                ),
                "pnpm_version": attr.string(default = DEFAULT_PNPM_VERSION),
                "pnpm_version_integrity": attr.string(),
            },
        ),
    },
)
