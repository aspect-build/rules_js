"""Starlark generation helpers for npm_translate_lock.
"""

load("@aspect_bazel_lib//lib:base64.bzl", "base64")
load("@bazel_skylib//lib:paths.bzl", "paths")
load("@bazel_skylib//lib:dicts.bzl", "dicts")
load(":utils.bzl", "utils")
load(":starlark_codegen_utils.bzl", "starlark_codegen_utils")

################################################################################
_NPM_IMPORT_TMPL = \
    """    npm_import(
        name = "{name}",
        root_package = "{root_package}",
        link_workspace = "{link_workspace}",
        link_packages = {link_packages},
        package = "{package}",
        version = "{version}",
        {maybe_url}
        npm_translate_lock_repo = "{npm_translate_lock_repo}",
        {maybe_src}
        {maybe_path}
        {maybe_dev}
        {maybe_commit}
        {maybe_generate_bzl_library_targets}
        {maybe_integrity}
        {maybe_deps}
        {maybe_transitive_closure}
        {maybe_patches}
        {maybe_patch_args}
        {maybe_lifecycle_hooks}
        {maybe_custom_postinstall}
        {maybe_lifecycle_hooks_env}
        {maybe_lifecycle_hooks_execution_requirements}
        {maybe_bins}
        {maybe_npm_auth}
        {maybe_npm_auth_basic}
        {maybe_npm_auth_username}
        {maybe_npm_auth_password}
    )
"""

_BIN_TMPL = \
    """load("{repo_package_json_bzl}", _bin = "bin", _bin_factory = "bin_factory")
bin = _bin
bin_factory = _bin_factory
"""

_BZL_LIBRARY_TMPL = \
    """bzl_library(
    name = "{name}_bzl_library",
    srcs = ["{src}"],
    deps = ["{dep}"],
    visibility = ["//visibility:public"],
)
"""

_BUILD_TMPL = \
    """alias(
    name = "{name}",
    actual = "{actual}",
    visibility = ["//visibility:public"],
)
"""

_PACKAGE_JSON_BZL_FILENAME = "package_json.bzl"
_RESOLVED_JSON_FILENAME = "resolved.json"

################################################################################
# TODO: move to bazel-lib?
def _to_apparent_repo_name(canonical_name):
    return canonical_name[canonical_name.rfind("~") + 1:]

################################################################################
def _link_package(root_package, import_path, rel_path = "."):
    link_package = paths.normalize(paths.join(root_package, import_path, rel_path))
    if link_package == ".":
        link_package = ""
    return link_package

################################################################################
def _is_url(url):
    return url.find("://") != -1

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
def _get_npm_auth(npmrc, npmrc_path, environ):
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
        environ: A map of environment variables with their values.

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
            token = utils.replace_npmrc_token_envvar(v, npmrc_path, environ)

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
            token = utils.replace_npmrc_token_envvar(v, npmrc_path, environ)

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

def _join_path(*parts):
    return paths.normalize(paths.join(*parts))

def _get_link_path(dep_version):
    is_link_or_file = dep_version.startswith("link:") or dep_version.startswith("file:")
    if not is_link_or_file:
        return None

    return dep_version[5:]

def _find_fp_deps(dep_version, import_path, importers):
    if import_path in importers:
        importer = importers.get(import_path)
        return importer["transitive_deps"]

    fail("Cannot link to external packages. Use a `file:` version protocol instead.")
    # TODO parse third-party pnpm-lock.yaml?

