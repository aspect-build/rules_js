"Pnpm lockfile parsing and conversion to rules_js format."

load("@bazel_skylib//lib:paths.bzl", "paths")
load("@bazel_skylib//lib:types.bzl", "types")

# Metadata about a pnpm "project" (importer).
#
# Metadata may come from different locations depending on the lockfile.
# The data structure should be standardize the data structure across lockfiles.
#
# Args:
#   project: the lockfile-unique importer project path
#   dependencies:
#   dev_dependencies:
#   optional_dependencies:
def _new_import_info(project, dependencies, dev_dependencies, optional_dependencies):
    return {
        "project": project,
        "dependencies": dependencies,
        "dev_dependencies": dev_dependencies,
        "optional_dependencies": optional_dependencies,
    }

# Metadata about an npm package.
#
# Metadata may come from different locations depending on the lockfile.
# The data structure should be standardize the data structure across lockfiles.
#
# Args:
#   name:
#   version:
#
#   dev_only: True if the package is exclusively a dev dependency throughout the workspace
#       Removed in lockfile v9+
#       See https://github.com/pnpm/spec/blob/master/lockfile/6.0.md#packagesdependencypathdev
#
#   has_bin: True if the package has binaries
#       See https://github.com/pnpm/spec/blob/master/lockfile/9.0.md#packagesdependencyidhasbin
#
#   optional: True if the package is exclusively an optional dependency throughout the workspace
#       TODO(remove): removed in lockfile v9+
#       See https://github.com/pnpm/spec/blob/master/lockfile/6.0.md#packagesdependencypathoptional
#
#   requires_build: True if pnpm predicted the package requires a build step
#       TODO(remove): removed in lockfile v9+
#       See https://github.com/pnpm/spec/blob/master/lockfile/6.0.md#packagesdependencypathrequiresbuild
#
#   resolution: the lockfile resolution field
def _new_package_info(key, name, dev_only, has_bin, optional, requires_build, version, resolution):
    return {
        "key": key,
        "name": name,
        "dev_only": dev_only,
        "has_bin": has_bin,
        "optional": optional,
        "requires_build": requires_build,
        "version": version,
        "resolution": resolution,
    }

# Metadata about an instance/snapshot of a package with a specific set of dependencies.
#
#   key: a lockfile-unique identifier for the snapshot
def _new_snapshot_info(key, package_key, dependencies, optional_dependencies):
    return {
        "key": key,
        "package": package_key,
        "dependencies": dependencies,
        "optional_dependencies": optional_dependencies,
    }

######################### Lockfile v5.4 #########################

def _strip_v5_peer_dep_or_patched_version(version):
    "Remove peer dependency or patched syntax from version string"

    # 21.1.0_rollup@2.70.2 becomes 21.1.0
    # 1.0.0_o3deharooos255qt5xdujc3cuq becomes 1.0.0
    index = version.find("_")
    if index != -1:
        return version[:index]
    return version

def _v5_package_key_to_name_version(k):
    k = k.removeprefix("/")

    version_index = k.find("/")
    if version_index == -1:
        fail("Unknown package key {} in packages".format(k))

    if k.startswith("@"):
        version_index = k.find("/", version_index + 1)
        if version_index == -1:
            fail("Unknown package key {} in packages".format(k))

    name = k[:version_index]
    version = k[version_index + 1:]

    peer_versions_index = version.find("_")
    if peer_versions_index != -1:
        version = version[:peer_versions_index]

    return name, version

def _convert_v5_importer_dependency_map(importers, packages, import_path, specifiers, deps):
    result = {}
    for name, version in deps.items():
        o_name = name
        o_version = version

        specifier = specifiers.get(name)

        if specifier.startswith("npm:") and not specifier.startswith("npm:{}@".format(name)):
            if version in packages:
                result[name] = version
                continue

            name, version = version.rsplit("@", 1)

        if version.startswith("link:"):
            result[name] = "link:" + paths.normalize(paths.join(import_path, version[5:]))
            continue

        if version in importers or version in packages:
            result[name] = version
            continue

        name_version = name + "/" + version
        if name_version in packages:
            result[name] = name_version
            continue

        slash_name_version = "/" + name_version
        if slash_name_version in packages:
            result[name] = slash_name_version
            continue

        msg = "Import {}@{} from project '{}' not found in packages: {}".format(o_name, o_version, import_path, packages.keys())
        fail(msg)
    return result

