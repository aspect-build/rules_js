"""Starlark helpers for npm_translate_lock."""

load("@bazel_lib//lib:base64.bzl", "base64")
load("@bazel_skylib//lib:new_sets.bzl", "sets")
load("@bazel_skylib//lib:paths.bzl", "paths")
load(":pnpm.bzl", "pnpm")
load(":utils.bzl", "utils")

################################################################################
def _check_for_conflicting_public_links(npm_imports, public_hoist_packages):
    if not public_hoist_packages:
        return
    all_public_links = {}
    for _import in npm_imports:
        for link_package, link_names in _import.link_packages.items():
            if link_package not in all_public_links:
                all_public_links[link_package] = {}
            for link_name in link_names:
                if link_name not in all_public_links[link_package]:
                    all_public_links[link_package][link_name] = []
                all_public_links[link_package][link_name].append("{}@{}".format(_import.package, _import.version))
    for link_package, link_names in all_public_links.items():
        for link_name, link_packages in link_names.items():
            if len(link_packages) > 1:
                if link_name in public_hoist_packages:
                    msg = """\n\nInvalid public hoist configuration with multiple packages to hoist to '{link_package}/node_modules/{link_name}': {link_packages}

Trying selecting a specific version of '{link_name}' to hoist in public_hoist_packages. For example '{link_packages_first}':

    public_hoist_packages = {{
        "{link_packages_first}": ["{link_package}"]
    }}
""".format(
                        link_package = link_package,
                        link_name = link_name,
                        link_packages = link_packages,
                        link_packages_first = link_packages[0],
                    )
                else:
                    msg = """\n\nInvalid public hoist configuration with multiple packages to hoist to '{link_package}/node_modules/{link_name}': {link_packages}

Check the public_hoist_packages attribute for duplicates.
""".format(
                        link_package = link_package,
                        link_name = link_name,
                        link_packages = link_packages,
                    )
                fail(msg)

################################################################################
def _gather_package_content_excludes(config, *names):
    found = False
    excludes = []

    for name in names:
        if name in config:
            found = True
            value = config[name]
            excludes.extend(value)

    if not found:
        return config["*"] if "*" in config else None

    return excludes

################################################################################
def _gather_values_from_matching_names(additive, keyed_lists, *names):
    keys = []
    result = []
    for name in names:
        if name and name in keyed_lists:
            keys.append(name)
            v = keyed_lists[name]
            if additive:
                if type(v) == "list":
                    result.extend(v)
                elif type(v) == "string":
                    result.append(v)
                else:
                    fail("expected value to be list or string")
            elif type(v) == "list":
                result = v
            elif type(v) == "string":
                result = [v]
            else:
                fail("expected value to be list or string")
    return (result, keys)

