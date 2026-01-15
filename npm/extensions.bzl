"""Adapt npm repository rules to be called from MODULE.bazel
See https://bazel.build/docs/bzlmod#extension-definition
"""

load("@bazel_lib//lib:repo_utils.bzl", "repo_utils")
load("//npm/private:npm_import.bzl", "npm_import", "npm_import_lib")
load("//npm/private:npm_translate_lock.bzl", "npm_translate_lock_lib", "parse_and_verify_lock")
load("//npm/private:npm_translate_lock_generate.bzl", "generate_repository_files")
load("//npm/private:npm_translate_lock_helpers.bzl", npm_translate_lock_helpers = "helpers")
load("//npm/private:npm_translate_lock_macro_helpers.bzl", macro_helpers = "helpers")
load("//npm/private:npmrc.bzl", "parse_npmrc")
load("//npm/private:pnpm_extension.bzl", "DEFAULT_PNPM_REPO_NAME", "resolve_pnpm_repositories")
load("//npm/private:pnpm_repository.bzl", "pnpm_repository", _DEFAULT_PNPM_VERSION = "DEFAULT_PNPM_VERSION", _LATEST_PNPM_VERSION = "LATEST_PNPM_VERSION")

DEFAULT_PNPM_VERSION = _DEFAULT_PNPM_VERSION
LATEST_PNPM_VERSION = _LATEST_PNPM_VERSION

_FORBIDDEN_OVERRIDE_TAG = """\
The "npm.{tag_class}" tag can only be used in the root Bazel module, \
but module "{module_name}" attempted to use it.

Package replacements affect the entire dependency graph and must be controlled \
by the root module to ensure consistency across all dependencies.

If you need to replace a package in a non-root module move the npm_replace_package() call to your root MODULE.bazel file

For more information, see: https://github.com/aspect-build/rules_js/blob/main/docs/pnpm.md
"""

def _fail_on_non_root_overrides(module, tag_class):
    """Prevents non-root modules from using restricted tags.

    Args:
        module: The module being processed
        tag_class: The name of the tag class to check (e.g., "npm_replace_package")
    """
    if module.is_root:
        return

    if getattr(module.tags, tag_class):
        fail(_FORBIDDEN_OVERRIDE_TAG.format(
            tag_class = tag_class,
            module_name = module.name,
        ))

def _npm_extension_impl(module_ctx):
    # Collect all exclude_package_contents tags and build exclusion dictionary
    exclude_package_contents_config = _build_exclude_package_contents_config(module_ctx)

    # Collect all package replacements across all modules
    replace_packages = {}
    for mod in module_ctx.modules:
        # Validate that only root modules (or isolated extensions) use npm_replace_package
        _fail_on_non_root_overrides(mod, "npm_replace_package")

        for attr in mod.tags.npm_replace_package:
            if attr.package in replace_packages:
                fail("Package '{}' already has a replacement defined in another module".format(attr.package))
            replace_packages[attr.package] = "@@{}//{}:{}".format(attr.replacement.repo_name, attr.replacement.package, attr.replacement.name)

    # Process npm_translate_lock and npm_import tags
    for mod in module_ctx.modules:
        for attr in mod.tags.npm_translate_lock:
            _npm_translate_lock_bzlmod(module_ctx, attr, exclude_package_contents_config, replace_packages)

        for i in mod.tags.npm_import:
            _npm_import_bzlmod(i)

    return module_ctx.extension_metadata(reproducible = True)

def _build_exclude_package_contents_config(module_ctx):
    """Build exclude_package_contents configuration from tags across all modules."""
    exclusions = {}

    for mod in module_ctx.modules:
        for exclude_tag in mod.tags.npm_exclude_package_contents:
            # Process the package in the tag
            package = exclude_tag.package
            if package in exclusions:
                fail("Duplicate exclude_package_contents tag for package: {}".format(package))

            # Store patterns and presets separately - don't expand here,
            # they will be processed via npm_import attributes
            exclusions[package] = struct(
                patterns = exclude_tag.patterns,
                presets = exclude_tag.presets,
            )

    return exclusions

def _hub_repo_impl(rctx):
    for path, contents in rctx.attr.contents.items():
        rctx.file(path, contents)

    # Support bazel <v8.3 by returning None if repo_metadata is not defined
    if not hasattr(rctx, "repo_metadata"):
        return None

    return rctx.repo_metadata(reproducible = True)

