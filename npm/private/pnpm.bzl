"Pnpm lockfile parsing and conversion to rules_js format."

load("@bazel_skylib//lib:types.bzl", "types")
load(":utils.bzl", "DEFAULT_REGISTRY_DOMAIN_SLASH", "utils")

def _is_vendored_tarfile(package_snapshot):
    if "resolution" in package_snapshot:
        return "tarball" in package_snapshot["resolution"] and package_snapshot["resolution"]["tarball"].startswith("file:")
    return False

def _to_package_key(name, version):
    if not version[0].isdigit():
        return version
    return "{}@{}".format(name, version)

def _split_name_at_version(name_version):
    at = name_version.find("@", 1)
    return name_version[:at], name_version[at + 1:]

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
def _new_package_info(id, name, dependencies, optional_dependencies, dev, has_bin, optional, requires_build, version, friendly_version, resolution):
    return {
        "id": id,
        "name": name,
        "dependencies": dependencies,
        "optional_dependencies": optional_dependencies,
        "dev": dev,
        "has_bin": has_bin,
        "optional": optional,
        "requires_build": requires_build,
        "version": version,
        "friendly_version": friendly_version,
        "resolution": resolution,
    }

######################### Lockfile v5.4 #########################

def _strip_v5_v6_default_registry(name_version):
    # Strip the default registry from the name_version string
    return name_version.removeprefix(DEFAULT_REGISTRY_DOMAIN_SLASH)

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

def _strip_v5_peer_dep_or_patched_version(version):
    "Remove peer dependency or patched syntax from version string"

    # 21.1.0_rollup@2.70.2 becomes 21.1.0
    # 1.0.0_o3deharooos255qt5xdujc3cuq becomes 1.0.0
    index = version.find("_")
    if index != -1:
        return version[:index]
    return version

def _strip_v5_default_registry_to_version(name, version):
    # Quick-exit if the version string does not start with the default registry
    if not version.startswith(DEFAULT_REGISTRY_DOMAIN_SLASH):
        return version

    # Strip the default registry/name@ from the version string
    return version.removeprefix(DEFAULT_REGISTRY_DOMAIN_SLASH + name + "/")

def _convert_v5_importer_dependency_map(specifiers, deps):
    result = {}
    for name, version in deps.items():
        specifier = specifiers.get(name)

        if specifier.startswith("npm:") and not specifier.startswith("npm:{}@".format(name)):
            # Keep the npm: specifier for aliased dependencies
            # convert v5 style aliases ([default_registry]/aliased/version) to npm:aliased@version
            alias, version = _strip_v5_v6_default_registry(version).lstrip("/").rsplit("/", 1)
            version = _convert_pnpm_v5_version_peer_dep(version)
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
    # Convert a pnpm lock file v5 dependency version string to a format
    # compatible with rules_js.
    #
    # Example versions:
    #  1.2.3
    #  1.2.3_@scope+peer@2.0.2_@scope+peer@4.5.6
    #  2.0.0_@aspect-test+c@2.0.2
    #  3.1.0_rollup@2.14.0
    #  4.5.6_o3deharooos255qt5xdujc3cuq

    # If there is a suffix to the version
    peer_dep_index = version.find("_")
    if peer_dep_index != -1:
        # if the suffix contains an @version (not just a _patchhash)
        peer_dep_at_index = version.find("@", peer_dep_index)
        if peer_dep_at_index != -1:
            peer_dep = version[peer_dep_index:]
            peer_dep = peer_dep.replace("_@", "_at_").replace("@", "_").replace("/", "_").replace("+", "_")

            version = version[0:peer_dep_index] + peer_dep

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

######################### Lockfile v6 #########################

def _convert_pnpm_v6_v9_version_peer_dep(version):
    # Convert a pnpm lock file v6-9+ version string to a format compatible
    # with rules_js.
    #
    # Examples:
    #   1.2.3
    #   1.2.3(@scope/peer@2.0.2)(@scope/peer@4.5.6)
    #   4.5.6(patch_hash=o3deharooos255qt5xdujc3cuq)
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
            peer_dep = utils.hash(peer_dep)
        else:
            peer_dep = peer_dep.replace("(@", "(_at_").replace(")(", "_").replace("@", "_").replace("/", "_")
        version = version[0:peer_dep_index] + "_" + peer_dep.strip("_-()")
    return version

def _strip_v6_default_registry_to_version(name, version):
    # Quick-exit if the version string does not start with the default registry
    if not version.startswith(DEFAULT_REGISTRY_DOMAIN_SLASH):
        return version

    # Strip the default registry/name@ from the version string
    return version.removeprefix(DEFAULT_REGISTRY_DOMAIN_SLASH + name + "@")

