"Utility functions for npm rules"

load("@aspect_bazel_lib//lib:paths.bzl", "relative_file")
load("@aspect_bazel_lib//lib:repo_utils.bzl", "repo_utils")
load("@aspect_bazel_lib//lib:utils.bzl", bazel_lib_utils = "utils")
load("@bazel_skylib//lib:paths.bzl", "paths")
load("@bazel_skylib//lib:types.bzl", "types")

INTERNAL_ERROR_MSG = "ERROR: rules_js internal error, please file an issue: https://github.com/aspect-build/rules_js/issues"
DEFAULT_REGISTRY_DOMAIN = "registry.npmjs.org"
DEFAULT_REGISTRY_DOMAIN_SLASH = "{}/".format(DEFAULT_REGISTRY_DOMAIN)
DEFAULT_REGISTRY_PROTOCOL = "https"
DEFAULT_EXTERNAL_REPOSITORY_ACTION_CACHE = ".aspect/rules/external_repository_action_cache"

def _sorted_map(m):
    result = dict()
    for key in sorted(m.keys()):
        result[key] = m[key]

    return result

def _sanitize_string(string):
    # Workspace names may contain only A-Z, a-z, 0-9, '-', '_' and '.'
    result = ""
    for i in range(0, len(string)):
        c = string[i]
        if c == "@" and (not result or result[-1] == "_"):
            result += "at"
        if not c.isalnum() and c != "-" and c != "_" and c != ".":
            c = "_"
        result += c
    return result

def _bazel_name(name, version = None):
    "Make a bazel friendly name from a package name and (optionally) a version that can be used in repository and target names"
    escaped_name = _sanitize_string(name)
    if not version:
        return escaped_name
    version_segments = version.split("_")
    escaped_version = _sanitize_string(version_segments[0])
    peer_version = "_".join(version_segments[1:])
    if peer_version:
        escaped_version = "%s__%s" % (escaped_version, _sanitize_string(peer_version))
    return "%s__%s" % (escaped_name, escaped_version)

def _to_package_key(name, version):
    if not version[0].isdigit():
        return version
    return "{}@{}".format(name, version)

def _strip_v5_peer_dep_or_patched_version(version):
    "Remove peer dependency or patched syntax from version string"

    # 21.1.0_rollup@2.70.2 becomes 21.1.0
    # 1.0.0_o3deharooos255qt5xdujc3cuq becomes 1.0.0
    index = version.find("_")
    if index != -1:
        return version[:index]
    return version

def _pnpm_name(name, version):
    "Make a name/version pnpm-style name for a package name and version"
    return "%s@%s" % (name, version)

# Metadata about a pnpm "project" (importer).
#
# Metadata may come from different locations depending on the lockfile, this struct should
# have data normalized across lockfiles.
def _new_import_info(dependencies, dev_dependencies, optional_dependencies):
    return {
        "dependencies": dependencies,
        "dev_dependencies": dev_dependencies,
        "optional_dependencies": optional_dependencies,
    }

# Metadata about a package.
#
# Metadata may come from different locations depending on the lockfile, this struct should
# have data normalized across lockfiles.
def _new_package_info(id, name, dependencies, optional_dependencies, peer_dependencies, dev, has_bin, optional, requires_build, version, friendly_version, resolution):
    return {
        "id": id,
        "name": name,
        "dependencies": dependencies,
        "optional_dependencies": optional_dependencies,
        "peer_dependencies": peer_dependencies,
        "dev": dev,
        "has_bin": has_bin,
        "optional": optional,
        "requires_build": requires_build,
        "version": version,
        "friendly_version": friendly_version,
        "resolution": resolution,
    }

def _strip_default_registry(name_version):
    # Strip the default registry from the name_version string
    if name_version.startswith(DEFAULT_REGISTRY_DOMAIN_SLASH):
        return name_version[len(DEFAULT_REGISTRY_DOMAIN_SLASH):]
    return name_version

def _strip_v5_default_registry_to_version(name, version):
    # Strip the default registry/name/ from the version string
    pre = DEFAULT_REGISTRY_DOMAIN_SLASH + name + "/"
    if version.startswith(pre):
        return version[len(pre):]
    return version