_hub_repo = repository_rule(
    implementation = _hub_repo_impl,
    attrs = {
        "contents": attr.string_dict(
            doc = "A mapping of file names to text they should contain.",
            mandatory = True,
        ),
    },
)

def _npm_translate_lock_bzlmod(module_ctx, attr, exclude_package_contents_config, replace_packages):
    state = parse_and_verify_lock(module_ctx, attr.name, attr)

    module_ctx.report_progress("Generating starlark for npm dependencies")

    registries = {}
    npm_auth = {}
    if attr.npmrc:
        npmrc = parse_npmrc(module_ctx.read(attr.npmrc))
        (registries, npm_auth) = npm_translate_lock_helpers.get_npm_auth(npmrc, module_ctx.path(attr.npmrc), module_ctx)

    if attr.use_home_npmrc:
        home_directory = repo_utils.get_home_directory(module_ctx)
        if home_directory:
            home_npmrc_path = "{}/{}".format(home_directory, ".npmrc")
            home_npmrc = parse_npmrc(module_ctx.read(home_npmrc_path))

            (registries2, npm_auth2) = npm_translate_lock_helpers.get_npm_auth(home_npmrc, home_npmrc_path, module_ctx)
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
        importers = state.importers(),
        packages = state.packages(),
        replace_packages = replace_packages,
        pnpm_patched_dependencies = state.pnpm_patched_dependencies(),
        only_built_dependencies = state.only_built_dependencies(),
        root_package = state.root_package(),
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

    for i in imports:
        npm_import(
            name = i.repo_name,
            key = i.package_key,
            bins = i.bins,
            commit = i.commit,
            custom_postinstall = i.custom_postinstall,
            deps = i.deps,
            deps_constraints = i.deps_constraints,
            integrity = i.integrity,
            generate_package_json_bzl = i.is_direct_dep,
            extract_full_archive = None,
            extra_build_content = "",
            generate_bzl_library_targets = attr.generate_bzl_library_targets,
            lifecycle_hooks = i.lifecycle_hooks if i.lifecycle_hooks else [],
            lifecycle_hooks_env = i.lifecycle_hooks_env,
            lifecycle_hooks_execution_requirements = i.lifecycle_hooks_execution_requirements,
            lifecycle_hooks_use_default_shell_env = i.lifecycle_hooks_use_default_shell_env,
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
            exclude_package_contents_presets = i.exclude_package_contents_presets,
            replace_package = i.replace_package,
            root_package = state.root_package(),
            transitive_closure = i.transitive_closure,
            url = i.url,
            version = i.version,
        )

    files = generate_repository_files(
        attr.name,
        attr,
        state,
        imports,
    )

    _hub_repo(
        name = attr.name,
        contents = files,
    )

def _npm_import_bzlmod(i):
    # Assume package+version is a unique key for any package store this import is placed in
    package_key = "{}@{}".format(i.package, i.version)

    npm_import(
        name = i.name,
        key = package_key,
        generate_package_json_bzl = True,  # Always generate package_json.bzl explicitly declared imports
        generate_bzl_library_targets = None,
        extract_full_archive = None,
        bins = i.bins,
        commit = i.commit,
        custom_postinstall = i.custom_postinstall,
        deps = i.deps,
        deps_constraints = None,
        extra_build_content = i.extra_build_content,
        integrity = i.integrity,
        lifecycle_hooks = i.lifecycle_hooks,
        lifecycle_hooks_env = i.lifecycle_hooks_env,
        lifecycle_hooks_execution_requirements = i.lifecycle_hooks_execution_requirements,
        lifecycle_hooks_use_default_shell_env = i.lifecycle_hooks_use_default_shell_env,
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
        exclude_package_contents_presets = i.exclude_package_contents_presets,
        replace_package = i.replace_package,
        root_package = i.root_package,
        transitive_closure = None,
        url = i.url,
        version = i.version,
    )

_NPM_IMPORT_ATTRS = npm_import_lib.attrs | {
    # Add macro attrs that aren't in the rule attrs.
    "name": attr.string(),

    # Attributes only used within the module extension implementation, not passed
    # along to the npm_import[_links] rules.
    "lifecycle_hooks_no_sandbox": attr.bool(default = False),
    "run_lifecycle_hooks": attr.bool(default = False),
}

