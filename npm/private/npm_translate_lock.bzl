"Convert pnpm lock file into starlark Bazel fetches"

load("@bazel_skylib//lib:paths.bzl", "paths")
load("@bazel_skylib//lib:dicts.bzl", "dicts")
load(":ini.bzl", "parse_ini")
load(":utils.bzl", "utils")
load(":transitive_closure.bzl", "translate_to_transitive_closure")
load(":starlark_codegen_utils.bzl", "starlark_codegen_utils")

_ATTRS = {
    "pnpm_lock": attr.label(),
    "package_json": attr.label(),
    "npm_package_lock": attr.label(),
    "yarn_lock": attr.label(),
    "npmrc": attr.label(),
    "patches": attr.string_list_dict(),
    "patch_args": attr.string_list_dict(),
    "custom_postinstalls": attr.string_dict(),
    "prod": attr.bool(),
    "public_hoist_packages": attr.string_list_dict(),
    "dev": attr.bool(),
    "no_optional": attr.bool(),
    "lifecycle_hooks_exclude": attr.string_list(),
    "run_lifecycle_hooks": attr.bool(default = True),
    "lifecycle_hooks_envs": attr.string_list_dict(),
    "lifecycle_hooks_execution_requirements": attr.string_list_dict(),
    "bins": attr.string_list_dict(),
    "lifecycle_hooks_no_sandbox": attr.bool(default = True),
    "verify_node_modules_ignored": attr.label(),
    "warn_on_unqualified_tarball_url": attr.bool(default = True),
    "link_workspace": attr.string(),
}

def _process_lockfile(rctx, pnpm_lock):
    lockfile = utils.parse_pnpm_lock(rctx.read(rctx.path(pnpm_lock)))
    return translate_to_transitive_closure(lockfile, rctx.attr.prod, rctx.attr.dev, rctx.attr.no_optional)

_NPM_IMPORT_TMPL = \
    """    npm_import(
        name = "{name}",
        root_package = "{root_package}",
        link_workspace = "{link_workspace}",
        link_packages = {link_packages},
        package = "{package}",
        version = "{version}",
        lifecycle_hooks_no_sandbox = {lifecycle_hooks_no_sandbox},{maybe_integrity}{maybe_url}{maybe_deps}{maybe_transitive_closure}{maybe_patches}{maybe_patch_args}{maybe_run_lifecycle_hooks}{maybe_custom_postinstall}{maybe_lifecycle_hooks_env}{maybe_lifecycle_hooks_execution_requirements}{maybe_bins}{maybe_npm_auth}
    )
"""

_BIN_TMPL = \
    """load("{repo_package_json_bzl}", _bin = "bin", _bin_factory = "bin_factory")
bin = _bin
bin_factory = _bin_factory
"""

_FP_STORE_TMPL = \
    """
    if is_root:
        _npm_package_store(
            name = "{virtual_store_root}/{{}}/{virtual_store_name}".format(name),
            src = "{npm_package_target}",
            package = "{package}",
            version = "0.0.0",
            deps = {deps},
            visibility = ["//visibility:public"],
            tags = ["manual"],
            use_declare_symlink = select({{
                "@aspect_rules_js//js/private:experimental_allow_unresolved_symlinks": True,
                "//conditions:default": False,
            }}),
        )"""

_FP_DIRECT_TMPL = \
    """
    for link_package in {link_packages}:
        if link_package == native.package_name():
            # terminal target for direct dependencies
            _npm_link_package_store(
                name = "{{}}/{name}".format(name),
                src = "//{root_package}:{virtual_store_root}/{{}}/{virtual_store_name}".format(name),
                visibility = ["//visibility:public"],
                tags = ["manual"],
                use_declare_symlink = select({{
                    "@aspect_rules_js//js/private:experimental_allow_unresolved_symlinks": True,
                    "//conditions:default": False,
                }}),
            )
            link_targets.append(":{{}}/{name}".format(name))

            # filegroup target that provides a single file which is
            # package directory for use in $(execpath) and $(rootpath)
            native.filegroup(
                name = "{{}}/{name}/dir".format(name),
                srcs = [":{{}}/{name}".format(name)],
                output_group = "{package_directory_output_group}",
                visibility = ["//visibility:public"],
                tags = ["manual"],
            )"""

_BZL_LIBRARY_TMPL = \
    """
bzl_library(
    name = "{name}",
    srcs = ["{src}"],
    deps = ["{dep}"],
    visibility = ["//visibility:public"],
)"""

_DEFS_BZL_FILENAME = "defs.bzl"
_REPOSITORIES_BZL_FILENAME = "repositories.bzl"
_PACKAGE_JSON_BZL_FILENAME = "package_json.bzl"