################################################################################
def _get_npm_auth(npmrc, npmrc_path, rctx):
    """Parses npm tokens, registries and scopes from `.npmrc`.

    - creates a token by registry dict: {registry: token}
    - creates a registry by scope dict: {scope: registry}

    For example:
        Given the following `.npmrc`:

        ```
        @myorg:registry=https://somewhere-else.com/myorg
        @another:registry=https://somewhere-else.com/another
        @basic:registry=https://somewhere-else.com/basic
        ; would apply only to @myorg
        //somewhere-else.com/myorg/:_authToken=MYTOKEN1
        ; would apply only to @another
        //somewhere-else.com/another/:_auth=dXNlcm5hbWU6cGFzc3dvcmQ===
        ; would apply only to @basic
        //somewhere-else.com/basic/:username=someone
        //somewhere-else.com/basic/:_password=aHVudGVyMg==
        ```

        `get_npm_auth(npmrc, npmrc_path, environ)` creates the following dict:

        ```starlark
        registries = {
                "@myorg": "somewhere-else.com/myorg",
                "@another": "somewhere-else.com/another",
                "@basic": "somewhere-else.com/basic",
        }
        auth = {
            "somewhere-else.com/myorg": {
                "bearer": MYTOKEN1",
            },
            "somewhere-else.com/another": {
                "basic": dXNlcm5hbWU6cGFzc3dvcmQ===",
            },
            "somewhere-else.com/basic": {
                "username": "someone",
                "password": "hunter2",
            },
        }
        ```

    Args:
        npmrc: The `.npmrc` file.
        npmrc_path: The file path to `.npmrc`.
        rctx: the repository_ctx or module_ctx to fetch environment vars from

    Returns:
        A tuple (registries, auth).
    """

    # _NPM_AUTH_TOKEN is case-sensitive. Should be the same as pnpm's
    # https://github.com/pnpm/pnpm/blob/4097af6b5c09d9de1a3570d531bb4bb89c093a04/network/auth-header/src/getAuthHeadersFromConfig.ts#L17
    _NPM_AUTH_TOKEN = "_authToken"
    _NPM_AUTH = "_auth"
    _NPM_USERNAME = "username"
    _NPM_PASSWORD = "_password"
    _NPM_PKG_SCOPE_KEY = ":registry"
    registries = {}
    auth = {}

    for (k, v) in npmrc.items():
        if k == _NPM_AUTH_TOKEN or k.endswith(":" + _NPM_AUTH_TOKEN):
            # //somewhere-else.com/myorg/:_authToken=MYTOKEN1
            # registry: somewhere-else.com/myorg
            # token: MYTOKEN1
            registry = k.removeprefix("//").removesuffix(_NPM_AUTH_TOKEN).removesuffix(":").removesuffix("/")

            # envvar replacement is supported for `_authToken`
            # https://pnpm.io/npmrc#url_authtoken
            token = utils.replace_npmrc_token_envvar(v, npmrc_path, rctx)

            if registry not in auth:
                auth[registry] = {}

            auth[registry]["bearer"] = token

        # global "registry" key is special cased elsewhere
        if k.endswith(_NPM_PKG_SCOPE_KEY):
            # @myorg:registry=https://somewhere-else.com/myorg
            # scope: @myorg
            # registry: somewhere-else.com/myorg
            scope = k.removesuffix(_NPM_PKG_SCOPE_KEY)
            registry = utils.to_registry_url(v)
            registries[scope] = registry

        if k == _NPM_AUTH or k.endswith(":" + _NPM_AUTH):
            # //somewhere-else.com/myorg/:username=someone
            # registry: somewhere-else.com/myorg
            # username: someone
            registry = k.removeprefix("//").removesuffix(_NPM_AUTH).removesuffix(":").removesuffix("/")

            # envvar replacement is supported for `_auth` as well
            token = utils.replace_npmrc_token_envvar(v, npmrc_path, rctx)

            if registry not in auth:
                auth[registry] = {}

            auth[registry]["basic"] = token

        if k == _NPM_USERNAME or k.endswith(":" + _NPM_USERNAME):
            # //somewhere-else.com/myorg/:username=someone
            # registry: somewhere-else.com/myorg
            # username: someone
            registry = k.removeprefix("//").removesuffix(_NPM_USERNAME).removesuffix(":").removesuffix("/")

            if registry not in auth:
                auth[registry] = {}

            auth[registry]["username"] = v

        if k == _NPM_PASSWORD or k.endswith(":" + _NPM_PASSWORD):
            # //somewhere-else.com/myorg/:_password=aHVudGVyMg==
            # registry: somewhere-else.com/myorg
            # _password: aHVudGVyMg==
            registry = k.removeprefix("//").removesuffix(_NPM_PASSWORD).removesuffix(":").removesuffix("/")

            if registry not in auth:
                auth[registry] = {}

            auth[registry]["password"] = base64.decode(v)

    return (registries, auth)

################################################################################
def _select_npm_auth(url, npm_auth):
    registry = url.split("//", 1)[-1]

    # Get rid of the port number
    registry_no_port = registry
    if ":" in registry:
        components = registry.split(":", 1)
        base = components[0]

        path = components[1].split("/", 1)
        if len(path) == 2:
            registry_no_port = base + "/" + path[1]
        else:
            registry_no_port = base

    npm_auth_bearer = None
    npm_auth_basic = None
    npm_auth_username = None
    npm_auth_password = None
    match_len = 0
    for auth_registry, auth_info in npm_auth.items():
        if auth_registry == "" and match_len == 0:
            # global auth applied to all registries; will be overridden by a registry scoped auth
            npm_auth_bearer = auth_info.get("bearer")
            npm_auth_basic = auth_info.get("basic")
            npm_auth_username = auth_info.get("username")
            npm_auth_password = auth_info.get("password")
        if (registry.startswith(auth_registry) or registry_no_port.startswith(auth_registry)) and len(auth_registry) > match_len:
            npm_auth_bearer = auth_info.get("bearer")
            npm_auth_basic = auth_info.get("basic")
            npm_auth_username = auth_info.get("username")
            npm_auth_password = auth_info.get("password")
            match_len = len(auth_registry)
            break

    return npm_auth_bearer, npm_auth_basic, npm_auth_username, npm_auth_password