def _convert_v5_importers(packages, importers):
    result = {}
    for import_path, importer in importers.items():
        specifiers = importer.get("specifiers", {})

        result[import_path] = _new_import_info(
            project = import_path,
            dependencies = _convert_v5_importer_dependency_map(importers, packages, import_path, specifiers, importer.get("dependencies", {})),
            dev_dependencies = _convert_v5_importer_dependency_map(importers, packages, import_path, specifiers, importer.get("devDependencies", {})),
            optional_dependencies = _convert_v5_importer_dependency_map(importers, packages, import_path, specifiers, importer.get("optionalDependencies", {})),
        )
    return result

def _v5_resolve_link_version(snapshot_key, package, name, version):
    package_key = package["id"] if "id" in package else snapshot_key

    # :link from file: may be relative to the workspace or to the package
    if package_key.startswith("file:"):
        # link: peerDependencies are already relative to the workspace, while
        # other link: deps are relative to the snapshot and must be normalized.
        # TODO: is it non-peer or is it (non?) workspace:* that is not workspace-relative?
        if not ("peerDependencies" in package and name in package["peerDependencies"]):
            version = "link:" + paths.normalize(paths.join(package_key[5:], version[5:]))
    return version

def _convert_pnpm_v5_package_dependency_version(packages, snapshot_key, package, name, version):
    if version.startswith("link:"):
        return _v5_resolve_link_version(snapshot_key, package, name, version)

    if version in packages:
        return version

    slash_name_version = "/" + name + "/" + version
    if slash_name_version in packages:
        return slash_name_version

    non_peered_version = _strip_v5_peer_dep_or_patched_version(version)
    if non_peered_version in packages:
        return non_peered_version

    slash_non_peered_version = "/" + non_peered_version
    if slash_non_peered_version in packages:
        return slash_non_peered_version

    fail("Unknown package {} ({}) not in packages {}".format(name, version, packages.keys()))

def _convert_pnpm_v5_package_dependency_map(packages, snapshot_key, package, deps):
    result = {}
    for name, version in deps.items():
        result[name] = _convert_pnpm_v5_package_dependency_version(packages, snapshot_key, package, name, version)
    return result

def _convert_v5_packages(lockfile_packages):
    packages = {}
    snapshots = {}
    for snapshot_key, package in lockfile_packages.items():
        # TODO: shouldn't this have peers/patches trimmed?
        package_key = snapshot_key

        if "name" in package and "version" in package:
            name = package["name"]
            version = package["version"]
        elif package_key.startswith("file:"):
            name = package["name"]
            version = package["version"] if "version" in package else "0.0.0"
        else:
            name, version = _v5_package_key_to_name_version(package_key)
            if "name" in package:
                name = package["name"]
            if "version" in package:
                version = package["version"]

        package_info = _new_package_info(
            key = package_key,
            name = name,
            version = version,
            dev_only = package.get("dev", False),
            has_bin = package.get("hasBin", False),
            optional = package.get("optional", False),
            requires_build = package.get("requiresBuild", False),
            resolution = package.get("resolution"),
        )

        if package_key in packages:
            msg = "ERROR: duplicate package: {}\n\t{}\n\t{}".format(package_key, packages[package_key], package_info)
            fail(msg)

        packages[package_key] = package_info

        snapshots[package_key] = _new_snapshot_info(
            key = package_key,
            package_key = package_key,
            dependencies = _convert_pnpm_v5_package_dependency_map(lockfile_packages, package_key, package, package.get("dependencies", {})),
            optional_dependencies = _convert_pnpm_v5_package_dependency_map(lockfile_packages, package_key, package, package.get("optionalDependencies", {})),
        )

    return packages, snapshots

def _convert_v5_lockfile(parsed):
    # Fallback to {".": parsed} for non-workspace lockfiles where the deps are at the root.
    lock_importers = parsed.get("importers", {".": parsed})
    lock_packages = parsed.get("packages", {})
    importers = _convert_v5_importers(lock_packages, lock_importers)
    packages, snapshots = _convert_v5_packages(lock_packages)
    return importers, packages, snapshots

######################### Lockfile v6 #########################

def _v6_package_key_to_name_version(k):
    k = k.removeprefix("/")
    version_index = k.find("@", 1)
    if version_index == -1:
        fail("Unknown package key {} in packages".format(k))
    name = k[:version_index]
    version = k[version_index + 1:]

    peer_versions_index = version.find("(")
    if peer_versions_index != -1:
        version = version[:peer_versions_index]

    return name, version