def _make_import_links_lookup(importers, rctx_workspace_root, root_package):
    # make a lookup table of package to link name for each importer
    importer_links = {}
    npm_links = {}
    for import_path, importer in importers.items():
        specifiers = importer["specifiers"]
        if type(specifiers) != "dict":
            msg = "expected dict of specifiers in processed importer '{}'".format(import_path)
            fail(msg)
        dependencies = importer["all_deps"]
        if type(dependencies) != "dict":
            msg = "expected dict of dependencies in processed importer '{}'".format(import_path)
            fail(msg)

        links = {
            "link_package": _link_package(root_package, import_path),
        }

        linked_packages = {}
        for dep_package, dep_version in dependencies.items():
            if dep_version[0].isdigit():
                maybe_package = utils.pnpm_name(dep_package, dep_version)
            elif dep_version.startswith("/"):
                maybe_package = dep_version[1:]
            else:
                maybe_package = dep_version

            if maybe_package not in linked_packages:
                linked_packages[maybe_package] = [dep_package]
            else:
                linked_packages[maybe_package].append(dep_package)

            if dep_version.startswith("link:"):
                link_path = _join_path(root_package, import_path, _get_link_path(dep_version))
                specifier = specifiers.get(dep_package)
                link_to_workspace = specifier.startswith("workspace:")
                if dep_version not in npm_links:
                    deps = _find_fp_deps(dep_version, link_path, importers)
                    if link_to_workspace:
                        src = "//" + link_path
                        npm_links[dep_version] = struct(
                            dep_package = dep_package,
                            src = src,
                            path = None,
                            import_paths = [],
                            deps = deps,
                        )
                    else:
                        path = _join_path(str(rctx_workspace_root), link_path)
                        npm_links[dep_version] = struct(
                            dep_package = dep_package,
                            src = None,
                            path = path,
                            import_paths = [],
                            deps = deps,
                        )
                npm_links[dep_version].import_paths.append(import_path)

        links["packages"] = linked_packages
        importer_links[import_path] = links

    return importer_links, npm_links