################################################################################
def _get_npm_imports(importers, packages, replace_packages, pnpm_patched_dependencies, only_built_dependencies, root_package, rctx_name, attr, all_lifecycle_hooks, all_lifecycle_hooks_execution_requirements, all_lifecycle_hooks_use_default_shell_env, registries, default_registry, npm_auth, exclude_package_contents_config):
    "Converts packages from the lockfile to a struct of attributes for npm_import"

    # Direct dependencies of 'importers' which will have public targets
    direct_deps = {}

    # A map of which importers depend on which packages (and by which name) to
    # quickly map package => dependents.
    package_importers = {}
    for importer_path, importer in importers.items():
        dependencies = importer["dependencies"] | importer["optional_dependencies"] | importer["dev_dependencies"]

        link_package = _link_package(root_package, importer_path)

        for dep_package, dep_package_key in dependencies.items():
            direct_deps[dep_package_key] = True

            if dep_package_key.startswith("link:"):
                continue

            if dep_package_key not in package_importers:
                package_importers[dep_package_key] = {link_package: [dep_package]}
            elif link_package not in package_importers[dep_package_key]:
                package_importers[dep_package_key][link_package] = [dep_package]
            elif dep_package not in package_importers[dep_package_key][link_package]:
                package_importers[dep_package_key][link_package].append(dep_package)

    patches_used = []
    result = []
    for package_key, package_info in packages.items():
        name = package_info["name"]
        version = package_info["version"]
        friendly_version = package_info["friendly_version"]
        transitive_closure = package_info.get("transitive_closure", {}) | package_info.get("transitive_optional_closure", {})
        resolution = package_info["resolution"]

        resolution_type = resolution.get("type", None)
        if resolution_type == "directory":
            # this package is treated as a first-party dep
            continue

        integrity = resolution.get("integrity", None)
        tarball = resolution.get("tarball", None)
        registry = resolution.get("registry", None)
        repo = resolution.get("repo", None)
        commit = resolution.get("commit", None)

        if resolution_type == "git":
            if not repo or not commit:
                msg = "expected package {} resolution to have repo and commit fields when resolution type is git".format(package_key)
                fail(msg)
        elif not integrity and not tarball:
            msg = "expected package {} resolution to have an integrity or tarball field but found none".format(package_key)
            fail(msg)

        friendly_name = utils.friendly_name(name, friendly_version)
        unfriendly_name = utils.friendly_name(name, version)
        if unfriendly_name == friendly_name:
            # there is no unfriendly name for this package
            unfriendly_name = None

        # gather patches & patch args
        patches = []
        patch_args = []

        translate_patches, patches_keys = _gather_values_from_matching_names(True, attr.patches, name, friendly_name, unfriendly_name)

        pnpm_patch = pnpm_patched_dependencies.get(friendly_name, pnpm_patched_dependencies.get(name, None))
        pnpm_patched = pnpm_patch != None

        if len(translate_patches) > 0 and pnpm_patched:
            msg = """\
ERROR: can not apply both `pnpm.patchedDependencies` and `npm_translate_lock(patches)` to the same package {pkg}.
""".format(
                pkg = name,
            )
            fail(msg)

        # Apply patch from `pnpm.patchedDependencies` first
        if pnpm_patched:
            patch_path = "//%s:%s" % (attr.pnpm_lock.package, pnpm_patch.get("path"))
            patches.append(patch_path)

            # pnpm patches are always applied with -p1
            patch_args = ["-p1"]
        elif len(translate_patches) > 0:
            patches = translate_patches
            patch_args, _ = _gather_values_from_matching_names(False, attr.patch_args, "*", name, friendly_name, unfriendly_name)
            patches_used.extend(patches_keys)

        # Resolve string patch labels relative to the root respository rather than relative to rules_js.
        # https://docs.google.com/document/d/1N81qfCa8oskCk5LqTW-LNthy6EBrDot7bdUsjz6JFC4/
        patches = [attr.pnpm_lock.relative(patch) for patch in patches]

        exclude_package_contents = _gather_package_content_excludes(exclude_package_contents_config, name, friendly_name, unfriendly_name)

        # gather replace packages
        replace_package, _ = _gather_values_from_matching_names(True, replace_packages, name, friendly_name, unfriendly_name)
        if len(replace_package) > 1:
            msg = "Multiple package replacements found for package {}".format(name)
            fail(msg)
        replace_package = replace_package[0] if replace_package else None

        # gather custom postinstalls
        custom_postinstalls, _ = _gather_values_from_matching_names(True, attr.custom_postinstalls, name, friendly_name, unfriendly_name)
        custom_postinstall = " && ".join([c for c in custom_postinstalls if c])

        repo_name = utils.package_repo_name(attr.name, package_key)

        # gather package visibility
        package_visibility, _ = _gather_values_from_matching_names(True, attr.package_visibility, "*", name, friendly_name, unfriendly_name)
        if len(package_visibility) == 0:
            package_visibility = ["//visibility:public"]

        # Bazel package which this pnpm package should be linked at which names
        link_packages = package_importers.get(package_key, {})

        # check if this package should be hoisted via public_hoist_packages
        public_hoist_packages, _ = _gather_values_from_matching_names(True, attr.public_hoist_packages, name, friendly_name, unfriendly_name)
        for public_hoist_package in public_hoist_packages:
            if public_hoist_package not in link_packages:
                link_packages[public_hoist_package] = [name]
            elif name not in link_packages[public_hoist_package]:
                link_packages[public_hoist_package].append(name)

        run_lifecycle_hooks = all_lifecycle_hooks and only_built_dependencies != None and name in only_built_dependencies
        if run_lifecycle_hooks:
            lifecycle_hooks, _ = _gather_values_from_matching_names(False, all_lifecycle_hooks, "*", name, friendly_name, unfriendly_name)
            lifecycle_hooks_env, _ = _gather_values_from_matching_names(True, attr.lifecycle_hooks_envs, "*", name, friendly_name, unfriendly_name)
            lifecycle_hooks_execution_requirements, _ = _gather_values_from_matching_names(False, all_lifecycle_hooks_execution_requirements, "*", name, friendly_name, unfriendly_name)
            lifecycle_hooks_use_default_shell_env, _ = _gather_values_from_matching_names(False, all_lifecycle_hooks_use_default_shell_env, "*", name, friendly_name, unfriendly_name)
        else:
            lifecycle_hooks = False
            lifecycle_hooks_env = []
            lifecycle_hooks_execution_requirements = []
            lifecycle_hooks_use_default_shell_env = False

        bins = {}
        matching_bins, _ = _gather_values_from_matching_names(False, attr.bins, "*", name, friendly_name, unfriendly_name)
        for bin in matching_bins:
            key_value = bin.split("=", 1)
            if len(key_value) == 2:
                bins[key_value[0]] = key_value[1]
            else:
                msg = "bins contains invalid key value pair '{}', required '=' separator not found".format(bin)
                fail(msg)

        if resolution_type == "git":
            url = repo
        elif tarball:
            if _is_url(tarball):
                # pnpm sometimes prefixes the `tarball` url with the default npm registry `https://registry.npmjs.org/`
                # in pnpm-lock.yaml which we must replace with the desired registry in the `registry` field:
                #   tarball: https://registry.npmjs.org/@types/cacheable-request/-/cacheable-request-6.0.2.tgz
                #   registry: https://registry.yarnpkg.com/
                if registry and tarball.startswith(utils.default_registry()):
                    url = registry + tarball[len(utils.default_registry()):]
                else:
                    url = tarball
            elif tarball.startswith("file:"):
                file_path = tarball[5:]
                file_path = paths.normalize(paths.join(root_package, file_path))
                url = "file:{}".format(file_path)
            else:
                if not registry:
                    registry = utils.npm_registry_url(name, registries, default_registry)
                url = "{}/{}".format(registry.removesuffix("/"), tarball)
        else:
            url = utils.npm_registry_download_url(name, friendly_version, registries, default_registry)

        npm_auth_bearer, npm_auth_basic, npm_auth_username, npm_auth_password = _select_npm_auth(url, npm_auth)

        deps_constraints = _collect_dep_constraints(packages, package_info)

        result_pkg = struct(
            custom_postinstall = custom_postinstall,
            deps = package_info["dependencies"] | package_info["optional_dependencies"],
            deps_constraints = deps_constraints,
            integrity = integrity,
            link_packages = link_packages,
            repo_name = repo_name,
            is_direct_dep = package_key in direct_deps,
            package_key = package_key,
            package = name,
            package_visibility = package_visibility,
            patch_tool = attr.patch_tool,
            patch_args = patch_args,
            patches = patches,
            exclude_package_contents = exclude_package_contents,
            lifecycle_hooks = lifecycle_hooks,
            lifecycle_hooks_env = lifecycle_hooks_env,
            lifecycle_hooks_execution_requirements = lifecycle_hooks_execution_requirements,
            lifecycle_hooks_use_default_shell_env = lifecycle_hooks_use_default_shell_env and lifecycle_hooks_use_default_shell_env[0] == "true",
            npm_auth = npm_auth_bearer,
            npm_auth_basic = npm_auth_basic,
            npm_auth_username = npm_auth_username,
            npm_auth_password = npm_auth_password,
            transitive_closure = transitive_closure if len(transitive_closure) else None,
            url = url,
            commit = commit,
            version = version,
            bins = bins,
            package_info = package_info,
            replace_package = replace_package,
        )

        result.append(result_pkg)

    # Check that all patches files specified were used; this is a defense-in-depth since it is too
    # easy to make a type in the patches keys or for a dep to change both of with could result
    # in a patch file being silently ignored.
    for key in attr.patches.keys():
        if key not in patches_used:
            msg = """

ERROR: Patch file key `{key}` does not match any npm packages in `npm_translate_lock(name = "{repo}").

Either remove this patch file if it is no longer needed or change its key to match an existing npm package.

""".format(
                key = key,
                repo = rctx_name,
            )
            fail(msg)

    # check all links and fail if there are duplicates which can happen with public hoisting
    _check_for_conflicting_public_links(result, attr.public_hoist_packages)

    return result