def _convert_pnpm_v6_importer_dependency_map(importers, packages, import_path, deps):
    result = {}
    for name, attributes in deps.items():
        specifier = attributes.get("specifier")
        version = attributes.get("version")

        o_name = name
        o_version = version

        # TODO: can drop this full 'if'?
        if specifier.startswith("npm:") and not specifier.startswith("npm:{}@".format(name)):
            if version in packages:
                result[name] = version
                continue
            name, version = version.rsplit("@", 1)

        if version.startswith("link:"):
            result[name] = "link:" + paths.normalize(paths.join(import_path, version[5:]))
            continue

        if version in importers or version in packages:
            result[name] = version
            continue

        name_version = name + "@" + version
        if name_version in packages:
            result[name] = name_version
            continue

        # no registry prefix
        slash_name_version = "/" + name_version
        if slash_name_version in packages:
            result[name] = slash_name_version
            continue

        msg = "Import {}@{} from project '{}' not found in packages: {}".format(o_name, o_version, import_path, packages.keys())
        fail(msg)
    return result

def _convert_v6_importers(packages, importers):
    result = {}
    for import_path, importer in importers.items():
        result[import_path] = _new_import_info(
            project = import_path,
            dependencies = _convert_pnpm_v6_importer_dependency_map(importers, packages, import_path, importer.get("dependencies", {})),
            dev_dependencies = _convert_pnpm_v6_importer_dependency_map(importers, packages, import_path, importer.get("devDependencies", {})),
            optional_dependencies = _convert_pnpm_v6_importer_dependency_map(importers, packages, import_path, importer.get("optionalDependencies", {})),
        )
    return result

def _strip_v6_peer_dep_or_patched_version(version):
    "Remove peer dependency or patched syntax from version string"

    # 21.1.0(rollup@2.70.2) becomes 21.1.0
    # 1.0.0(patch=...) 1.0.0
    index = version.find("(")
    if index != -1:
        return version[:index]
    return version

_v6_resolve_link_version = _v5_resolve_link_version

def _convert_pnpm_v6_package_dependency_version(packages, snapshot_key, package, name, version):
    if version.startswith("link:"):
        return _v6_resolve_link_version(snapshot_key, package, name, version)

    if version in packages:
        return version

    slash_name_version = "/" + name + "@" + version
    if slash_name_version in packages:
        return slash_name_version

    non_peered_version = _strip_v6_peer_dep_or_patched_version(version)
    if non_peered_version in packages:
        return non_peered_version

    slash_non_peered_version = "/" + non_peered_version
    if slash_non_peered_version in packages:
        return slash_non_peered_version

    fail("Unknown package {} ({}) not in packages {}".format(name, version, packages.keys()))

def _convert_pnpm_v6_package_dependency_map(packages, package_key, package, deps):
    result = {}
    for name, version in deps.items():
        result[name] = _convert_pnpm_v6_package_dependency_version(packages, package_key, package, name, version)
    return result

def _convert_v6_packages(packages):
    result = {}
    snapshots = {}
    for snapshot_key, package in packages.items():
        # TODO: shouldn't this have peers/patches trimmed?
        package_key = snapshot_key

        if "name" in package and "version" in package:
            name = package["name"]
            version = package["version"]
        elif package_key.startswith("file:"):
            name = package["name"]
            version = package["version"] if "version" in package else "0.0.0"
        else:
            name, version = _v6_package_key_to_name_version(package_key)
            if "name" in package:
                name = package["name"]
            if "version" in package:
                version = package["version"]

        result[package_key] = _new_package_info(
            key = package_key,
            name = name,
            version = version,
            dev_only = package.get("dev", False),
            has_bin = package.get("hasBin", False),
            optional = package.get("optional", False),
            requires_build = package.get("requiresBuild", False),
            resolution = package.get("resolution"),
        )

        snapshots[snapshot_key] = _new_snapshot_info(
            key = snapshot_key,
            package_key = package_key,
            dependencies = _convert_pnpm_v6_package_dependency_map(packages, package_key, package, package.get("dependencies", {})),
            optional_dependencies = _convert_pnpm_v6_package_dependency_map(packages, package_key, package, package.get("optionalDependencies", {})),
        )

    return result, snapshots

def _convert_v6_lockfile(parsed):
    # Fallback to {".": parsed} for non-workspace lockfiles where the deps are at the root.
    lock_importers = parsed.get("importers", {".": parsed})
    lock_packages = parsed.get("packages", {})
    importers = _convert_v6_importers(lock_packages, lock_importers)
    packages, snapshots = _convert_v6_packages(lock_packages)
    return importers, packages, snapshots