_EXCLUDE_PACKAGE_CONTENT_ATTRS = {
    "package": attr.string(
        doc = "Package name to apply exclusions to. Supports wildcards like '*' for all packages.",
        mandatory = True,
    ),
    "patterns": attr.string_list(
        doc = "List of glob patterns to exclude from the specified package.",
        default = [],
    ),
    "presets": attr.string_list(
        doc = """\
Which preset exclusion patterns to include. Multiple presets can be combined. Valid values:
- "basic": basic exclusions such as README files, tests, and development files.
- "yarn_autoclean": Yarn autoclean exclusions (see https://github.com/yarnpkg/yarn/blob/7cafa512a777048ce0b666080a24e80aae3d66a9/src/cli/commands/autoclean.js#L16)
""",
        default = ["basic"],
    ),
}

_EXCLUDE_PACKAGE_CONTENT_DOCS = """Configuration for excluding package contents from npm packages.

This tag can be used multiple times to specify different exclusion patterns for different package specifiers.
More specific package matches override less specific ones (the wildcard "*" is only used if no specific
package match is found).

By default, `presets` is set to `["basic"]` which excludes common files such as `*.md` and development-related
files. Multiple presets can be combined.

Example:
```
npm.npm_exclude_package_contents(
    package = "*",
    patterns = ["**/docs/**"],
)
npm.npm_exclude_package_contents(
    package = "my-package@1.2.3",
    # Overrides the "*" config for this specific package
    presets = ["yarn_autoclean"],
)
```
"""

_REPLACE_PACKAGE_ATTRS = {
    "package": attr.string(
        doc = "The package name and version to replace (e.g., 'chalk@5.3.0')",
        mandatory = True,
    ),
    "replacement": attr.label(
        doc = "The target to use as replacement for this package",
        mandatory = True,
    ),
}
_REPLACE_PACKAGE_DOCS = """Replace a package with a custom target.

This allows replacing packages declared in package.json with custom implementations.
Multiple npm_replace_package tags can be used to replace different packages.

Targets must produce `JsInfo` or `NpmPackageInfo` providers such as `js_library` or `npm_package` targets.

The injected package targets may optionally contribute transitive npm package dependencies on top
of the transitive dependencies specified in the pnpm lock file for their respective packages, however, these
transitive dependencies must not collide with pnpm lock specified transitive dependencies.

Any patches specified for the packages will be not applied to the injected package targets. They
will be applied, however, to the fetches sources for their respecitve packages so they can still be useful
for patching the fetched `package.json` files, which are used to determine the generated bin entries for packages.

NB: lifecycle hooks and custom_postinstall scripts, if implicitly or explicitly enabled, will be run on
the injected package targets. These may be disabled explicitly using the `lifecycle_hooks` attribute.

Example:
```starlark
npm.npm_replace_package(
    package = "chalk@5.3.0",
    replacement = "@chalk_501//:pkg",
)
```"""

npm = module_extension(
    implementation = _npm_extension_impl,
    tag_classes = {
        "npm_translate_lock": tag_class(attrs = npm_translate_lock_lib.attrs, doc = npm_translate_lock_lib.doc),
        "npm_import": tag_class(attrs = _NPM_IMPORT_ATTRS, doc = npm_import_lib.doc),
        "npm_exclude_package_contents": tag_class(attrs = _EXCLUDE_PACKAGE_CONTENT_ATTRS, doc = _EXCLUDE_PACKAGE_CONTENT_DOCS),
        "npm_replace_package": tag_class(attrs = _REPLACE_PACKAGE_ATTRS, doc = _REPLACE_PACKAGE_DOCS),
    },
)

def _pnpm_extension_impl(module_ctx):
    resolved = resolve_pnpm_repositories(module_ctx)

    for note in resolved.notes:
        # buildifier: disable=print
        print(note)

    for name, pnpm in resolved.repositories.items():
        pnpm_repository(
            name = name,
            pnpm_version = pnpm["version"],
            include_npm = pnpm["include_npm"],
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
                "include_npm": attr.bool(
                    doc = "If true, include the npm package along with the pnpm binary.",
                    default = False,
                ),
                "pnpm_version": attr.string(
                    doc = "pnpm version to use. The string `latest` will be resolved to LATEST_PNPM_VERSION.",
                    default = DEFAULT_PNPM_VERSION,
                ),
                "pnpm_version_from": attr.label(
                    doc = "Label to a package.json file to read the pnpm version from. It should be in the packageManager attribute.",
                    default = None,
                ),
                "pnpm_version_integrity": attr.string(),
            },
        ),
    },
)