def _link_package(root_package, import_path, rel_path = "."):
    link_package = paths.normalize(paths.join(root_package, import_path, rel_path))
    if link_package.startswith("../"):
        fail("Invalid link_package outside of the WORKSPACE: {}".format(link_package))
    if link_package == ".":
        link_package = ""
    return link_package

def _is_url(url):
    return url.find("://") != -1

def _gather_values_from_matching_names(keyed_lists, *names):
    result = []
    for name in names:
        if name:
            v = keyed_lists.get(name, [])
            if type(v) == "list":
                result.extend(v)
            else:
                result.append(v)
    return result

def _get_npm_auth(rctx):
    """Parses npm tokens from `.npmrc` and creates a tokens dict {registry: token}.

    For example:

        Given the following `.npmrc`:

        ```
        //somewhere-else.com/myorg/:_authToken=MYTOKEN1
        //somewhere-else.com/another/:_authToken=MYTOKEN2
        ```

        `_get_npm_auth(rctx)` creates the following dict:

        ```starlark
        tokens = {
            "somewhere-else.com/myorg": "MYTOKEN1",
            "somewhere-else.com/another": "MYTOKEN2",
        }
        ```
    """

    _NPM_TOKEN_KEY = ":_authtoken"
    tokens = {}

    # Read token from npmrc label
    if rctx.attr.npmrc:
        npmrc_path = rctx.path(rctx.attr.npmrc)
        npmrc = parse_ini(rctx.read(npmrc_path))
        for (k, v) in npmrc.items():
            if k.find(_NPM_TOKEN_KEY) != -1:
                # //somewhere-else.com/myorg/:_authToken=MYTOKEN1
                # registry: somewhere-else.com/myorg
                # token: MYTOKEN1
                registry = k.removeprefix("//").removesuffix("/{}".format(_NPM_TOKEN_KEY))
                token = v

                # A token can be a reference to an environment variable
                if token.startswith("$"):
                    # ${NPM_TOKEN} -> NPM_TOKEN
                    # $NPM_TOKEN -> NPM_TOKEN
                    token = token.removeprefix("$").removeprefix("{").removesuffix("}")
                    if token in rctx.os.environ.keys() and rctx.os.environ[token]:
                        token = rctx.os.environ[token]
                    else:
                        print("""\
WARNING: Issue while reading "{npmrc}". Failed to replace env in config: ${{{token}}}
""".format(
                            npmrc = npmrc_path,
                            token = token,
                        ))
                tokens[registry] = token
    return tokens