################################################################################
def _collect_dep_constraints(packages, package_info):
    # Quick-exit for packages with no optional dependencies
    if not package_info["optional_dependencies"] and not package_info.get("transitive_optional_closure", None):
        return None

    constraints = {}

    optional_keys = package_info["optional_dependencies"].values() + package_info.get("transitive_optional_closure", {}).keys()
    for dep_key in optional_keys:
        dep = packages[dep_key]

        c = None
        if dep["os"] and dep["cpu"]:
            c = []
            for os in dep["os"]:
                for cpu in dep["cpu"]:
                    c.append(pnpm.to_bazel_os_cpu_constraint(os, cpu))
        elif dep["cpu"]:
            c = [pnpm.to_bazel_cpu_constraint(cpu) for cpu in dep["cpu"]]
        elif dep["os"]:
            c = [pnpm.to_bazel_os_constraint(os) for os in dep["os"]]

        if c != None:
            # Record the constraints for this optional dependency
            constraints[dep_key] = [v for v in c if v != None]

    return constraints

################################################################################
def _link_package(root_package, import_path, rel_path = "."):
    link_package = paths.normalize(paths.join(root_package, import_path, rel_path))
    if link_package.startswith("../"):
        msg = "Invalid link_package outside of the repository: {}".format(link_package)
        fail(msg)
    if link_package == ".":
        link_package = ""
    return link_package