def _convert_v5_importer_dependency_map(specifiers, deps):
    result = {}
    for name, version in deps.items():
        specifier = specifiers.get(name)

        if specifier.startswith("npm:"):
            # Keep the npm: specifier for aliased dependencies
            # convert v5 style aliases ([default_registry]/aliased/version) to npm:aliased@version
            alias, version = _strip_default_registry(version).lstrip("/").rsplit("/", 1)
            version = "npm:{}@{}".format(alias, version)
        else:
            # Transition [registry/]name/version[_patch][_peer_data] to a rules_js version format
            version = _convert_pnpm_v5_version_peer_dep(_strip_v5_default_registry_to_version(name, version))

        result[name] = version
    return result

def _convert_v5_importers(importers):
    result = {}
    for import_path, importer in importers.items():
        specifiers = importer.get("specifiers", {})

        result[import_path] = _new_import_info(
            dependencies = _convert_v5_importer_dependency_map(specifiers, importer.get("dependencies", {})),
            dev_dependencies = _convert_v5_importer_dependency_map(specifiers, importer.get("devDependencies", {})),
            optional_dependencies = _convert_v5_importer_dependency_map(specifiers, importer.get("optionalDependencies", {})),
        )
    return result

def _convert_pnpm_v5_version_peer_dep(version):
    # Covert a pnpm lock file v5 version string of the format
    # 1.2.3_@scope+peer@2.0.2_@scope+peer@4.5.6
    # to a version_peer_version that is compatible with rules_js.

    # If there is a suffix to the version
    peer_dep_index = version.find("_")
    if peer_dep_index != -1:
        # if the suffix contains an @version (not just a _patchhash)
        peer_dep_index = version.find("@", peer_dep_index)
        if peer_dep_index != -1:
            peer_dep = version[peer_dep_index:]
            version = version[0:peer_dep_index] + _sanitize_string(peer_dep)

    return version

def _convert_pnpm_v5_package_dependency_version(name, version):
    # an alias to an alternate package
    if version.startswith("/"):
        alias, version = version[1:].rsplit("/", 1)
        return "npm:{}@{}".format(alias, version)

    # Removing the default registry+name from the version string
    version = _strip_v5_default_registry_to_version(name, version)

    # Convert peer dependency data to rules_js ~v5 format
    version = _convert_pnpm_v5_version_peer_dep(version)

    return version

def _convert_pnpm_v5_package_dependency_map(deps):
    result = {}
    for name, version in deps.items():
        result[name] = _convert_pnpm_v5_package_dependency_version(name, version)
    return result

def _convert_v5_v6_file_package(package_path, package_snapshot):
    if "name" not in package_snapshot:
        msg = "expected package {} to have a name field".format(package_path)
        fail(msg)

    name = package_snapshot["name"]
    version = package_path
    if _is_vendored_tarfile(package_snapshot):
        if "version" in package_snapshot:
            version = package_snapshot["version"]
        friendly_version = version
    else:
        friendly_version = package_snapshot["version"] if "version" in package_snapshot else version

    return name, version, friendly_version