def _gen_npm_imports(lockfile, root_package, attr):
    "Converts packages from the lockfile to a struct of attributes for npm_import"

    if attr.prod and attr.dev:
        fail("prod and dev attributes cannot both be set to true")

    packages = lockfile.get("packages")
    if not packages:
        fail("expected packages in processed lockfile")

    importers = lockfile.get("importers")
    if not importers:
        fail("expected importers in processed lockfile")

    result = []
    for package, package_info in packages.items():
        name = package_info.get("name")
        version = package_info.get("version")
        friendly_version = package_info.get("friendly_version")
        deps = package_info.get("dependencies")
        optional_deps = package_info.get("optionalDependencies")
        dev = package_info.get("dev")
        optional = package_info.get("optional")
        requires_build = package_info.get("requiresBuild")
        integrity = package_info.get("integrity")
        tarball = package_info.get("tarball")
        registry = package_info.get("registry")
        transitive_closure = package_info.get("transitiveClosure")

        if version.startswith("file:"):
            # this package is treated as a first-party dep
            continue

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
        patches = _gather_values_from_matching_names(attr.patches, name, friendly_name, unfriendly_name)
        patch_args = _gather_values_from_matching_names(attr.patch_args, name, friendly_name, unfriendly_name)

        # gather custom postinstalls
        custom_postinstalls = _gather_values_from_matching_names(attr.custom_postinstalls, name, friendly_name, unfriendly_name)
        custom_postinstall = " && ".join([c for c in custom_postinstalls if c])

        repo_name = "%s__%s" % (attr.name, utils.bazel_name(name, version))
        if repo_name.startswith("aspect_rules_js.npm."):
            repo_name = repo_name[len("aspect_rules_js.npm."):]

        link_packages = {}

        for import_path, importer in importers.items():
            dependencies = importer.get("dependencies")
            if type(dependencies) != "dict":
                fail("expected dict of dependencies in processed importer '%s'" % import_path)
            link_package = _link_package(root_package, import_path)
            for dep_package, dep_version in dependencies.items():
                if dep_version.startswith("link:"):
                    continue
                if dep_version[0].isdigit():
                    maybe_package = utils.pnpm_name(dep_package, dep_version)
                elif dep_version.startswith("/"):
                    maybe_package = dep_version[1:]
                else:
                    maybe_package = dep_version
                if package == maybe_package:
                    # this package is a direct dependency at this import path
                    if link_package not in link_packages:
                        link_packages[link_package] = [dep_package]
                    else:
                        link_packages[link_package].append(dep_package)

        # check if this package should be hoisted via public_hoist_packages
        public_hoist_packages = _gather_values_from_matching_names(attr.public_hoist_packages, name, friendly_name, unfriendly_name)
        for public_hoist_package in public_hoist_packages:
            if public_hoist_package not in link_packages:
                link_packages[public_hoist_package] = [name]
            elif name not in link_packages[public_hoist_package]:
                link_packages[public_hoist_package].append(name)

        run_lifecycle_hooks = (
            requires_build and
            attr.run_lifecycle_hooks and
            name not in attr.lifecycle_hooks_exclude and
            friendly_name not in attr.lifecycle_hooks_exclude
        )

        lifecycle_hooks_env = _gather_values_from_matching_names(attr.lifecycle_hooks_envs, "*", name, friendly_name, unfriendly_name)
        lifecycle_hooks_execution_requirements = _gather_values_from_matching_names(attr.lifecycle_hooks_execution_requirements, "*", name, friendly_name, unfriendly_name)

        bins = {}
        for bin in _gather_values_from_matching_names(attr.bins, "*", name, friendly_name, unfriendly_name):
            key_value = bin.split("=", 1)
            if len(key_value) == 2:
                bins[key_value[0]] = key_value[1]
            else:
                msg = "bins contains invalid key value pair '%s', required '=' separator not found" % bin
                fail(msg)

        url = None
        if tarball:
            if _is_url(tarball):
                if registry and tarball.startswith(utils.npm_registry_url):
                    url = registry + tarball[len(utils.npm_registry_url):]
                else:
                    url = tarball
            else:
                # pnpm 6.x may omit the registry component from the tarball value when it is configured
                # via an .npmrc registry setting for the package. If there is a registry value, then use
                # that as the prefix. If there isn't then prefix with the default npm registry value and
                # suggest upgrading to a newer version pnpm.
                if not registry:
                    registry = utils.npm_registry_url

                    # buildifier: disable=print
                    if attr.warn_on_unqualified_tarball_url:
                        print("""

====================================================================================================
WARNING: The pnpm lockfile package entry for {} ({})
does not contain a fully qualified tarball URL or a registry setting to indicate which registry to
use. Prefixing tarball url `{}`
with the default npm registry url `{}`.

If you are using an older version of pnpm such as 6.x, upgrading to 7.x or newer and
re-generating the lockfile should generate a fully qualified tarball URL for this package.

To disable this warning, set `warn_on_unqualified_tarball_url` to False in your
`npm_translate_lock` repository rule.
====================================================================================================

""".format(name, version, tarball, utils.npm_registry_url))
                url = registry + tarball

        result.append(struct(
            custom_postinstall = custom_postinstall,
            deps = deps,
            integrity = integrity,
            link_packages = link_packages,
            name = repo_name,
            package = name,
            patch_args = patch_args,
            patches = patches,
            root_package = root_package,
            run_lifecycle_hooks = run_lifecycle_hooks,
            lifecycle_hooks_env = lifecycle_hooks_env,
            lifecycle_hooks_execution_requirements = lifecycle_hooks_execution_requirements,
            transitive_closure = transitive_closure,
            url = url,
            version = version,
            bins = bins,
        ))

    return result

def _normalize_bazelignore(lines):
    """Make bazelignore lines predictable

    - strip trailing slash so that users can have either of equivalent
        foo/node_modules or foo/node_modules/
    - strip leading ./ so users can have node_modules or ./node_modules
    """
    result = []
    for line in lines:
        if line.startswith("./"):
            result.append(line[2:].rstrip("/"))
        else:
            result.append(line.rstrip("/"))
    return result

def _verify_node_modules_ignored(root_package, importer_paths, bazelignore):
    bazelignore = _normalize_bazelignore(bazelignore.split("\n"))
    missing_ignores = []

    # The pnpm-lock.yaml file package needs to be prefixed on paths
    for i in importer_paths:
        if i == ".":
            expected = root_package
        else:
            expected = paths.normalize(paths.join(root_package, i))

        expected = paths.join(expected, "node_modules")
        if expected not in bazelignore:
            missing_ignores.append(expected)
    return missing_ignores

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
                    msg = """\n\nInvalid public hoist configuration with multiple packages to hoist to '{}/node_modules/{}': {}

Trying selecting a specific version of '{}' to hoist in public_hoist_packages. For example '{}':

    public_hoist_packages = {{
        "{}": ["{}"]
    }}
""".format(
                        link_package,
                        link_name,
                        link_packages,
                        link_name,
                        link_packages[0],
                        link_packages[0],
                        link_package,
                    )
                else:
                    msg = """\n\nInvalid public hoist configuration with multiple packages to hoist to '{}/node_modules/{}': {}

Check the public_hoist_packages attribute for duplicates.
""".format(
                        link_package,
                        link_name,
                        link_packages,
                    )
                fail(msg)