def _convert_pnpm_v6_importer_dependency_map(deps):
    result = {}
    for name, attributes in deps.items():
        specifier = attributes.get("specifier")
        version = attributes.get("version")

        if specifier.startswith("npm:") and not specifier.startswith("npm:{}@".format(name)):
            # Keep the npm: specifier for aliased dependencies
            # convert v6 style aliases ([registry]/aliased@version) to npm:aliased@version
            alias, version = _split_name_at_version(_strip_v5_v6_default_registry(version).lstrip("/"))
            version = _convert_pnpm_v6_v9_version_peer_dep(version)
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
        # Convert peer dependency data to rules_js ~v5 format
        version = _convert_pnpm_v6_v9_version_peer_dep(version[1:])

        return "npm:{}".format(version)

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

######################### Lockfile v9 #########################

def _convert_pnpm_v9_package_dependency_version(snapshots, name, version):
    # Detect when an alias is just a direct reference to another snapshot
    is_alias = version in snapshots

    # Convert peer dependency data to rules_js ~v5 format
    version = _convert_pnpm_v6_v9_version_peer_dep(version)

    return "npm:{}".format(version) if is_alias else version

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

        # Transition version[(patch)(peer)(data)] to a rules_js version format
        version = _convert_pnpm_v6_v9_version_peer_dep(version)

        if specifier.startswith("npm:") and not specifier.startswith("npm:{}@".format(name)):
            # Keep the npm: specifier for aliased dependencies
            version = "npm:{}".format(version)

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
    for package_path, package_snapshot in snapshots.items():
        peer_meta_index = package_path.find("(")
        static_key = package_path[:peer_meta_index] if peer_meta_index > 0 else package_path
        if not static_key in packages:
            msg = "package {} not found in pnpm 'packages'".format(static_key)
            fail(msg)

        package_data = packages[static_key]

        if "resolution" not in package_data:
            msg = "package {} has no resolution field".format(static_key)
            fail(msg)

        package_key = _convert_pnpm_v6_v9_version_peer_dep(package_path)

        # the raw name + version are the static_key, not including peerDeps+patch
        version_index = static_key.index("@", 1)
        name = static_key[:version_index]

        # Extract the version including peerDeps+patch from the package_key
        version = package_key[package_key.index("@", 1) + 1:]

        # package_data can have the resolved "version" for things like https:// deps
        friendly_version = package_data["version"] if "version" in package_data else static_key[version_index + 1:]

        # direct reference to tarball files: use the friendly_version to align with pnpm <v9 which
        # uses the resolved version in the package store.
        if _is_vendored_tarfile(package_data):
            version = friendly_version

        package_info = _new_package_info(
            id = package_data.get("id", None),  # TODO: does v9 have "id"?
            name = name,
            version = version,
            friendly_version = friendly_version,
            dependencies = _convert_pnpm_v9_package_dependency_map(snapshots, package_snapshot.get("dependencies", {})),
            optional_dependencies = _convert_pnpm_v9_package_dependency_map(snapshots, package_snapshot.get("optionalDependencies", {})),
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

######################### Pnpm API #########################

def _parse_pnpm_lock_json(content):
    """Parse the content of a pnpm-lock.yaml file.

    Args:
        content: lockfile content as json

    Returns:
        A tuple of (importers dict, packages dict, patched_dependencies dict, error string)
    """
    return _parse_lockfile(json.decode(content) if content else None, None)

def _parse_lockfile(parsed, err):
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

    importers = utils.sorted_map(importers)
    packages = utils.sorted_map(packages)

    _validate_lockfile_data(importers, packages)

    return importers, packages, patched_dependencies, lockfile_version, None

def _validate_lockfile_data(importers, packages):
    for name, deps in importers.items():
        _validate_lockfile_deps(packages, "importer", name, deps["dependencies"])
        _validate_lockfile_deps(packages, "importer", name, deps["dev_dependencies"])
        _validate_lockfile_deps(packages, "importer", name, deps["optional_dependencies"])

    for name, info in packages.items():
        _validate_lockfile_deps(packages, "package", name, info["dependencies"])
        _validate_lockfile_deps(packages, "package", name, info["optional_dependencies"])

def _validate_lockfile_deps(packages, importer_type, importer, deps):
    for dep, version in deps.items():
        if version.startswith("npm:"):
            version = version[4:]

        if version not in packages and not (version.startswith("file:") or version.startswith("link:")) and not ("{}@{}".format(dep, version) in packages):
            msg = "ERROR: {} '{}' depends on package '{}' at version '{}' which is not in the packages: {}".format(
                importer_type,
                importer,
                dep,
                version,
                packages.keys(),
            )

            # TODO: fail instead of print
            # buildifier: disable=print
            print(msg)

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

pnpm = struct(
    assert_lockfile_version = _assert_lockfile_version,
    parse_pnpm_lock_json = _parse_pnpm_lock_json,
)

# Exported only to be tested
pnpm_test = struct(
    strip_v5_peer_dep_or_patched_version = _strip_v5_peer_dep_or_patched_version,
)
