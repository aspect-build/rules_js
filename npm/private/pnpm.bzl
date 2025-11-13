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
#   key:
#   version:
#
#   has_bin: True if the package has binaries
#       See https://github.com/pnpm/spec/blob/master/lockfile/9.0.md#packagesdependencyidhasbin
#
#   optional: True if the package is exclusively an optional dependency throughout the workspace
#       See https://github.com/pnpm/spec/blob/master/lockfile/6.0.md#packagesdependencypathoptional
#
#   resolution: the lockfile resolution field
def _new_package_info(key, name, has_bin, optional, version, friendly_version, resolution):
    return {
        "key": key,
        "name": name,
        "has_bin": has_bin,
        "optional": optional,
        "version": version,
        "friendly_version": friendly_version,
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

######################### Lockfile v9 #########################

def _v9_snapshot_key_to_package_key(snapshot_key):
    peer_meta_index = snapshot_key.find("(")
    package_key = snapshot_key[:peer_meta_index] if peer_meta_index > 0 else snapshot_key
    return package_key

def _v9_package_key_to_name_version(k):
    version_index = k.find("@", 1)
    if version_index == -1:
        fail("Unknown package key {} in packages".format(k))
    return k[:version_index], k[version_index + 1:]

def _v9_resolve_link_version(packages, snapshot_key, name, link):
    package_key = _v9_snapshot_key_to_package_key(snapshot_key)
    package = packages[package_key]
    resolution = package["resolution"]

    # :link dep from file:package will be relative to the file:package and not the workspace root
    if resolution.get("type", None) == "directory":
        # ... unless that link: dep is resolved from a peerDependency, then it is already resolved to workspace-relative
        if "peerDependencies" in package and name in package["peerDependencies"]:
            return link

        return paths.normalize(paths.join(resolution["directory"], link))

    # in the standard case snapshot link: deps are already relative to the workspace root
    return link

def _convert_pnpm_v9_snapshot_dependency_version(importers, packages, snapshots, snapshot_key, name, version):
    if version.startswith("link:"):
        # Resolve link: deps to be workspace root relative
        resolved_version = "link:" + _v9_resolve_link_version(packages, snapshot_key, name, version[5:])

        if resolved_version[5:] not in importers:
            msg = "Snapshot link dependency {} ({} resolved to {}) not found in importers: {}".format(name, version, resolved_version, importers.keys())
            fail(msg)
        return resolved_version

    if version in snapshots:
        return version

    name_version = name + "@" + version
    if name_version in snapshots:
        return name_version

    fail("Unknown package {} ({}) not in snapshots: {}".format(name, version, snapshots.keys()))

def _convert_pnpm_v9_snapshot_dependency_map(importers, packages, snapshots, snapshot_key, deps):
    result = {}
    for name, version in deps.items():
        result[name] = _convert_pnpm_v9_snapshot_dependency_version(importers, packages, snapshots, snapshot_key, name, version)
    return result

def _convert_pnpm_v9_importer_dependency_map(importers, snapshots, import_path, deps):
    result = {}
    for name, attributes in deps.items():
        version = attributes["version"]

        if version.startswith("link:"):
            workspace_rel_link = paths.normalize(paths.join(import_path, version[5:]))
            if workspace_rel_link not in importers:
                msg = "Import {} ({}) from project '{}' has invalid link path: {}".format(name, version, import_path, workspace_rel_link)
                fail(msg)

            result[name] = "link:" + workspace_rel_link
            continue

        if version in snapshots:
            result[name] = version
            continue

        name_version = name + "@" + version
        if name_version in snapshots:
            result[name] = name_version
            continue

        msg = "Import {} ({}) from project '{}' not found in snapshots: {}".format(name, version, import_path, snapshots.keys())
        fail(msg)
    return result

def _convert_v9_lockfile(parsed):
    lock_importers = parsed.get("importers", {})
    lock_packages = parsed.get("packages", {})
    lock_snapshots = parsed.get("snapshots", {})

    packages = _convert_v9_packages(lock_packages)
    snapshots = _convert_v9_snapshots(lock_importers, lock_packages, lock_snapshots)
    importers = _convert_v9_importers(lock_snapshots, lock_importers)
    return importers, packages, snapshots

def _convert_v9_importers(snapshots, importers):
    result = {}
    for import_path, importer in importers.items():
        result[import_path] = _new_import_info(
            project = import_path,
            dependencies = _convert_pnpm_v9_importer_dependency_map(importers, snapshots, import_path, importer.get("dependencies", {})),
            dev_dependencies = _convert_pnpm_v9_importer_dependency_map(importers, snapshots, import_path, importer.get("devDependencies", {})),
            optional_dependencies = _convert_pnpm_v9_importer_dependency_map(importers, snapshots, import_path, importer.get("optionalDependencies", {})),
        )
    return result

def _convert_v9_packages(packages):
    # Convert pnpm lockfile v9 importers to a rules_js compatible format.
    #
    # Example:
    #
    #  packages:
    #    '@scoped/name@5.0.2'
    #       hasBin
    #       resolution (registry-url, integrity etc)
    #       peerDependencies which *might* be resolved

    result = {}
    for package_key, package_info in packages.items():
        # lockfile v9 package key is always of the format <name>@<version>:
        # - no 'name' property exists like <v9
        # - a 'version' property may exist if the package key <version> is not the resolved version number

        name, version = _v9_package_key_to_name_version(package_key)

        result[package_key] = _new_package_info(
            key = package_key,
            name = name,
            version = version,
            friendly_version = package_info.get("version", version),
            has_bin = package_info.get("hasBin", False),
            optional = package_info.get("optional", False),
            resolution = package_info.get("resolution"),
        )
    return result

def _convert_v9_snapshots(importers, packages, snapshots):
    # Convert pnpm lockfile v9 snapshots to a rules_js compatible format.
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
    for snapshot_key, package_snapshot in snapshots.items():
        package_key = _v9_snapshot_key_to_package_key(snapshot_key)
        if package_key not in packages:
            msg = "snapshot {} (package {}) not found in pnpm 'packages': {}".format(snapshot_key, package_key, packages.keys())
            fail(msg)

        result[snapshot_key] = _new_snapshot_info(
            key = snapshot_key,
            package_key = package_key,
            dependencies = _convert_pnpm_v9_snapshot_dependency_map(importers, packages, snapshots, snapshot_key, package_snapshot.get("dependencies", {})),
            optional_dependencies = _convert_pnpm_v9_snapshot_dependency_map(importers, packages, snapshots, snapshot_key, package_snapshot.get("optionalDependencies", {})),
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
        return {}, {}, {}, err

    if not types.is_dict(parsed):
        return {}, {}, {}, "lockfile should be a starlark dict"
    if not parsed.get("lockfileVersion", False):
        return {}, {}, {}, "expected lockfileVersion key in lockfile"

    # Lockfile version may be a float such as 5.4 or a string such as '6.0'
    lockfile_version = str(parsed["lockfileVersion"])
    lockfile_version = lockfile_version.lstrip("'")
    lockfile_version = lockfile_version.rstrip("'")
    lockfile_version = lockfile_version.lstrip("\"")
    lockfile_version = lockfile_version.rstrip("\"")
    lockfile_version = float(lockfile_version)
    _assert_lockfile_version(lockfile_version)

    lock_patched_dependencies = parsed.get("patchedDependencies", {})

    importers, packages, snapshots = _convert_v9_lockfile(parsed)

    _validate_lockfile_data(lockfile_version, importers, packages, snapshots)

    return importers, packages, snapshots, lock_patched_dependencies, None

def _validate_lockfile_data(lockfile_version, importers, packages, snapshots):
    for name, i in importers.items():
        if i["project"] != name:
            msg = "ERROR({}): importer '{}' does not match dict key '{}'".format(lockfile_version, i["project"], name)
            fail(msg)
        _validate_lockfile_deps(lockfile_version, "snapshot", name, snapshots, importers, i["dependencies"])
        _validate_lockfile_deps(lockfile_version, "snapshot", name, snapshots, importers, i["dev_dependencies"])
        _validate_lockfile_deps(lockfile_version, "snapshot", name, snapshots, importers, i["optional_dependencies"])

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

        _validate_lockfile_deps(lockfile_version, "importer", s, snapshots, importers, s["dependencies"])
        _validate_lockfile_deps(lockfile_version, "importer", s, snapshots, importers, s["optional_dependencies"])

def _validate_lockfile_deps(lockfile_version, term, who, snapshots, importers, deps):
    for dep in deps.values():
        if dep.startswith("link:"):
            if dep[5:] not in importers:
                msg = "ERROR({}): {} '{}' has link dependency '{}' which is not in importers: {}".format(
                    lockfile_version,
                    term,
                    who,
                    dep,
                    importers.keys(),
                )

                fail(msg)
        elif dep not in snapshots:
            msg = "ERROR({}): } '{}' depends on snapshot '{}' which is not in snapshots: {}".format(
                lockfile_version,
                term,
                who,
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
    min_lock_version = 9.0
    max_lock_version = 9.0
    msg = None

    if version < min_lock_version:
        msg = "npm_translate_lock requires lock_version at least {min}, but found {actual}. Please upgrade to pnpm v9 or greater.".format(
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