################################################################################
def _gen_npm_imports(packages, importers, patched_dependencies, root_package, rctx_name, rctx_workspace_root, attr, all_lifecycle_hooks, all_lifecycle_hooks_execution_requirements, registries, default_registry, npm_auth):
    "Converts packages from the lockfile to a struct of attributes for npm_import"
    if attr.prod and attr.dev:
        fail("prod and dev attributes cannot both be set to true")

    # make a lookup table of package to link name for each importer
    importer_links, npm_links = _make_import_links_lookup(importers, rctx_workspace_root, root_package)

    patches_used = []
    result = []
    for package, package_info in packages.items():
        name = package_info.get("name")
        version = package_info.get("version")
        friendly_version = package_info.get("friendly_version")
        deps = {
            name: "0.0.0" if version.startswith("file:") else version
            for name, version in package_info.get("dependencies", {}).items()
        }
        optional_deps = {
            name: "0.0.0" if version.startswith("file:") else version
            for name, version in package_info.get("optional_dependencies", {}).items()
        }
        dev = package_info.get("dev")
        optional = package_info.get("optional")
        pnpm_patched = package_info.get("patched")
        requires_build = package_info.get("requires_build")
        transitive_closure = package_info.get("transitive_closure")
        resolution = package_info.get("resolution")

        src = None
        path = None
        if version.startswith("file:"):
            link_path = _get_link_path(package_info.get("id") or version)
            version = "0.0.0"

            if link_path.startswith("/") or link_path.startswith("../"):
                src = None
                path = _join_path(str(rctx_workspace_root), link_path)
            else:
                src = "//" + link_path
                path = None

        resolution_type = resolution.get("type", None)

        integrity = resolution.get("integrity", None)
        tarball = resolution.get("tarball", None)
        registry = resolution.get("registry", None)
        repo = resolution.get("repo", None)
        commit = resolution.get("commit", None)

        if resolution_type == "git":
            if not repo or not commit:
                msg = "expected package {} resolution to have repo and commit fields when resolution type is git".format(package)
                fail(msg)
        elif not integrity and not tarball and not resolution_type == "directory":
            msg = "expected package {} resolution to have an integrity or tarball field but found none".format(package)
            fail(msg)

        if attr.prod and dev:
            # when prod attribute is set, skip devDependencies
            continue
        if attr.dev and not dev:
            # when dev attribute is set, skip (non-dev) dependencies
            continue
        if attr.no_optional and optional:
            # when no_optional attribute is set, skip optionalDependencies
            continue

        if not attr.no_optional:
            deps = dicts.add(optional_deps, deps)

        friendly_name = utils.friendly_name(name, friendly_version)
        unfriendly_name = utils.friendly_name(name, version)
        if unfriendly_name == friendly_name:
            # there is no unfriendly name for this package
            unfriendly_name = None

        # gather patches & patch args
        patches, patches_keys = _gather_values_from_matching_names(True, attr.patches, name, friendly_name, unfriendly_name)

        # Apply patch from `pnpm.patchedDependencies` first
        if pnpm_patched:
            patch_path = "//%s:%s" % (attr.pnpm_lock.package, patched_dependencies.get(friendly_name).get("path"))
            patches.insert(0, patch_path)

        # Resolve string patch labels relative to the root respository rather than relative to rules_js.
        # https://docs.google.com/document/d/1N81qfCa8oskCk5LqTW-LNthy6EBrDot7bdUsjz6JFC4/
        patches = [str(attr.pnpm_lock.relative(patch)) for patch in patches]

        # Prepend the optional '@' to patch labels in the root repository for earlier versions of Bazel so
        # that checked in repositories.bzl files don't fail diff tests when run under multiple versions of Bazel.
        patches = [("@" if patch.startswith("//") else "") + patch for patch in patches]

        patch_args, _ = _gather_values_from_matching_names(False, attr.patch_args, "*", name, friendly_name, unfriendly_name)

        # Patches in `pnpm.patchedDependencies` must have the -p1 format. Therefore any
        # patches applied via `patches` must also use -p1 since we don't support different
        # patch args for different patches.
        if pnpm_patched and not _has_strip_prefix_arg(patch_args, 1):
            if _has_strip_prefix_arg(patch_args):
                msg = """\
ERROR: patch_args for package {package} contains a strip prefix that is incompatible with a patch applied via `pnpm.patchedDependencies`.

`pnpm.patchedDependencies` requires a strip prefix of `-p1`. All applied patches must use the same strip prefix.

""".format(package = friendly_name)
                fail(msg)
            patch_args = patch_args[:]
            patch_args.append("-p1")

        patches_used.extend(patches_keys)

        # gather custom postinstalls
        custom_postinstalls, _ = _gather_values_from_matching_names(True, attr.custom_postinstalls, name, friendly_name, unfriendly_name)
        custom_postinstall = " && ".join([c for c in custom_postinstalls if c])

        repo_name = "{}__{}".format(attr.name, utils.bazel_name(name, version))
        if repo_name.startswith("aspect_rules_js.npm."):
            repo_name = repo_name[len("aspect_rules_js.npm."):]

        # gather all of the importers (workspace packages) that this npm package should be linked at which names
        link_packages = {}
        for import_path, links in importer_links.items():
            link_package = links["link_package"]
            linked_packages = links["packages"]
            link_names = linked_packages.get(package, [])
            if link_names:
                link_packages[link_package] = link_names

        # check if this package should be hoisted via public_hoist_packages
        public_hoist_packages, _ = _gather_values_from_matching_names(True, attr.public_hoist_packages, name, friendly_name, unfriendly_name)
        for public_hoist_package in public_hoist_packages:
            if public_hoist_package not in link_packages:
                link_packages[public_hoist_package] = [name]
            elif name not in link_packages[public_hoist_package]:
                link_packages[public_hoist_package].append(name)

        lifecycle_hooks, _ = _gather_values_from_matching_names(False, all_lifecycle_hooks, "*", name, friendly_name, unfriendly_name)
        lifecycle_hooks_env, _ = _gather_values_from_matching_names(True, attr.lifecycle_hooks_envs, "*", name, friendly_name, unfriendly_name)
        lifecycle_hooks_execution_requirements, _ = _gather_values_from_matching_names(False, all_lifecycle_hooks_execution_requirements, "*", name, friendly_name, unfriendly_name)
        run_lifecycle_hooks = requires_build and lifecycle_hooks

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
        elif resolution_type == "directory":
            url = None
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
                url = tarball
            else:
                if not registry:
                    registry = utils.npm_registry_url(name, registries, default_registry)
                url = "{}/{}".format(registry.removesuffix("/"), tarball)
        else:
            url = utils.npm_registry_download_url(name, version, registries, default_registry)

        npm_auth_bearer = None
        npm_auth_basic = None
        npm_auth_username = None
        npm_auth_password = None
        if url:
            registry = url.split("//", 1)[-1]
            match_len = 0
            for auth_registry, auth_info in npm_auth.items():
                if auth_registry == "" and match_len == 0:
                    # global auth applied to all registries; will be overridden by a registry scoped auth
                    npm_auth_bearer = auth_info.get("bearer")
                    npm_auth_basic = auth_info.get("basic")
                    npm_auth_username = auth_info.get("username")
                    npm_auth_password = auth_info.get("password")
                if registry.startswith(auth_registry) and len(auth_registry) > match_len:
                    npm_auth_bearer = auth_info.get("bearer")
                    npm_auth_basic = auth_info.get("basic")
                    npm_auth_username = auth_info.get("username")
                    npm_auth_password = auth_info.get("password")
                    match_len = len(auth_registry)

        pkg = struct(
            custom_postinstall = custom_postinstall,
            deps = deps,
            url = url,
            src = src,
            path = path,
            integrity = integrity,
            link_packages = link_packages,
            name = repo_name,
            package = name,
            patch_args = patch_args,
            patches = patches,
            root_package = root_package,
            run_lifecycle_hooks = run_lifecycle_hooks,
            lifecycle_hooks = lifecycle_hooks,
            lifecycle_hooks_env = lifecycle_hooks_env,
            lifecycle_hooks_execution_requirements = lifecycle_hooks_execution_requirements,
            npm_auth = npm_auth_bearer,
            npm_auth_basic = npm_auth_basic,
            npm_auth_username = npm_auth_username,
            npm_auth_password = npm_auth_password,
            transitive_closure = transitive_closure,
            commit = commit,
            version = version,
            bins = bins,
            package_info = package_info,
            dev = dev,
        )

        result.append(pkg)

    # create additional npm_import targets for fp_links
    for dep_version, npm_link in npm_links.items():
        dep_package = npm_link.dep_package
        version = "0.0.0"

        repo_name = "{}__{}".format(attr.name, utils.bazel_name(dep_package, version))
        if repo_name.startswith("aspect_rules_js.npm."):
            repo_name = repo_name[len("aspect_rules_js.npm."):]

        # gather all of the importers (workspace packages) that this npm package should be linked at which names
        link_packages = {}
        for import_path in npm_link.import_paths:
            links = importer_links.get(import_path)
            if links:
                link_package = links["link_package"]
                linked_packages = links["packages"]
                link_names = linked_packages.get(dep_version, [])
                if link_names:
                    link_packages[link_package] = link_names

        pkg = struct(
            name = repo_name,
            package = dep_package,
            url = None,
            src = npm_link.src,
            path = npm_link.path,
            version = version,
            link_packages = link_packages,
            root_package = root_package,
            patches = None,
            run_lifecycle_hooks = None,
            lifecycle_hooks = None,
            integrity = None,
            deps = npm_link.deps,
            transitive_closure = None,
            custom_postinstall = None,
            bins = None,
            commit = None,
            npm_auth = None,
            npm_auth_basic = None,
            npm_auth_username = None,
            npm_auth_password = None,
            dev = None,
            package_info = {},
        )

        result.append(pkg)

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

    return result

