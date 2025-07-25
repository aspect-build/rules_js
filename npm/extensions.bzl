"""Adapt npm repository rules to be called from MODULE.bazel
See https://bazel.build/docs/bzlmod#extension-definition
"""

load("@aspect_bazel_lib//lib:repo_utils.bzl", "repo_utils")
load("@aspect_bazel_lib//lib:utils.bzl", bazel_lib_utils = "utils")
load("@aspect_tools_telemetry_report//:defs.bzl", "TELEMETRY")  # buildifier: disable=load
load("@bazel_features//:features.bzl", "bazel_features")
load("//npm:repositories.bzl", "npm_import", "pnpm_repository", _DEFAULT_PNPM_VERSION = "DEFAULT_PNPM_VERSION", _LATEST_PNPM_VERSION = "LATEST_PNPM_VERSION")
load("//npm/private:exclude_package_contents_default.bzl", "exclude_package_contents_default")
load("//npm/private:npm_import.bzl", "npm_import_lib", "npm_import_links_lib")
load("//npm/private:npm_translate_lock.bzl", "npm_translate_lock_lib", "npm_translate_lock_rule")
load("//npm/private:npm_translate_lock_helpers.bzl", npm_translate_lock_helpers = "helpers")
load("//npm/private:npm_translate_lock_macro_helpers.bzl", macro_helpers = "helpers")
load("//npm/private:npm_translate_lock_state.bzl", "npm_translate_lock_state")
load("//npm/private:npmrc.bzl", "parse_npmrc")
load("//npm/private:pnpm_extension.bzl", "DEFAULT_PNPM_REPO_NAME", "resolve_pnpm_repositories")
load("//npm/private:tar.bzl", "detect_system_tar")
load("//npm/private:transitive_closure.bzl", "translate_to_transitive_closure")

DEFAULT_PNPM_VERSION = _DEFAULT_PNPM_VERSION
LATEST_PNPM_VERSION = _LATEST_PNPM_VERSION

def _npm_extension_impl(module_ctx):
    if not bazel_lib_utils.is_bazel_6_or_greater():
        # ctx.actions.declare_symlink was added in Bazel 6
        fail("A minimum version of Bazel 6 required to use rules_js")

    # Collect all exclude_package_contents tags and build exclusion dictionary
    exclude_package_contents_config = _build_exclude_package_contents_config(module_ctx)

    for mod in module_ctx.modules:
        for attr in mod.tags.npm_translate_lock:
            _npm_translate_lock_bzlmod(attr, exclude_package_contents_config)

            # We cannot read the pnpm_lock file before it has been bootstrapped.
            # See comment in e2e/update_pnpm_lock_with_import/test.sh.
            if attr.pnpm_lock:
                if hasattr(module_ctx, "watch"):
                    module_ctx.watch(attr.pnpm_lock)
                _npm_lock_imports_bzlmod(module_ctx, attr, exclude_package_contents_config)

        for i in mod.tags.npm_import:
            _npm_import_bzlmod(i)

    if bazel_features.external_deps.extension_metadata_has_reproducible:
        return module_ctx.extension_metadata(
            reproducible = True,
        )
    return module_ctx.extension_metadata()

def _build_exclude_package_contents_config(module_ctx):
    """Build exclude_package_contents configuration from tags across all modules."""
    exclusions = {}

    for mod in module_ctx.modules:
        for exclude_tag in mod.tags.npm_exclude_package_contents:
            # Process the package in the tag
            package = exclude_tag.package
            if package in exclusions:
                fail("Duplicate exclude_package_contents tag for package: {}".format(package))

            exclusions[package] = []

            # Add default exclusions if requested
            if exclude_tag.use_defaults:
                exclusions[package].extend(exclude_package_contents_default)

            # Add custom patterns
            exclusions[package].extend(exclude_tag.patterns)

    return exclusions