######################### Lockfile v9 #########################
def _v9_resolve_link_version(packages, snapshot_key, name, version):
    package_key = _strip_v9_peer_dep_or_patched_version(snapshot_key)
    package = packages[package_key]
    resolution = package.get("resolution")

    # :link from file: may be relative to the workspace or to the package
    if resolution.get("type", None) == "directory":
        # link: peerDependencies are already relative to the workspace, while
        # other link: deps are relative to the snapshot and must be normalized.
        # TODO: is it non-peer or is it (non?) workspace:* that is not workspace-relative?
        if not ("peerDependencies" in package and name in package["peerDependencies"]):
            version = "link:" + paths.normalize(paths.join(resolution.get("directory"), version[5:]))
    return version

def _convert_pnpm_v9_snapshot_dependency_version(packages, snapshots, snapshot_key, name, version):
    if version.startswith("link:"):
        return _v9_resolve_link_version(packages, snapshot_key, name, version)

    if version in snapshots or version in packages:
        return version

    name_version = name + "@" + version
    if name_version in packages or name_version in snapshots:
        return name_version

    fail("Unknown package {} ({}) not in\n\tpackages: {}\n\tsnapshots: {}".format(name, version, packages.keys(), snapshots.keys()))

def _convert_pnpm_v9_snapshot_dependency_map(packages, snapshots, snapshot_key, deps):
    result = {}
    for name, version in deps.items():
        result[name] = _convert_pnpm_v9_snapshot_dependency_version(packages, snapshots, snapshot_key, name, version)
    return result

def _convert_pnpm_v9_importer_dependency_map(packages, importers, snapshots, import_path, deps):
    result = {}
    for name, attributes in deps.items():
        version = attributes.get("version")

        if version.startswith("link:"):
            result[name] = "link:" + paths.normalize(paths.join(import_path, version[5:]))
            continue

        if version in importers or version in packages or version in snapshots:
            result[name] = version
            continue

        name_version = name + "@" + version
        if name_version in packages or name_version in snapshots:
            result[name] = name_version
            continue

        msg = "Import {} ({}) from project '{}' not found in\n\tpackages: {}\n\tsnapshots: {}".format(name, version, import_path, packages.keys(), snapshots.keys())
        fail(msg)
    return result

def _convert_v9_lockfile(parsed):
    lock_importers = parsed.get("importers", {})
    lock_packages = parsed.get("packages", {})
    lock_snapshots = parsed.get("snapshots", {})

    importers = _convert_v9_importers(lock_packages, lock_importers, lock_snapshots)
    packages = _convert_v9_packages(lock_packages)
    snapshots = _convert_v9_snapshots(lock_packages, lock_snapshots)
    return importers, packages, snapshots

def _convert_v9_importers(packages, importers, snapshots):
    result = {}
    for import_path, importer in importers.items():
        result[import_path] = _new_import_info(
            project = import_path,
            dependencies = _convert_pnpm_v9_importer_dependency_map(packages, importers, snapshots, import_path, importer.get("dependencies", {})),
            dev_dependencies = _convert_pnpm_v9_importer_dependency_map(packages, importers, snapshots, import_path, importer.get("devDependencies", {})),
            optional_dependencies = _convert_pnpm_v9_importer_dependency_map(packages, importers, snapshots, import_path, importer.get("optionalDependencies", {})),
        )
    return result

_v9_package_key_to_name_version = _v6_package_key_to_name_version

def _convert_v9_packages(packages):
    result = {}
    for package_key, package_snapshot in packages.items():
        # lockfile v9 package key is always of the format <name>@<version>:
        # - no 'name' property exists like <v9
        # - a 'version' property may exist if the package key <version> is not the resolved version number

        name, version = _v9_package_key_to_name_version(package_key)
        if "version" in package_snapshot:
            version = package_snapshot["version"]

        result[package_key] = _new_package_info(
            key = package_key,
            name = name,
            version = version,
            dev_only = None,  # NOTE: pnpm v9+ no longer marks packages as dev-only
            has_bin = package_snapshot.get("hasBin", False),
            optional = package_snapshot.get("optional", False),
            requires_build = None,  # Unknown from lockfile in v9
            resolution = package_snapshot.get("resolution"),
        )
    return result

_strip_v9_peer_dep_or_patched_version = _strip_v6_peer_dep_or_patched_version