def _convert_v5_packages(packages):
    result = {}
    for package_path, package_snapshot in packages.items():
        if "resolution" not in package_snapshot:
            msg = "package {} has no resolution field".format(package_path)
            fail(msg)

        package_path = _convert_pnpm_v5_version_peer_dep(package_path)

        if package_path.startswith("file:"):
            # direct reference to file
            name, version, friendly_version = _convert_v5_v6_file_package(package_path, package_snapshot)
        elif "name" in package_snapshot and "version" in package_snapshot:
            # key/path is complicated enough the real name+version are properties
            name = package_snapshot["name"]
            version = _strip_v5_default_registry_to_version(name, package_path)
            friendly_version = package_snapshot["version"]
        elif package_path.startswith("/"):
            # a simple /name/version[_peer_info]
            name, version = package_path[1:].rsplit("/", 1)
            friendly_version = _strip_v5_peer_dep_or_patched_version(version)
        else:
            msg = "unexpected package path: {} of {}".format(package_path, package_snapshot)
            fail(msg)

        package_key = _to_package_key(name, version)

        package_info = _new_package_info(
            id = package_snapshot.get("id", None),
            name = name,
            version = version,
            friendly_version = friendly_version,
            dependencies = _convert_pnpm_v5_package_dependency_map(package_snapshot.get("dependencies", {})),
            peer_dependencies = _convert_pnpm_v5_package_dependency_map(package_snapshot.get("peerDependencies", {})),
            optional_dependencies = _convert_pnpm_v5_package_dependency_map(package_snapshot.get("optionalDependencies", {})),
            dev = package_snapshot.get("dev", False),
            has_bin = package_snapshot.get("hasBin", False),
            optional = package_snapshot.get("optional", False),
            requires_build = package_snapshot.get("requiresBuild", False),
            resolution = package_snapshot.get("resolution"),
        )

        if package_key in result:
            msg = "WARNING: duplicate package: {}\n\t{}\n\t{}".format(package_key, result[package_key], package_info)

            # buildifier: disable=print
            print(msg)

        result[package_key] = package_info
    return result

def _convert_pnpm_v6_v9_version_peer_dep(version):
    # Covert a pnpm lock file v6 version string of the format
    # 1.2.3(@scope/peer@2.0.2)(@scope/peer@4.5.6)
    # to a version_peer_version that is compatible with rules_js.
    if version[-1] == ")":
        # Drop the patch_hash= not present in v5 so (patch_hash=123) -> (123) like v5
        version = version.replace("(patch_hash=", "(")

        # There is a peer dep if the string ends with ")"
        peer_dep_index = version.find("(")
        peer_dep = version[peer_dep_index:]
        if len(peer_dep) > 32:
            # Prevent long paths. The pnpm lockfile v6 no longer hashes long sequences of
            # peer deps so we must hash here to prevent extremely long file paths that lead to
            # "File name too long) build failures.
            peer_dep = "_" + _hash(peer_dep)
        version = version[0:peer_dep_index] + _sanitize_string(peer_dep)
        version = version.rstrip("_")
    return version

def _strip_v6_default_registry_to_version(name, version):
    # Strip the default registry/name@ from the version string
    pre = DEFAULT_REGISTRY_DOMAIN_SLASH + name + "@"
    if version.startswith(pre):
        return version[len(pre):]
    return version

def _convert_pnpm_v6_importer_dependency_map(deps):
    result = {}
    for name, attributes in deps.items():
        specifier = attributes.get("specifier")
        version = attributes.get("version")

        if specifier.startswith("npm:"):
            # Keep the npm: specifier for aliased dependencies
            # convert v6 style aliases ([registry]/aliased@version) to npm:aliased@version
            alias, version = _strip_default_registry(version).lstrip("/").rsplit("@", 1)
            version = "npm:{}@{}".format(alias, version)
        else:
            # Transition [registry/]name@version[(peer)(data)] to a rules_js version format
            version = _convert_pnpm_v6_v9_version_peer_dep(_strip_v6_default_registry_to_version(name, version))

        result[name] = version
    return result

def _convert_v6_importers(importers):
    # Convert pnpm lockfile v6 importers to a rules_js compatible ~v5 format.
    #
    # v5 importers:
    #   specifiers:
    #      pkg-a: 1.2.3
    #      pkg-b: ^4.5.6
    #   deps:
    #      pkg-a: 1.2.3
    #   devDeps:
    #      pkg-b: 4.10.1
    #   ...
    #
    # v6 pushed the 'specifiers' and 'version' into subproperties:
    #
    #   deps:
    #      pkg-a:
    #         specifier: 1.2.3
    #         version: 1.2.3
    #   devDeps:
    #      pkg-b:
    #          specifier: ^4.5.6
    #          version: 4.10.1

    result = {}
    for import_path, importer in importers.items():
        result[import_path] = _new_import_info(
            dependencies = _convert_pnpm_v6_importer_dependency_map(importer.get("dependencies", {})),
            dev_dependencies = _convert_pnpm_v6_importer_dependency_map(importer.get("devDependencies", {})),
            optional_dependencies = _convert_pnpm_v6_importer_dependency_map(importer.get("optionalDependencies", {})),
        )
    return result