################################################################################
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

def _find_missing_bazel_ignores(root_package, importer_paths, bazelignore):
    bazelignore = _normalize_bazelignore(bazelignore.split("\n"))
    missing_ignores = []

    # The pnpm-lock.yaml file package needs to be prefixed on paths
    for i in importer_paths:
        expected = paths.normalize(paths.join(root_package, i, "node_modules"))
        if expected not in bazelignore:
            missing_ignores.append(expected)
    return missing_ignores

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
def _verify_node_modules_ignored(rctx, importers, root_package):
    if rctx.attr.verify_node_modules_ignored != None:
        missing_ignores = _find_missing_bazel_ignores(root_package, importers.keys(), rctx.read(rctx.path(rctx.attr.verify_node_modules_ignored)))
        if missing_ignores:
            msg = """

ERROR: in verify_node_modules_ignored:
pnpm install will create nested node_modules, but not all of them are ignored by Bazel.
We recommend that all node_modules folders in the source tree be ignored,
to avoid Bazel printing confusing error messages.

Either add line(s) to {bazelignore}:

{fixes}

or disable this check by setting `verify_node_modules_ignored = None` in `npm_translate_lock(name = "{repo}")`
                """.format(
                fixes = "\n".join(missing_ignores),
                bazelignore = rctx.attr.verify_node_modules_ignored,
                repo = rctx.name,
            )
            fail(msg)