################################################################################
def _is_url(url):
    return url.find("://") != -1

################################################################################
def _to_apparent_repo_name(canonical_name):
    # Bazel 7 uses `~` as the canonical name separator by default, Bazel 8 always uses `+`.
    return canonical_name[max(canonical_name.rfind("~"), canonical_name.rfind("+")) + 1:]

################################################################################
def _verify_node_modules_ignored(rctx, attr, importers, root_package):
    if attr.verify_node_modules_ignored != None:
        missing_ignores = _find_missing_bazel_ignores(root_package, importers.keys(), rctx.read(rctx.path(attr.verify_node_modules_ignored)))
        if missing_ignores:
            msg = """

ERROR: in verify_node_modules_ignored:
pnpm install will create nested node_modules, but not all of them are ignored by Bazel.
We recommend that all node_modules folders in the source tree be ignored,
to avoid Bazel printing confusing error messages.

Possible fixes:
  - Upgrade to Bazel 8.0 and use ignore_directories(["**/node_modules"]) in REPO.bazel
  - Disable this check by removing `verify_node_modules_ignored` in `npm_translate_lock(name = "{repo}")`
  - Add line(s) to {bazelignore}:

{fixes}
                """.format(
                fixes = "\n".join(missing_ignores),
                bazelignore = attr.verify_node_modules_ignored,
                repo = rctx.name,
            )
            fail(msg)