def _convert_pnpm_v6_package_dependency_version(name, version):
    # an alias to an alternate package
    if version.startswith("/"):
        alias, version = version[1:].rsplit("@", 1)
        return "npm:{}@{}".format(alias, version)

    # Removing the default registry+name from the version string
    version = _strip_v6_default_registry_to_version(name, version)

    # Convert peer dependency data to rules_js ~v5 format
    version = _convert_pnpm_v6_v9_version_peer_dep(version)

    return version

def _convert_pnpm_v6_package_dependency_map(deps):
    result = {}
    for name, version in deps.items():
        result[name] = _convert_pnpm_v6_package_dependency_version(name, version)
    return result

def _convert_v6_packages(packages):
    # Convert pnpm lockfile v6 importers to a rules_js compatible ~v5 format.
    #
    # v6 package metadata mainly changed formatting of metadata such as:
    #
    # dependency versions with peers:
    #   v5: 2.0.0_@aspect-test+c@2.0.2
    #   v6: 2.0.0(@aspect-test/c@2.0.2)

    result = {}
    for package_path, package_snapshot in packages.items():
        if "resolution" not in package_snapshot:
            msg = "package {} has no resolution field".format(package_path)
            fail(msg)

        package_path = _convert_pnpm_v6_v9_version_peer_dep(package_path)

        if package_path.startswith("file:"):
            # direct reference to file
            name, version, friendly_version = _convert_v5_v6_file_package(package_path, package_snapshot)
        elif "name" in package_snapshot and "version" in package_snapshot:
            # key/path is complicated enough the real name+version are properties
            name = package_snapshot["name"]
            version = _strip_v6_default_registry_to_version(name, package_path)
            friendly_version = package_snapshot["version"]
        elif package_path.startswith("/"):
            # plain /pkg@version(_peer_info)
            name, version = package_path[1:].rsplit("@", 1)
            friendly_version = _strip_v5_peer_dep_or_patched_version(version)  # NOTE: already converted to v5 peer style
        else:
            msg = "unexpected package path: {} of {}".format(package_path, package_snapshot)
            fail(msg)

        package_key = _to_package_key(name, version)

        package_info = _new_package_info(
            id = package_snapshot.get("id", None),
            name = name,
            version = version,
            friendly_version = friendly_version,
            dependencies = _convert_pnpm_v6_package_dependency_map(package_snapshot.get("dependencies", {})),
            peer_dependencies = _convert_pnpm_v6_package_dependency_map(package_snapshot.get("peerDependencies", {})),
            optional_dependencies = _convert_pnpm_v6_package_dependency_map(package_snapshot.get("optionalDependencies", {})),
            dev = package_snapshot.get("dev", False),
            has_bin = package_snapshot.get("hasBin", False),
            optional = package_snapshot.get("optional", False),
            requires_build = package_snapshot.get("requiresBuild", False),
            resolution = package_snapshot.get("resolution"),
        )

        if package_key in result:
            msg = "ERROR: duplicate package: {}\n\t{}\n\t{}".format(package_key, result[package_key], package_info)

            # buildifier: disable=print
            print(msg)

        result[package_key] = package_info

    return result

def _convert_pnpm_v9_package_dependency_version(snapshots, name, version):
    # Detect when an alias is just a direct reference to another snapshot
    if version in snapshots:
        return "npm:{}".format(version)

    # Convert peer dependency data to rules_js ~v5 format
    version = _convert_pnpm_v6_v9_version_peer_dep(version)

    return version

def _convert_pnpm_v9_package_dependency_map(snapshots, deps):
    result = {}
    for name, version in deps.items():
        result[name] = _convert_pnpm_v9_package_dependency_version(snapshots, name, version)
    return result