def _convert_v9_snapshots(packages, snapshots):
    result = {}

    # Snapshots contains the packages with the keys (which include peers) to return
    for snapshot_key, package_snapshot in snapshots.items():
        package_key = _strip_v9_peer_dep_or_patched_version(snapshot_key)
        if package_key not in packages:
            msg = "snapshot {} (package {}) not found in pnpm 'packages': {}".format(snapshot_key, package_key, packages.keys())
            fail(msg)

        result[snapshot_key] = _new_snapshot_info(
            key = snapshot_key,
            package_key = package_key,
            dependencies = _convert_pnpm_v9_snapshot_dependency_map(packages, snapshots, snapshot_key, package_snapshot.get("dependencies", {})),
            optional_dependencies = _convert_pnpm_v9_snapshot_dependency_map(packages, snapshots, snapshot_key, package_snapshot.get("optionalDependencies", {})),
        )

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
        return {}, {}, {}, None, err

    if not types.is_dict(parsed):
        return {}, {}, {}, None, "lockfile should be a starlark dict"
    if not parsed.get("lockfileVersion", False):
        return {}, {}, {}, None, "expected lockfileVersion key in lockfile"

    # Lockfile version may be a float such as 5.4 or a string such as '6.0'
    lockfile_version = str(parsed["lockfileVersion"])
    lockfile_version = lockfile_version.lstrip("'")
    lockfile_version = lockfile_version.rstrip("'")
    lockfile_version = lockfile_version.lstrip("\"")
    lockfile_version = lockfile_version.rstrip("\"")
    lockfile_version = float(lockfile_version)
    _assert_lockfile_version(lockfile_version)

    lock_patched_dependencies = parsed.get("patchedDependencies", {})

    if lockfile_version < 6.0:
        importers, packages, snapshots = _convert_v5_lockfile(parsed)
    elif lockfile_version < 9.0:
        importers, packages, snapshots = _convert_v6_lockfile(parsed)
    else:  # >= 9
        importers, packages, snapshots = _convert_v9_lockfile(parsed)

    _validate_lockfile_data(lockfile_version, importers, packages, snapshots)

    return importers, packages, snapshots, lock_patched_dependencies, lockfile_version, None

def _validate_lockfile_data(lockfile_version, importers, packages, snapshots):
    for name, i in importers.items():
        if i["project"] != name:
            msg = "ERROR({}): importer '{}' does not match dict key '{}'".format(lockfile_version, i["project"], name)
            fail(msg)
        _validate_lockfile_importer_deps(lockfile_version, snapshots, name, i["dependencies"])
        _validate_lockfile_importer_deps(lockfile_version, snapshots, name, i["dev_dependencies"])
        _validate_lockfile_importer_deps(lockfile_version, snapshots, name, i["optional_dependencies"])

    for package_key, package in packages.items():
        if package["key"] != package_key:
            msg = "ERROR({}): package '{}' does not match dict key '{}'".format(lockfile_version, package["key"], package_key)
            fail(msg)

        if "resolution" not in package:
            msg = "package {} has no resolution field".format(package_key)
            fail(msg)

    for name, s in snapshots.items():
        if s["key"] != name:
            msg = "ERROR({}): snapshot '{}' does not match dict key '{}'".format(lockfile_version, s["key"], name)
            fail(msg)

        if s["package"] not in packages:
            msg = "ERROR({}): snapshot '{}' does not match package key '{}'".format(lockfile_version, s["key"], s["package"])
            fail(msg)

        _validate_lockfile_snapshot_deps(lockfile_version, packages, snapshots, s, s["dependencies"])
        _validate_lockfile_snapshot_deps(lockfile_version, packages, snapshots, s, s["optional_dependencies"])

def _validate_lockfile_snapshot_deps(lockfile_version, packages, snapshots, snapshot, deps):
    for dep in deps.values():
        if dep.startswith("link:"):
            continue

        if dep not in snapshots:
            msg = "ERROR({}): snapshot '{}' depends on '{}' which is not in\n\tsnapshots: {}\n\tpackages: {}".format(
                lockfile_version,
                snapshot["key"],
                dep,
                snapshots.keys(),
                packages.keys(),
            )
            fail(msg)

def _validate_lockfile_importer_deps(lockfile_version, snapshots, importer, deps):
    for dep in deps.values():
        if dep.startswith("link:"):
            continue

        if dep not in snapshots:
            msg = "ERROR({}): importer '{}' depends on snapshot '{}' which is not in snapshots: {}".format(
                lockfile_version,
                importer,
                dep,
                snapshots.keys(),
            )

            fail(msg)

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
    v5_strip_peer_dep_or_patched_version = _strip_v5_peer_dep_or_patched_version,
    v5_package_key_to_name_version = _v5_package_key_to_name_version,
    v6_package_key_to_name_version = _v6_package_key_to_name_version,
)