def _find_missing_bazel_ignores(root_package, importer_paths, bazelignore):
    bazelignore = _normalize_bazelignore(bazelignore.split("\n"))
    missing_ignores = []

    # The pnpm-lock.yaml file package needs to be prefixed on paths
    for i in importer_paths:
        expected = paths.normalize(paths.join(root_package, i, "node_modules"))
        if expected not in bazelignore:
            missing_ignores.append(expected)
    return missing_ignores

def _normalize_bazelignore(lines):
    """Make bazelignore lines predictable

    - strip trailing slash so that users can have either of equivalent
        foo/node_modules or foo/node_modules/
    - strip trailing carriage return on Windows
    - strip leading ./ so users can have node_modules or ./node_modules
    """
    result = []

    # N.B. from https://bazel.build/rules/lib/string#rstrip:
    # Note that chars is not a suffix: all combinations of its value are removed
    strip_trailing_chars = "/\r"
    for line in lines:
        if line.startswith("./"):
            result.append(line[2:].rstrip(strip_trailing_chars))
        else:
            result.append(line.rstrip(strip_trailing_chars))
    return result

################################################################################
def _verify_lifecycle_hooks_specified(_, state):
    if state.only_built_dependencies() == None:
        msg = """\
ERROR: pnpm 'onlyBuiltDependencies' configuration required when using pnpm v9 or later.

Packages that rules_js should generate lifecycle hook actions for must be declared in
'onlyBuiltDependencies'.

As of pnpm v10 'onlyBuiltDependencies' should be configured in the pnpm-workspace.yaml file
alongside other pnpm configuration. See https://pnpm.io/10.x/settings#onlybuiltdependencies
for more information.

In pnpm v9 and earlier 'onlyBuiltDependencies' is configured in the root package.json
pnpm.onlyBuiltDependencies. The root package.json must be alongside the pnpm-lock.yaml file
and will be automatically detected even if not explicitly added to data attribute.
See https://pnpm.io/9.x/package_json#pnpmonlybuiltdependencies for more information.

Prior to pnpm v9, rules_js keyed off of the requiresBuild attribute in the pnpm lock
file to determine if a lifecycle hook action should be generated for an npm package.
See [pnpm #7707](https://github.com/pnpm/pnpm/issues/7707) for the reasons that pnpm
removed the requiresBuild attribute from the lockfile in v9.
"""
        fail(msg)

################################################################################
def _verify_patches(rctx, attr, state):
    if attr.verify_patches and attr.patches != None:
        rctx.report_progress("Verifying patches in {}".format(attr.verify_patches))

        # Patches in the patch list verification file
        verify_patches_content = rctx.read(rctx.path(attr.verify_patches)).strip(" \t\n\r")
        verify_patches = sets.make(verify_patches_content.split("\n"))

        # Patches in `patches` or `pnpm.patchedDependencies`
        declared_patches = sets.make([patch["path"] for patch in state.pnpm_patched_dependencies().values()])

        # Patches in `npm_translate_lock(patches)`
        for patches in attr.patches.values():
            for patch in patches:
                patch_label = attr.pnpm_lock.relative(patch)
                sets.insert(declared_patches, paths.join(patch_label.package, patch_label.name))

        if not sets.is_subset(verify_patches, declared_patches):
            missing_patches = sets.to_list(sets.difference(verify_patches, declared_patches))
            missing_patches_formatted = "\n".join(["- %s" % path for path in missing_patches])
            fail("""
ERROR: in verify_patches:

The following patches were found in {patches_list} but were not listed in the 
`patches` attribute of `npm_translate_lock` or in `pnpm.patchedDependencies`.

{missing_patches}

To disable this check, remove the `verify_patches` attribute from `npm_translate_lock`.

""".format(patches_list = attr.verify_patches, missing_patches = missing_patches_formatted))

helpers = struct(
    gather_values_from_matching_names = _gather_values_from_matching_names,
    get_npm_auth = _get_npm_auth,
    get_npm_imports = _get_npm_imports,
    link_package = _link_package,
    to_apparent_repo_name = _to_apparent_repo_name,
    verify_node_modules_ignored = _verify_node_modules_ignored,
    verify_lifecycle_hooks_specified = _verify_lifecycle_hooks_specified,
    verify_patches = _verify_patches,
)

# exported for unit testing
helpers_testonly = struct(
    find_missing_bazel_ignores = _find_missing_bazel_ignores,
    gather_package_content_excludes = _gather_package_content_excludes,
)