def _convert_pnpm_v9_importer_dependency_map(deps):
    result = {}
    for name, attributes in deps.items():
        specifier = attributes.get("specifier")
        version = attributes.get("version")

        if specifier.startswith("npm:"):
            # Keep the npm: specifier for aliased dependencies
            alias, version = version.rsplit("@", 1)
            version = "npm:{}@{}".format(alias, version)
        else:
            # Transition version[(patch)(peer)(data)] to a rules_js version format
            version = _convert_pnpm_v6_v9_version_peer_dep(version)

        result[name] = version
    return result

def _convert_v9_importers(importers):
    # Convert pnpm lockfile v9 importers to a rules_js compatible ~v5 format.
    # Almost identical to v6 but with fewer odd edge cases.

    result = {}
    for import_path, importer in importers.items():
        result[import_path] = _new_import_info(
            dependencies = _convert_pnpm_v9_importer_dependency_map(importer.get("dependencies", {})),
            dev_dependencies = _convert_pnpm_v9_importer_dependency_map(importer.get("devDependencies", {})),
            optional_dependencies = _convert_pnpm_v9_importer_dependency_map(importer.get("optionalDependencies", {})),
        )
    return result

def _convert_v9_packages(packages, snapshots):
    # Convert pnpm lockfile v9 importers to a rules_js compatible format.

    # v9 split package metadata (v6 "packages" field) into 2:
    #
    # The 'snapshots' keys contain the resolved dependencies such as each unique combo of deps/peers/versions
    # while 'packages' contain the static information about each and every package@version such as hasBin,
    # resolution and static dep data.
    #
    # Note all static registry info such as URLs has moved from the 'importers[x/pkg@version].version' and 'packages[x/pkg@version]' to
    # only being present in the actual packages[pkg@version].resolution.*
    #
    # Example:
    #
    #  packages:
    #    '@scoped/name@5.0.2'
    #       hasBin
    #       resolution (registry-url, integrity etc)
    #       peerDependencies which *might* be resolved
    #
    #  snapshots:
    #    pkg@http://a/url
    #       ...
    #
    #    '@scoped/name@2.0.0(peer@2.0.2)'
    #       dependencies:
    #           a-dep: 1.2.3
    #           peer: 2.0.2
    #           b-dep: 3.2.1(peer-b@4.5.6)
    #           alias: actual@1.2.3
    #           l: file:../path/to/dir
    #           x: https://a/url/v1.2.3.tar.gz

    result = {}

    # Snapshots contains the packages with the keys (which include peers) to return
    for package_key, package_snapshot in snapshots.items():
        peer_meta_index = package_key.find("(")
        static_key = package_key[:peer_meta_index] if peer_meta_index > 0 else package_key
        if not static_key in packages:
            msg = "package {} not found in pnpm 'packages'".format(static_key)
            fail(msg)

        package_data = packages[static_key]

        if "resolution" not in package_data:
            msg = "package {} has no resolution field".format(static_key)
            fail(msg)

        # the raw name + version are the key, not including peerDeps+patch
        version_index = static_key.index("@", 1)
        name = static_key[:version_index]
        package_key = _convert_pnpm_v6_v9_version_peer_dep(package_key)

        # Extract the version including peerDeps+patch from the key
        version = package_key[package_key.index("@", 1) + 1:]

        # package_data can have the resolved "version" for things like https:// deps
        friendly_version = package_data["version"] if "version" in package_data else static_key[version_index + 1:]

        package_info = _new_package_info(
            id = package_data.get("id", None),  # TODO: does v9 have "id"?
            name = name,
            version = version,
            friendly_version = friendly_version,
            dependencies = _convert_pnpm_v9_package_dependency_map(snapshots, package_snapshot.get("dependencies", {})),
            optional_dependencies = _convert_pnpm_v9_package_dependency_map(snapshots, package_snapshot.get("optionalDependencies", {})),
            peer_dependencies = package_data.get("peerDependencies", {}),
            dev = None,  # TODO(pnpm9): must inspect importers.*.devDependencies?
            has_bin = package_data.get("hasBin", False),
            optional = package_snapshot.get("optional", False),
            requires_build = None,  # Unknown from lockfile in v9
            resolution = package_data.get("resolution"),
        )

        if package_key in result:
            msg = "ERROR: duplicate package: {}\n\t{}\n\t{}".format(package_key, result[package_key], package_info)
            fail(msg)

        result[package_key] = package_info

    return result