def _validate_attrs(rctx):
    count = 0
    if rctx.attr.yarn_lock:
        count += 1
    if rctx.attr.npm_package_lock:
        count += 1
    if count and not rctx.attr.package_json:
        fail("npm_translate_lock with yarn_lock or npm_package_lock attribute also requires that the package_json attribute is set")
    if rctx.attr.pnpm_lock:
        count += 1

        # don't allow a pnpm lock file that isn't in the root directory of a bazel package
        if paths.dirname(rctx.attr.pnpm_lock.name):
            fail("pnpm-lock.yaml file must be at the root of a bazel package")
        if rctx.attr.package_json:
            fail("The package_json attribute should not be used with pnpm_lock.")
    if count != 1:
        fail("npm_translate_lock requires exactly one of [pnpm_lock, npm_package_lock, yarn_lock] attributes, but {} were set.".format(count))

def _label_str(label):
    return "//{}:{}".format(
        # Ideally we would print the workspace_name, but starting in Bazel 6, it's empty for the
        # local workspace and there's no other way to determine it.
        # label.workspace_name,
        label.package,
        label.name,
    )

def _impl(rctx):
    lockfile = None
    root_package = None
    link_workspace = None
    lockfile_description = None
    npm_auth = _get_npm_auth(rctx)

    _validate_attrs(rctx)

    if rctx.attr.pnpm_lock != None:
        lockfile = _process_lockfile(rctx, rctx.attr.pnpm_lock)

        # root package is the directory of the pnpm_lock file
        root_package = rctx.attr.pnpm_lock.package
        link_workspace = rctx.attr.pnpm_lock.workspace_name

        lockfile_description = _label_str(rctx.attr.pnpm_lock)
    else:
        rctx.file(
            "package.json",
            content = rctx.read(rctx.attr.package_json),
            executable = False,
        )

        if rctx.attr.npm_package_lock:
            lock_attr = rctx.attr.npm_package_lock
            rctx.file(
                "package-lock.json",
                content = rctx.read(rctx.attr.npm_package_lock),
                executable = False,
            )
        elif rctx.attr.yarn_lock:
            lock_attr = rctx.attr.yarn_lock
            rctx.file(
                "yarn.lock",
                content = rctx.read(rctx.attr.yarn_lock),
                executable = False,
            )
        else:
            fail("rules_js internal validation error, please file an issue")

        if rctx.attr.npmrc:
            rctx.file(
                ".npmrc",
                content = rctx.read(rctx.attr.npmrc),
                executable = False,
            )

        result = rctx.execute([
            rctx.path(Label("@nodejs_host//:bin/node")),
            rctx.path(Label("@pnpm//:package/bin/pnpm.cjs")),
            "import",
        ])
        if result.return_code:
            msg = "pnpm import exited with status %s: \nSTDOUT:\n%s\nSTDERR:\n%s" % (result.return_code, result.stdout, result.stderr)
            fail(msg)

        lockfile = _process_lockfile(rctx, "pnpm-lock.yaml")

        # root package is the directory of the lockfile
        root_package = lock_attr.package
        link_workspace = lock_attr.workspace_name

        lockfile_description = "{} and {}".format(
            _label_str(rctx.attr.package_json),
            _label_str(lock_attr),
        )

    # in Bazel 5.3.0, the lock file workspace_name will now be empty if it is the local workspace;
    # we use rctx.attr.link_workspace instead to handle the explicit link workspace name case (e2e/rules_foo for example);
    # check that there isn't conflicting link workspaces if both are set
    if link_workspace and rctx.attr.link_workspace and link_workspace != rctx.attr.link_workspace:
        msg = "lock file workspace_name '{}' and link_workspace '{}' are both set but do not match".format(
            link_workspace,
            rctx.attr.link_workspace,
        )
        fail(msg)

    if not link_workspace:
        link_workspace = rctx.attr.link_workspace

    generated_by_lines = [
        "\"@generated by @aspect_rules_js//npm/private:npm_translate_lock.bzl from {}\"".format(lockfile_description),
        "",  # empty line after bzl docstring since buildifier expects this if this file is vendored in
    ]

    repositories_bzl = generated_by_lines + [
        """load("@aspect_rules_js//npm:npm_import.bzl", "npm_import")""",
        "",
        "def npm_repositories():",
        "    \"Generated npm_import repository rules corresponding to npm packages in {}\"".format(lockfile_description),
    ]

    packages = lockfile.get("packages")
    if not packages:
        fail("expected packages in processed lockfile")

    importers = lockfile.get("importers")
    if not importers:
        fail("expected importers in processed lockfile")

    importer_paths = importers.keys()

    if rctx.attr.verify_node_modules_ignored != None:
        missing_ignores = _verify_node_modules_ignored(root_package, importer_paths, rctx.read(rctx.path(rctx.attr.verify_node_modules_ignored)))
        if missing_ignores:
            fail("""\

ERROR: in verify_node_modules_ignored:
pnpm install will create nested node_modules, but not all of them are ignored by Bazel.
We recommend that all node_modules folders in the source tree be ignored,
to avoid Bazel printing confusing error messages.

Either add line(s) to {bazelignore}:

{fixes}

or disable this check by setting 'verify_node_modules_ignored = None' in `npm_translate_lock(name = "{repo}")`
                """.format(
                fixes = "\n".join(missing_ignores),
                bazelignore = rctx.attr.verify_node_modules_ignored,
                repo = rctx.name,
            ))

    link_packages = [_link_package(root_package, import_path) for import_path in importer_paths]

    defs_bzl_header = generated_by_lines + ["""# buildifier: disable=bzl-visibility
load("@aspect_rules_js//js:defs.bzl", _js_library = "js_library")"""]

    npm_imports = _gen_npm_imports(lockfile, root_package, rctx.attr)

    fp_links = {}
    rctx_files = {
        "BUILD.bazel": generated_by_lines + [
            """load("@bazel_skylib//:bzl_library.bzl", "bzl_library")""",
            "",
            "exports_files({})".format(starlark_codegen_utils.to_list_attr([
                _DEFS_BZL_FILENAME,
                _REPOSITORIES_BZL_FILENAME,
            ])),
        ],
    }

    # Look for first-party file: links in packages
    for package_info in packages.values():
        name = package_info.get("name")
        version = package_info.get("version")
        deps = package_info.get("dependencies")
        if version.startswith("file:"):
            if version in packages and packages[version]["id"]:
                dep_path = _link_package(root_package, packages[version]["id"][len("file:"):])
            else:
                dep_path = _link_package(root_package, version[len("file:"):])
            dep_key = "{}+{}".format(name, version)
            transitive_deps = {}
            for raw_package, raw_version in deps.items():
                if raw_version.startswith("link:") or raw_version.startswith("file:"):
                    dep_store_target = """"//{root_package}:{virtual_store_root}/{{}}/{virtual_store_name}".format(name)""".format(
                        root_package = root_package,
                        virtual_store_name = utils.virtual_store_name(raw_package, "0.0.0"),
                        virtual_store_root = utils.virtual_store_root,
                    )
                elif raw_version.startswith("/"):
                    store_package, store_version = utils.parse_pnpm_name(raw_version[1:])
                    dep_store_target = """"//{root_package}:{virtual_store_root}/{{}}/{virtual_store_name}".format(name)""".format(
                        root_package = root_package,
                        virtual_store_name = utils.virtual_store_name(store_package, store_version),
                        virtual_store_root = utils.virtual_store_root,
                    )
                else:
                    dep_store_target = """"//{root_package}:{virtual_store_root}/{{}}/{virtual_store_name}".format(name)""".format(
                        root_package = root_package,
                        virtual_store_name = utils.virtual_store_name(raw_package, raw_version),
                        virtual_store_root = utils.virtual_store_root,
                    )
                if dep_store_target not in transitive_deps:
                    transitive_deps[dep_store_target] = [raw_package]
                else:
                    transitive_deps[dep_store_target].append(raw_package)

            # collapse link aliases lists into to acomma separated strings
            for dep_store_target in transitive_deps.keys():
                transitive_deps[dep_store_target] = ",".join(transitive_deps[dep_store_target])
            fp_links[dep_key] = {
                "package": name,
                "path": dep_path,
                "link_packages": {},
                "deps": transitive_deps,
            }

    # Look for first-party links in importers
    for import_path, importer in importers.items():
        dependencies = importer.get("dependencies")
        if type(dependencies) != "dict":
            fail("expected dict of dependencies in processed importer '%s'" % import_path)
        link_package = _link_package(root_package, import_path)
        for dep_package, dep_version in dependencies.items():
            if dep_version.startswith("file:"):
                if dep_version in packages and packages[dep_version]["id"]:
                    dep_path = _link_package(root_package, packages[dep_version]["id"][len("file:"):])
                else:
                    dep_path = _link_package(root_package, dep_version[len("file:"):])
                dep_key = "{}+{}".format(dep_package, dep_version)
                if not dep_key in fp_links.keys():
                    fail("Expected to file: referenced package {} in first-party links".format(dep_key))
                fp_links[dep_key]["link_packages"][link_package] = []
            elif dep_version.startswith("link:"):
                dep_importer = paths.normalize(paths.join(import_path, dep_version[len("link:"):]))
                dep_path = _link_package(root_package, import_path, dep_version[len("link:"):])
                dep_key = "{}+{}".format(dep_package, dep_path)
                if dep_key in fp_links.keys():
                    fp_links[dep_key]["link_packages"][link_package] = []
                else:
                    transitive_deps = {}
                    raw_deps = {}
                    if dep_importer in importers.keys():
                        raw_deps = importers.get(dep_importer).get("dependencies")
                    for raw_package, raw_version in raw_deps.items():
                        if raw_version.startswith("link:") or raw_version.startswith("file:"):
                            dep_store_target = """"//{root_package}:{virtual_store_root}/{{}}/{virtual_store_name}".format(name)""".format(
                                root_package = root_package,
                                virtual_store_name = utils.virtual_store_name(raw_package, "0.0.0"),
                                virtual_store_root = utils.virtual_store_root,
                            )
                        elif raw_version.startswith("/"):
                            store_package, store_version = utils.parse_pnpm_name(raw_version[1:])
                            dep_store_target = """"//{root_package}:{virtual_store_root}/{{}}/{virtual_store_name}".format(name)""".format(
                                root_package = root_package,
                                virtual_store_name = utils.virtual_store_name(store_package, store_version),
                                virtual_store_root = utils.virtual_store_root,
                            )
                        else:
                            dep_store_target = """"//{root_package}:{virtual_store_root}/{{}}/{virtual_store_name}".format(name)""".format(
                                root_package = root_package,
                                virtual_store_name = utils.virtual_store_name(raw_package, raw_version),
                                virtual_store_root = utils.virtual_store_root,
                            )
                        if dep_store_target not in transitive_deps:
                            transitive_deps[dep_store_target] = [raw_package]
                        else:
                            transitive_deps[dep_store_target].append(raw_package)

                    # collapse link aliases lists into to acomma separated strings
                    for dep_store_target in transitive_deps.keys():
                        transitive_deps[dep_store_target] = ",".join(transitive_deps[dep_store_target])
                    fp_links[dep_key] = {
                        "package": dep_package,
                        "path": dep_path,
                        "link_packages": {link_package: []},
                        "deps": transitive_deps,
                    }

    if fp_links:
        defs_bzl_header.append("""load("@aspect_rules_js//npm/private:npm_link_package_store.bzl", _npm_link_package_store = "npm_link_package_store")
load("@aspect_rules_js//npm/private:npm_package_store.bzl", _npm_package_store = "npm_package_store")""")

    defs_bzl_body = [
        """def npm_link_all_packages(name = "node_modules", imported_links = []):
    \"\"\"Generated list of npm_link_package() target generators and first-party linked packages corresponding to the packages in {lockfile_description}

    Args:
        name: name of catch all target to generate for all packages linked
        imported_links: optional list link functions from manually imported packages
            that were fetched with npm_import rules,

            For example,

            ```
            load("@npm//:defs.bzl", "npm_link_all_packages")
            load("@npm_meaning-of-life__links//:defs.bzl", npm_link_meaning_of_life = "npm_link_imported_package")

            npm_link_all_packages(
                name = "node_modules",
                imported_links = [
                    npm_link_meaning_of_life,
                ],
            )```
    \"\"\"

    root_package = "{root_package}"
    link_packages = {link_packages}
    is_root = native.package_name() == root_package
    link = native.package_name() in link_packages
    if not is_root and not link:
        msg = "The npm_link_all_packages() macro loaded from {defs_bzl_file} and called in bazel package '%s' may only be called in the bazel package(s) corresponding to the root package '{root_package}' and packages [{link_packages_comma_separated}]" % native.package_name()
        fail(msg)
    link_targets = []
    scope_targets = {{}}

    for link_fn in imported_links:
        new_link_targets, new_scope_targets = link_fn(name)
        link_targets.extend(new_link_targets)
        for _scope, _targets in new_scope_targets.items():
            scope_targets[_scope] = scope_targets[_scope] + _targets if _scope in scope_targets else _targets
""".format(
            lockfile_description = lockfile_description,
            root_package = root_package,
            link_packages = str(link_packages),
            link_packages_comma_separated = "'" + "', '".join(link_packages) + "'" if len(link_packages) else "",
            defs_bzl_file = "@{}//:{}".format(rctx.name, _DEFS_BZL_FILENAME),
        ),
    ]

    # check all links and fail if there are duplicates which can happen with public hoisting
    _check_for_conflicting_public_links(npm_imports, rctx.attr.public_hoist_packages)

    stores_bzl = []
    links_bzl = {}
    for (i, _import) in enumerate(npm_imports):
        maybe_integrity = """
        integrity = "%s",""" % _import.integrity if _import.integrity else ""
        maybe_url = """
        url = "%s",""" % _import.url if _import.url else ""
        maybe_deps = ("""
        deps = %s,""" % starlark_codegen_utils.to_dict_attr(_import.deps, 2)) if len(_import.deps) > 0 else ""
        maybe_transitive_closure = ("""
        transitive_closure = %s,""" % starlark_codegen_utils.to_dict_list_attr(_import.transitive_closure, 2)) if len(_import.transitive_closure) > 0 else ""
        maybe_patches = ("""
        patches = %s,""" % _import.patches) if len(_import.patches) > 0 else ""
        maybe_patch_args = ("""
        patch_args = %s,""" % _import.patch_args) if len(_import.patches) > 0 and len(_import.patch_args) > 0 else ""
        maybe_custom_postinstall = ("""
        custom_postinstall = \"%s\",""" % _import.custom_postinstall) if _import.custom_postinstall else ""
        maybe_run_lifecycle_hooks = ("""
        run_lifecycle_hooks = True,""") if _import.run_lifecycle_hooks else ""
        maybe_lifecycle_hooks_env = ("""
        lifecycle_hooks_env = %s,""" % _import.lifecycle_hooks_env) if _import.run_lifecycle_hooks and _import.lifecycle_hooks_env else ""
        maybe_lifecycle_hooks_execution_requirements = ("""
        lifecycle_hooks_execution_requirements = %s,""" % _import.lifecycle_hooks_execution_requirements) if _import.run_lifecycle_hooks and _import.lifecycle_hooks_execution_requirements else ""
        maybe_bins = ("""
        bins = %s,""" % starlark_codegen_utils.to_dict_attr(_import.bins, 2)) if len(_import.bins) > 0 else ""

        _registry_url = _import.url if _import.url else utils.npm_registry_url
        _registry = _registry_url.split("//", 1)[-1].removesuffix("/")
        maybe_npm_auth = ("""
        npm_auth = "%s",""" % npm_auth[_registry]) if _registry in npm_auth else ""

        repositories_bzl.append(_NPM_IMPORT_TMPL.format(
            link_packages = starlark_codegen_utils.to_dict_attr(_import.link_packages, 2, quote_value = False),
            link_workspace = link_workspace,
            maybe_custom_postinstall = maybe_custom_postinstall,
            maybe_deps = maybe_deps,
            maybe_integrity = maybe_integrity,
            maybe_patch_args = maybe_patch_args,
            maybe_patches = maybe_patches,
            maybe_run_lifecycle_hooks = maybe_run_lifecycle_hooks,
            maybe_lifecycle_hooks_env = maybe_lifecycle_hooks_env,
            maybe_lifecycle_hooks_execution_requirements = maybe_lifecycle_hooks_execution_requirements,
            lifecycle_hooks_no_sandbox = rctx.attr.lifecycle_hooks_no_sandbox,
            maybe_transitive_closure = maybe_transitive_closure,
            maybe_url = maybe_url,
            maybe_bins = maybe_bins,
            name = _import.name,
            package = _import.package,
            root_package = _import.root_package,
            version = _import.version,
            maybe_npm_auth = maybe_npm_auth,
        ))

        if _import.link_packages:
            defs_bzl_header.append(
                """load("@{repo_name}{links_repo_suffix}//:defs.bzl", link_{i} = "npm_link_imported_package_store", store_{i} = "npm_imported_package_store")""".format(
                    i = i,
                    repo_name = _import.name,
                    links_repo_suffix = utils.links_repo_suffix,
                ),
            )
        else:
            defs_bzl_header.append(
                """load("@{repo_name}{links_repo_suffix}//:defs.bzl", store_{i} = "npm_imported_package_store")""".format(
                    i = i,
                    repo_name = _import.name,
                    links_repo_suffix = utils.links_repo_suffix,
                ),
            )

        stores_bzl.append("""        store_{i}(name = "{{}}/{name}".format(name))""".format(
            i = i,
            name = _import.package,
        ))
        for link_package, _link_aliases in _import.link_packages.items():
            link_aliases = _link_aliases or [_import.package]
            for link_alias in link_aliases:
                if link_package not in links_bzl:
                    links_bzl[link_package] = []
                links_bzl[link_package].append("""            link_targets.append(link_{i}(name = "{{}}/{name}".format(name)))""".format(
                    i = i,
                    name = link_alias,
                ))
                if len(link_alias.split("/", 1)) > 1:
                    package_scope = link_alias.split("/", 1)[0]
                    links_bzl[link_package].append("""            scope_targets["{package_scope}"] = scope_targets["{package_scope}"] + [link_targets[-1]] if "{package_scope}" in scope_targets else [link_targets[-1]]""".format(
                        package_scope = package_scope,
                    ))
        pkgs = lockfile.get("packages").values()
        for link_package in _import.link_packages.keys():
            if pkgs[i].get("hasBin"):
                build_file_path = paths.normalize(paths.join(link_package, "BUILD.bazel"))
                if build_file_path not in rctx_files.keys():
                    rctx_files[build_file_path] = generated_by_lines + [
                        """load("@bazel_skylib//:bzl_library.bzl", "bzl_library")""",
                    ]
                rctx_files[build_file_path].append(_BZL_LIBRARY_TMPL.format(
                    name = _import.package,
                    src = ":" + paths.join(_import.package, _PACKAGE_JSON_BZL_FILENAME),
                    dep = "@{repo_name}//{link_package}:{package_name}".format(
                        repo_name = _import.name,
                        link_package = link_package,
                        package_name = link_package.split("/")[-1] or _import.package.split("/")[-1],
                    ),
                ))
                package_json_bzl_file_path = paths.normalize(paths.join(link_package, _import.package, _PACKAGE_JSON_BZL_FILENAME))
                repo_package_json_bzl = "@{repo_name}//{link_package}:{package_json_bzl}".format(
                    repo_name = _import.name,
                    link_package = link_package,
                    package_json_bzl = _PACKAGE_JSON_BZL_FILENAME,
                )
                rctx.file(package_json_bzl_file_path, "\n".join([
                    _BIN_TMPL.format(
                        repo_package_json_bzl = repo_package_json_bzl,
                    ),
                ]))

    defs_bzl_body.append("""    if is_root:""")
    defs_bzl_body.extend(stores_bzl)

    defs_bzl_body.append("""    if link:""")
    for link_package, bzl in links_bzl.items():
        defs_bzl_body.append("""        if native.package_name() == "{}":""".format(link_package))
        defs_bzl_body.extend(bzl)

    for fp_link in fp_links.values():
        fp_package = fp_link.get("package")
        fp_path = fp_link.get("path")
        fp_link_packages = fp_link.get("link_packages")
        fp_deps = fp_link.get("deps")
        fp_bazel_name = utils.bazel_name(fp_package, fp_path)
        fp_target = "//{}:{}".format(fp_path, paths.basename(fp_path))

        defs_bzl_body.append(_FP_STORE_TMPL.format(
            bazel_name = fp_bazel_name,
            deps = starlark_codegen_utils.to_dict_attr(fp_deps, 3, quote_key = False),
            npm_package_target = fp_target,
            package = fp_package,
            virtual_store_name = utils.virtual_store_name(fp_package, "0.0.0"),
            virtual_store_root = utils.virtual_store_root,
        ))

        defs_bzl_body.append(_FP_DIRECT_TMPL.format(
            bazel_name = fp_bazel_name,
            link_packages = fp_link_packages.keys(),
            name = fp_package,
            package_directory_output_group = utils.package_directory_output_group,
            root_package = root_package,
            virtual_store_name = utils.virtual_store_name(fp_package, "0.0.0"),
            virtual_store_root = utils.virtual_store_root,
        ))

        if len(fp_package.split("/", 1)) > 1:
            package_scope = fp_package.split("/", 1)[0]
            defs_bzl_body.append("""            scope_targets["{package_scope}"] = scope_targets["{package_scope}"] + [link_targets[-1]] if "{package_scope}" in scope_targets else [link_targets[-1]]""".format(
                package_scope = package_scope,
            ))

    # Generate catch all & scoped npm_linked_packages target
    defs_bzl_body.append("""
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

    rctx.file(_DEFS_BZL_FILENAME, "\n".join(defs_bzl_header + [""] + defs_bzl_body + [""]))
    rctx.file(_REPOSITORIES_BZL_FILENAME, "\n".join(repositories_bzl))
    for filename, contents in rctx_files.items():
        rctx.file(filename, "\n".join(contents))

npm_translate_lock = struct(
    implementation = _impl,
    attrs = _ATTRS,
    gen_npm_imports = _gen_npm_imports,
)

npm_translate_lock_testonly = struct(
    testonly_process_lockfile = _process_lockfile,
    verify_node_modules_ignored = _verify_node_modules_ignored,
)