def _write_build_alias_target(name):
    return _BUILD_TMPL.format(
        name = "{}_source_directory".format(name),
        actual = "{}{}//:source_directory".format(
            "@@" if utils.bzlmod_supported else "@",
            name,
        ),
    )

def _write_defs_link_packages(repo_name, i, link_packages = True):
    if link_packages:
        return """load("{at}{repo_name}{links_repo_suffix}//:defs.bzl", link_{i} = "npm_link_imported_package_store", store_{i} = "npm_imported_package_store")""".format(
            at = "@@" if utils.bzlmod_supported else "@",
            i = i,
            links_repo_suffix = utils.links_repo_suffix,
            repo_name = repo_name,
        )

    return """load("{at}{repo_name}{links_repo_suffix}//:defs.bzl", store_{i} = "npm_imported_package_store")""".format(
        at = "@@" if utils.bzlmod_supported else "@",
        i = i,
        links_repo_suffix = utils.links_repo_suffix,
        repo_name = repo_name,
    )

def _write_store_bzl_store_invocation(name, i, indentation = 8):
    return """{indent}store_{i}(name = "{{}}/{name}".format(name)) # store_bzl """.format(
        name = name,
        i = i,
        indent = " " * indentation,
    )

def _write_link_package_links_bzl(link_aliases, i, indentation = 12):
    bzl = []

    for link_alias in link_aliases:
        bzl.append("""{indentation}link_targets.append(link_{i}(name = "{{}}/{name}".format(name))) # links_bzl""".format(
            i = i,
            name = link_alias,
            indentation = " " * indentation,
        ))
        if len(link_alias.split("/", 1)) > 1:
            package_scope = link_alias.split("/", 1)[0]
            bzl.append("""{indentation}scope_targets["{package_scope}"] = scope_targets["{package_scope}"] + [link_targets[-1]] if "{package_scope}" in scope_targets else [link_targets[-1]]""".format(
                package_scope = package_scope,
                indentation = " " * indentation,
            ))

    return bzl

def _write_link_package_links_targets_bzl(link_aliases, i, indentation = 12):
    bzl = []

    for link_alias in link_aliases:
        bzl.append("""{indentation}link_targets.append("//{{}}:{{}}/{name}".format(bazel_package, name)) # links_targets_bzl""".format(
            i = i,
            name = link_alias,
            indentation = " " * indentation,
        ))
    return bzl

################################################################################
def _format_skylark_args(prefix = None, **kwargs):
    result = {}

    for key, value in kwargs.items():
        key_with_prefix = (prefix or "") + key
        if not value:
            result[key_with_prefix] = ""
            continue

        if value == True:
            _value = "True"
        elif type(value) == "string":
            _value = "\"{value}\"".format(key = key, value = value)
        elif type(value) == "list" and type(value[0]) == "dict":
            _value = starlark_codegen_utils.to_dict_list_attr(value, 2)
        elif type(value) == "dict":
            if key == "transitive_closure":
                _value = starlark_codegen_utils.to_dict_list_attr(value, 2)
            else:
                _value = starlark_codegen_utils.to_dict_attr(value, 2)
        else:
            _value = value

        _value = "{key} = {value},".format(key = key, value = _value)
        result[key_with_prefix] = _value

    return result