def _parse_pnpm_lock_json(content):
    """Parse the content of a pnpm-lock.yaml file.

    Args:
        content: lockfile content as json

    Returns:
        A tuple of (importers dict, packages dict, patched_dependencies dict, error string)
    """
    return _parse_pnpm_lock_common(json.decode(content) if content else None, None)

def _parse_pnpm_lock_common(parsed, err):
    """Helper function used by _parse_pnpm_lock_json.

    Args:
        parsed: lockfile content object
        err: any errors from pasring

    Returns:
        A tuple of (importers dict, packages dict, patched_dependencies dict, error string)
    """
    if err != None or parsed == None or parsed == {}:
        return {}, {}, {}, err

    if not types.is_dict(parsed):
        return {}, {}, {}, "lockfile should be a starlark dict"
    if "lockfileVersion" not in parsed.keys():
        return {}, {}, {}, "expected lockfileVersion key in lockfile"

    # Lockfile version may be a float such as 5.4 or a string such as '6.0'
    lockfile_version = str(parsed["lockfileVersion"])
    lockfile_version = lockfile_version.lstrip("'")
    lockfile_version = lockfile_version.rstrip("'")
    lockfile_version = lockfile_version.lstrip("\"")
    lockfile_version = lockfile_version.rstrip("\"")
    lockfile_version = float(lockfile_version)
    _assert_lockfile_version(lockfile_version)

    # Fallback to {".": parsed} for non-workspace lockfiles where the deps are at the root.
    importers = parsed.get("importers", {".": parsed})
    packages = parsed.get("packages", {})
    patched_dependencies = parsed.get("patchedDependencies", {})

    if lockfile_version < 6.0:
        importers = _convert_v5_importers(importers)
        packages = _convert_v5_packages(packages)
    elif lockfile_version < 9.0:
        importers = _convert_v6_importers(importers)
        packages = _convert_v6_packages(packages)
    else:  # >= 9
        snapshots = parsed.get("snapshots", {})
        importers = _convert_v9_importers(importers)
        packages = _convert_v9_packages(packages, snapshots)

    importers = _sorted_map(importers)
    packages = _sorted_map(packages)

    return importers, packages, patched_dependencies, lockfile_version, None

def _assert_lockfile_version(version, testonly = False):
    if type(version) != type(1.0):
        fail("version should be passed as a float")

    # Restrict the supported lock file versions to what this code has been tested with:
    #   5.4 - pnpm v7.0.0 bumped the lockfile version to 5.4
    #   6.0 - pnpm v8.0.0 bumped the lockfile version to 6.0; this included breaking changes
    #   6.1 - pnpm v8.6.0 bumped the lockfile version to 6.1
    #   9.0 - pnpm v9.0.0 bumped the lockfile version to 9.0
    min_lock_version = 5.4
    max_lock_version = 9.0
    msg = None

    if version < min_lock_version:
        msg = "npm_translate_lock requires lock_version at least {min}, but found {actual}. Please upgrade to pnpm v7 or greater.".format(
            min = min_lock_version,
            actual = version,
        )
    if version > max_lock_version:
        msg = "npm_translate_lock currently supports a maximum lock_version of {max}, but found {actual}. Please file an issue on rules_js".format(
            max = max_lock_version,
            actual = version,
        )
    if msg and not testonly:
        fail(msg)
    return msg

def _friendly_name(name, version):
    "Make a name@version developer-friendly name for a package name and version"
    return "%s@%s" % (name, version)

def _package_store_name(pnpm_name, pnpm_version):
    "Make a package store name for a given package and version"

    if pnpm_version.startswith("link:") or pnpm_version.startswith("file:"):
        name = pnpm_name
        version = "0.0.0"
    elif pnpm_version.startswith("npm:"):
        name, version = pnpm_version[4:].rsplit("@", 1)
    else:
        name = pnpm_name
        version = pnpm_version

    if version.startswith("@"):
        # Special case where the package name should _not_ be included in the package store name.
        # See https://github.com/aspect-build/rules_js/issues/423 for more context.
        return version.replace("/", "+")
    else:
        escaped_name = name.replace("/", "+")
        escaped_version = version.replace("://", "/").replace("/", "+")
        return "%s@%s" % (escaped_name, escaped_version)