def _npm_translate_lock_bzlmod(attr, exclude_package_contents_config):
    npm_translate_lock_rule(
        name = attr.name,
        bins = attr.bins,
        custom_postinstalls = attr.custom_postinstalls,
        data = attr.data,
        dev = attr.dev,
        external_repository_action_cache = attr.external_repository_action_cache,
        generate_bzl_library_targets = attr.generate_bzl_library_targets,
        link_workspace = attr.link_workspace,
        no_optional = attr.no_optional,
        npmrc = attr.npmrc,
        npm_package_lock = attr.npm_package_lock,
        npm_package_target_name = attr.npm_package_target_name,
        package_visibility = attr.package_visibility,
        patches = attr.patches,
        patch_args = attr.patch_args,
        pnpm_lock = attr.pnpm_lock,
        use_pnpm = attr.use_pnpm,
        preupdate = attr.preupdate,
        prod = attr.prod,
        public_hoist_packages = attr.public_hoist_packages,
        quiet = attr.quiet,
        replace_packages = attr.replace_packages,
        root_package = attr.root_package,
        update_pnpm_lock = attr.update_pnpm_lock,
        use_home_npmrc = attr.use_home_npmrc,
        verify_node_modules_ignored = attr.verify_node_modules_ignored,
        verify_patches = attr.verify_patches,
        yarn_lock = attr.yarn_lock,
        exclude_package_contents = exclude_package_contents_config,
        bzlmod = True,
    )

def _npm_lock_imports_bzlmod(module_ctx, attr, exclude_package_contents_config):
    state = npm_translate_lock_state.new(attr.name, module_ctx, attr, True)

    importers, packages = translate_to_transitive_closure(
        state.importers(),
        state.packages(),
        attr.prod,
        attr.dev,
        attr.no_optional,
    )

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
        exclude_package_contents_config = exclude_package_contents_config,
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
            # attr.pnpm_lock.repo_name is a canonical repository name, so it needs to be qualified with an extra '@'.
            link_workspace = attr.link_workspace if attr.link_workspace else "@" + attr.pnpm_lock.repo_name,
            npm_auth = i.npm_auth,
            npm_auth_basic = i.npm_auth_basic,
            npm_auth_password = i.npm_auth_password,
            npm_auth_username = i.npm_auth_username,
            package = i.package,
            package_visibility = i.package_visibility,
            patch_tool = i.patch_tool,
            patch_args = i.patch_args,
            patches = i.patches,
            exclude_package_contents = i.exclude_package_contents,
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
        patch_tool = i.patch_tool,
        patch_args = i.patch_args,
        patches = i.patches,
        exclude_package_contents = i.exclude_package_contents,
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
    attrs.pop("exclude_package_contents")  # Use tag classes only for MODULE.bazel

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

def _npm_exclude_package_contents_attrs():
    return {
        "package": attr.string(
            doc = "Package name to apply exclusions to. Supports wildcards like '*' for all packages.",
            mandatory = True,
        ),
        "patterns": attr.string_list(
            doc = "List of glob patterns to exclude from the specified package.",
            default = [],
        ),
        "use_defaults": attr.bool(
            doc = "Whether to use default exclusion patterns for the specified package. Defaults are as to Yarn autoclean: https://github.com/yarnpkg/yarn/blob/7cafa512a777048ce0b666080a24e80aae3d66a9/src/cli/commands/autoclean.js#L16",
            default = False,
        ),
    }

npm = module_extension(
    implementation = _npm_extension_impl,
    tag_classes = {
        "npm_translate_lock": tag_class(attrs = _npm_translate_lock_attrs()),
        "npm_import": tag_class(attrs = _npm_import_attrs()),
        "npm_exclude_package_contents": tag_class(attrs = _npm_exclude_package_contents_attrs()),
    },
)

def _pnpm_extension_impl(module_ctx):
    resolved = resolve_pnpm_repositories(module_ctx.modules)

    for note in resolved.notes:
        # buildifier: disable=print
        print(note)

    for name, pnpm_version in resolved.repositories.items():
        pnpm_repository(
            name = name,
            pnpm_version = pnpm_version,
        )

pnpm = module_extension(
    implementation = _pnpm_extension_impl,
    tag_classes = {
        "pnpm": tag_class(
            attrs = {
                "name": attr.string(
                    doc = """Name of the generated repository, allowing more than one pnpm version to be registered.
                        Overriding the default is only permitted in the root module.""",
                    default = DEFAULT_PNPM_REPO_NAME,
                ),
                "pnpm_version": attr.string(
                    doc = "pnpm version to use. The string `latest` will be resolved to LATEST_PNPM_VERSION.",
                    default = DEFAULT_PNPM_VERSION,
                ),
                "pnpm_version_integrity": attr.string(),
            },
        ),
    },
)