################################################################################
def _remove_lines(s):
    lines = s.splitlines()
    lines = [line.rstrip() for line in lines]
    lines = [line for line in lines if line]
    return "\n".join(lines) + "\n"

################################################################################
def _generate_repository_files(rctx, pnpm_lock_label, importers, packages, patched_dependencies, root_package, default_registry, npm_registries, npm_auth, link_workspace):
    generated_by_lines = [
        "\"\"\"@generated by npm_translate_lock(name = \"{}\", pnpm_lock = \"{}\")\"\"\"".format(_to_apparent_repo_name(rctx.name), utils.consistent_label_str(pnpm_lock_label)),
        "",  # empty line after bzl docstring since buildifier expects this if this file is vendored in
    ]

    npm_imports = _gen_npm_imports(packages, importers, patched_dependencies, root_package, rctx.name, rctx.workspace_root, rctx.attr, rctx.attr.lifecycle_hooks, rctx.attr.lifecycle_hooks_execution_requirements, npm_registries, default_registry, npm_auth)

    repositories_bzl = []

    repositories_imports = []
    if len(npm_imports) > 0:
        repositories_imports.append("npm_import")

    if len(repositories_imports) > 0:
        imports_str = ", ".join(["\"{}\"".format(imp) for imp in repositories_imports])
        repositories_bzl.append("""load("@aspect_rules_js//npm:repositories.bzl", {})""".format(imports_str))
        repositories_bzl.append("")

    repositories_bzl.append("def npm_repositories():")
    repositories_bzl.append("""    "Generated npm_import repository rules corresponding to npm packages in {}\"""".format(utils.consistent_label_str(pnpm_lock_label)))
    repositories_bzl.append("")

    link_packages = [_link_package(root_package, import_path) for import_path in importers.keys()]

    defs_bzl_header = ["""# buildifier: disable=bzl-visibility
load("@aspect_rules_js//js:defs.bzl", _js_library = "js_library")"""]

    rctx_files = {
        "BUILD.bazel": [
            """load("@bazel_skylib//:bzl_library.bzl", "bzl_library")""",
            "",
            """
# A no-op run target that can be run to invalidate the repository
# to update the pnpm lockfile. Useful under bzlmod where
# `bazel sync --only=repo` is a no-op.
sh_binary(
    name = "sync",
    srcs = ["@aspect_rules_js//npm/private:noop.sh"],
)""",
            "",
            "exports_files({})".format(starlark_codegen_utils.to_list_attr([
                rctx.attr.defs_bzl_filename,
                rctx.attr.repositories_bzl_filename,
            ])),
        ],
    }

    npm_link_targets_bzl = [
        """\
def npm_link_targets(name = "node_modules", package = None):
    link_packages = {link_packages}
    bazel_package = package if package != None else native.package_name()
    link = bazel_package in link_packages

    link_targets = []
""".format(link_packages = str(link_packages)),
    ]

    npm_link_all_packages_bzl = [
        """\
def npm_link_all_packages(name = "node_modules", imported_links = []):
    root_package = "{root_package}"
    link_packages = {link_packages}
    is_root = native.package_name() == root_package
    link = native.package_name() in link_packages
    if not is_root and not link:
        msg = "The npm_link_all_packages() macro loaded from {defs_bzl_file} and called in bazel package '%s' may only be called in bazel packages that correspond to the pnpm root package or pnpm workspace projects. Projects are discovered from the pnpm-lock.yaml and may be missing if the lockfile is out of date. Root package: '{root_package}', pnpm workspace projects: {link_packages_comma_separated}" % native.package_name()
        fail(msg)
    link_targets = []
    scope_targets = {{}}

    for link_fn in imported_links:
        new_link_targets, new_scope_targets = link_fn(name)
        link_targets.extend(new_link_targets)
        for _scope, _targets in new_scope_targets.items():
            scope_targets[_scope] = scope_targets[_scope] + _targets if _scope in scope_targets else _targets
""".format(
            defs_bzl_file = "@{}//:{}".format(rctx.name, rctx.attr.defs_bzl_filename),
            link_packages = str(link_packages),
            link_packages_comma_separated = "'" + "', '".join(link_packages) + "'" if len(link_packages) else "",
            root_package = root_package,
            pnpm_lock_label = pnpm_lock_label,
        ),
    ]

    # check all links and fail if there are duplicates which can happen with public hoisting
    _check_for_conflicting_public_links(npm_imports, rctx.attr.public_hoist_packages)

    stores_bzl = []
    links_bzl = {}
    links_targets_bzl = {}
    for (i, _import) in enumerate(npm_imports):
        has_patches = bool(_import.patches)
        has_lc_hooks = _import.run_lifecycle_hooks and _import.lifecycle_hooks
        kwargs = _format_skylark_args(
            prefix = "maybe_",
            url = _import.url,
            src = _import.src,
            path = _import.path,
            integrity = _import.integrity,
            deps = _import.deps,
            transitive_closure = _import.transitive_closure,
            patches = _import.patches,
            patch_args = _import.patch_args if has_patches else None,
            custom_postinstall = _import.custom_postinstall,
            lifecycle_hooks = _import.lifecycle_hooks if has_lc_hooks else None,
            lifecycle_hooks_env = _import.lifecycle_hooks_env if has_lc_hooks else None,
            lifecycle_hooks_execution_requirements = _import.lifecycle_hooks_execution_requirements if has_lc_hooks else None,
            bins = _import.bins,
            generate_bzl_library_targets = rctx.attr.generate_bzl_library_targets,
            commit = _import.commit,
            npm_auth = _import.npm_auth,
            npm_auth_basic = _import.npm_auth_basic,
            npm_auth_username = _import.npm_auth_username,
            npm_auth_password = _import.npm_auth_password,
            dev = _import.dev,
        )

        repositories_bzl.append(_remove_lines(_NPM_IMPORT_TMPL.format(
            link_packages = starlark_codegen_utils.to_dict_attr(_import.link_packages, 2, quote_value = False),
            link_workspace = link_workspace,
            name = _to_apparent_repo_name(_import.name),
            npm_translate_lock_repo = _to_apparent_repo_name(rctx.name),
            package = _import.package,
            root_package = _import.root_package,
            url = _import.url,
            version = _import.version,
            **kwargs
        )))

        rctx_files["BUILD.bazel"].append(_write_build_alias_target(_import.name))
        defs_bzl_header.append(_write_defs_link_packages(_import.name, i, _import.link_packages))
        stores_bzl.append(_write_store_bzl_store_invocation(_import.package, i))

        for link_package, _link_aliases in _import.link_packages.items():
            link_aliases = _link_aliases or [_import.package]
            if link_package not in links_bzl:
                links_bzl[link_package] = []
            links_bzl[link_package] += _write_link_package_links_bzl(link_aliases, i)

            if link_package not in links_targets_bzl:
                links_targets_bzl[link_package] = []
            links_targets_bzl[link_package] += _write_link_package_links_targets_bzl(link_aliases, i)

        for link_package in _import.link_packages.keys():
            build_file = paths.normalize(paths.join(link_package, "BUILD.bazel"))
            if build_file not in rctx_files:
                rctx_files[build_file] = []
            resolved_json_file_path = paths.normalize(paths.join(link_package, _import.package, _RESOLVED_JSON_FILENAME))
            rctx.file(resolved_json_file_path, json.encode({
                # Allow consumers to auto-detect this filetype
                "$schema": "https://docs.aspect.build/rules/aspect_rules_js/docs/npm_translate_lock",
                "version": _import.version,
                "integrity": _import.integrity,
            }))
            rctx_files[build_file].append("exports_files([\"{}\"])".format(resolved_json_file_path))
            if _import.package_info.get("has_bin"):
                if rctx.attr.generate_bzl_library_targets:
                    rctx_files[build_file].append("""load("@bazel_skylib//:bzl_library.bzl", "bzl_library")""")
                    rctx_files[build_file].append(_BZL_LIBRARY_TMPL.format(
                        name = _import.package,
                        src = ":" + paths.join(_import.package, _PACKAGE_JSON_BZL_FILENAME),
                        dep = "@{repo_name}//{link_package}:{package_name}_bzl_library".format(
                            repo_name = _to_apparent_repo_name(_import.name),
                            link_package = link_package,
                            package_name = link_package.split("/")[-1] or _import.package.split("/")[-1],
                        ),
                    ))
                package_json_bzl_file_path = paths.normalize(paths.join(link_package, _import.package, _PACKAGE_JSON_BZL_FILENAME))
                repo_package_json_bzl = "{at}{repo_name}//{link_package}:{package_json_bzl}".format(
                    at = "@@" if utils.bzlmod_supported else "@",
                    repo_name = _import.name,
                    link_package = link_package,
                    package_json_bzl = _PACKAGE_JSON_BZL_FILENAME,
                )
                rctx.file(package_json_bzl_file_path, "\n".join([
                    _BIN_TMPL.format(
                        repo_package_json_bzl = repo_package_json_bzl,
                    ),
                ]))

    if len(stores_bzl) > 0:
        npm_link_all_packages_bzl.append("""    if is_root:""")
        npm_link_all_packages_bzl.extend(stores_bzl)

    if len(links_bzl) > 0:
        npm_link_all_packages_bzl.append("""    if link:""")
        for link_package, bzl in links_bzl.items():
            npm_link_all_packages_bzl.append("""        if native.package_name() == "{}":""".format(link_package))
            npm_link_all_packages_bzl.extend(bzl)

    if len(links_targets_bzl) > 0:
        npm_link_targets_bzl.append("""    if link:""")
        for link_package, bzl in links_targets_bzl.items():
            npm_link_targets_bzl.append("""        if bazel_package == "{}":""".format(link_package))
            npm_link_targets_bzl.extend(bzl)

    # Generate catch all & scoped npm_linked_packages target
    npm_link_all_packages_bzl.append("""
    for scope, scoped_targets in scope_targets.items():
        _js_library(
            name = "{}/{}".format(name, scope),
            srcs = scoped_targets,
            tags = ["manual"],
            visibility = ["//visibility:public"],
        )

    _js_library(
        name = name,
        srcs = link_targets,
        tags = ["manual"],
        visibility = ["//visibility:public"],
    )""")

    npm_link_targets_bzl.append("""    return link_targets""")

    rctx_files[rctx.attr.defs_bzl_filename] = ["\n".join(defs_bzl_header + [""] + npm_link_all_packages_bzl + [""] + npm_link_targets_bzl + [""])]
    rctx_files[rctx.attr.repositories_bzl_filename] = ["\n".join(repositories_bzl)]

    for filename, contents in rctx.attr.additional_file_contents.items():
        if not filename in rctx_files.keys():
            rctx_files[filename] = contents
        elif filename.endswith(".bzl"):
            # bzl files are special cased since all load statements must go at the top
            load_statements = []
            other_statements = []
            for content in contents:
                if content.startswith("load("):
                    load_statements.append(content)
                else:
                    other_statements.append(content)
            rctx_files[filename] = load_statements + rctx_files[filename] + other_statements
        else:
            rctx_files[filename].extend(contents)

    for filename, contents in rctx_files.items():
        rctx.file(filename, "\n".join(generated_by_lines + contents))

def _has_strip_prefix_arg(patch_args, strip_num = None):
    if strip_num != None:
        return "-p%d" % strip_num in patch_args or "--strip=%d" % strip_num in patch_args
    for arg in patch_args:
        if arg.startswith("-p") or arg.startswith("--strip="):
            return True
    return False

helpers = struct(
    # TODO(cleanup): move non-generation helpers out of this file in a follow-up PR
    to_apparent_repo_name = _to_apparent_repo_name,
    get_npm_auth = _get_npm_auth,
    gen_npm_imports = _gen_npm_imports,
    generate_repository_files = _generate_repository_files,
    find_missing_bazel_ignores = _find_missing_bazel_ignores,
    verify_node_modules_ignored = _verify_node_modules_ignored,
)