def _make_symlink(ctx, symlink_path, target_path):
    if not bazel_lib_utils.is_bazel_6_or_greater():
        # ctx.actions.declare_symlink was added in Bazel 6
        fail("A minimum version of Bazel 6 required to use rules_js")
    symlink = ctx.actions.declare_symlink(symlink_path)
    ctx.actions.symlink(
        output = symlink,
        target_path = relative_file(target_path, symlink.path),
    )
    return symlink

def _parse_package_name(package):
    # Parse a @scope/name string and return a (scope, name) tuple
    segments = package.split("/", 1)
    if len(segments) == 2 and segments[0].startswith("@"):
        return (segments[0], segments[1])
    return ("", segments[0])

def _npm_registry_url(package, registries, default_registry):
    (package_scope, _) = _parse_package_name(package)

    return registries[package_scope] if package_scope in registries else default_registry

def _npm_registry_download_url(package, version, registries, default_registry):
    "Make a registry download URL for a given package and version"

    (_, package_name_no_scope) = _parse_package_name(package)
    registry = _npm_registry_url(package, registries, default_registry)

    return "{0}/{1}/-/{2}-{3}.tgz".format(
        registry.removesuffix("/"),
        package,
        package_name_no_scope,
        _strip_v5_peer_dep_or_patched_version(version),
    )

def _is_git_repository_url(url):
    return url.startswith("git+ssh://") or url.startswith("git+https://") or url.startswith("git@")

def _to_registry_url(url):
    return "{}://{}".format(DEFAULT_REGISTRY_PROTOCOL, url) if url.find("//") == -1 else url

def _default_registry_url():
    return _to_registry_url(DEFAULT_REGISTRY_DOMAIN_SLASH)

def _hash(s):
    # Bazel's hash() resolves to a 32-bit signed integer [-2,147,483,648 to 2,147,483,647].
    # NB: There has been discussion of adding a sha256 built-in hash function to Starlark but no
    # work has been done to date.
    # See https://github.com/bazelbuild/starlark/issues/36#issuecomment-1115352085.
    return str(hash(s))

def _dicts_match(a, b):
    if len(a) != len(b):
        return False
    for key in a.keys():
        if not key in b:
            return False
        if a[key] != b[key]:
            return False
    return True

# Copies a file from the external repository to the same relative location in the source tree
def _reverse_force_copy(rctx, label, dst = None):
    if type(label) != "Label":
        fail(INTERNAL_ERROR_MSG)
    dst = dst if dst else str(rctx.path(label))
    src = str(rctx.path(paths.join(label.package, label.name)))
    if repo_utils.is_windows(rctx):
        fail("Not yet implemented for Windows")
        #         rctx.file("_reverse_force_copy.bat", content = """
        # @REM needs a mkdir dirname(%2)
        # xcopy /Y %1 %2
        # """, executable = True)
        #         result = rctx.execute(["cmd.exe", "/C", "_reverse_force_copy.bat", src.replace("/", "\\"), dst.replace("/", "\\")])

    else:
        rctx.file("_reverse_force_copy.sh", content = """#!/usr/bin/env bash
set -o errexit -o nounset -o pipefail
mkdir -p $(dirname $2)
cp -f $1 $2
""", executable = True)
        result = rctx.execute(["./_reverse_force_copy.sh", src, dst])
    if result.return_code != 0:
        msg = """

ERROR: failed to copy file from {src} to {dst}:
STDOUT:
{stdout}
STDERR:
{stderr}
""".format(
            src = src,
            dst = dst,
            stdout = result.stdout,
            stderr = result.stderr,
        )
        fail(msg)

# This uses `rctx.execute` to check if the file exists since `rctx.exists` does not exist.
def _exists(rctx, p):
    if type(p) == "Label":
        fail("ERROR: dynamic labels not accepted since they should be converted paths at the top of the repository rule implementation to avoid restarts after rctx.execute() calls")
    p = str(p)
    if repo_utils.is_windows(rctx):
        fail("Not yet implemented for Windows")
        #         rctx.file("_exists.bat", content = """IF EXIST %1 (
        #     EXIT /b 0
        # ) ELSE (
        #     EXIT /b 42
        # )""", executable = True)
        #         result = rctx.execute(["cmd.exe", "/C", "_exists.bat", str(p).replace("/", "\\")])

    else:
        rctx.file("_exists.sh", content = """#!/usr/bin/env bash
set -o errexit -o nounset -o pipefail
if [ ! -f $1 ]; then exit 42; fi
""", executable = True)
        result = rctx.execute(["./_exists.sh", str(p)])
    if result.return_code == 0:  # file exists
        return True
    elif result.return_code == 42:  # file does not exist
        return False
    else:
        fail(INTERNAL_ERROR_MSG)

def _replace_npmrc_token_envvar(token, npmrc_path, environ):
    # A token can be a reference to an environment variable
    if token.startswith("$"):
        # ${NPM_TOKEN} -> NPM_TOKEN
        # $NPM_TOKEN -> NPM_TOKEN
        token = token.removeprefix("$").removeprefix("{").removesuffix("}")
        if token in environ.keys() and environ[token]:
            token = environ[token]
        else:
            # buildifier: disable=print
            print("""
WARNING: Issue while reading "{npmrc}". Failed to replace env in config: ${{{token}}}
""".format(
                npmrc = npmrc_path,
                token = token,
            ))
    return token

def _is_vendored_tarfile(package_snapshot):
    if "resolution" in package_snapshot:
        return "tarball" in package_snapshot["resolution"]
    return False

def _default_external_repository_action_cache():
    return DEFAULT_EXTERNAL_REPOSITORY_ACTION_CACHE

def _is_tarball_extension(ext):
    # Takes an extension (without leading dot) and return True if the extension
    # is a common tarball extension as per
    # https://en.wikipedia.org/wiki/Tar_(computing)#Suffixes_for_compressed_files
    tarball_extensions = [
        "tar",
        "tar.bz2",
        "tb2",
        "tbz",
        "tbz2",
        "tz2",
        "tar.gz",
        "taz",
        "tgz",
        "tar.lz",
        "tar.lzma",
        "tlz",
        "tar.lzo",
        "tar.xz",
        "txz",
        "tar.Z",
        "tZ",
        "taZ",
        "tar.zst",
        "tzst",
    ]
    return ext in tarball_extensions

utils = struct(
    bazel_name = _bazel_name,
    sorted_map = _sorted_map,
    pnpm_name = _pnpm_name,
    assert_lockfile_version = _assert_lockfile_version,
    parse_pnpm_lock_json = _parse_pnpm_lock_json,
    friendly_name = _friendly_name,
    package_store_name = _package_store_name,
    make_symlink = _make_symlink,
    # Symlinked node_modules structure package store path under node_modules
    package_store_root = ".aspect_rules_js",
    # Suffix for npm_import links repository
    links_repo_suffix = "__links",
    # Output group name for the package directory of a linked npm package
    package_directory_output_group = "package_directory",
    npm_registry_url = _npm_registry_url,
    npm_registry_download_url = _npm_registry_download_url,
    is_git_repository_url = _is_git_repository_url,
    to_registry_url = _to_registry_url,
    default_external_repository_action_cache = _default_external_repository_action_cache,
    default_registry = _default_registry_url,
    hash = _hash,
    dicts_match = _dicts_match,
    reverse_force_copy = _reverse_force_copy,
    exists = _exists,
    replace_npmrc_token_envvar = _replace_npmrc_token_envvar,
    is_tarball_extension = _is_tarball_extension,
)

# Exported only to be tested
utils_test = struct(
    parse_package_name = _parse_package_name,
    strip_v5_peer_dep_or_patched_version = _strip_v5_peer_dep_or_patched_version,
)
