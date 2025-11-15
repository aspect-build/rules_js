"Pnpm lockfile parsing and conversion to rules_js format."

load("@bazel_skylib//lib:paths.bzl", "paths")
load("@bazel_skylib//lib:types.bzl", "types")
load(":utils.bzl", "utils")

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
#
# Args:
#   name:
#   version:
#   dependencies:
#   optional_dependencies:
#   friendly_version:
#
#   has_bin: True if the package has binaries
#       See https://github.com/pnpm/spec/blob/master/lockfile/9.0.md#packagesdependencyidhasbin
#
#   optional: True if the package is exclusively an optional dependency throughout the workspace
#       See https://github.com/pnpm/spec/blob/master/lockfile/6.0.md#packagesdependencypathoptional
#
#   resolution: the lockfile resolution field
def _new_package_info(name, dependencies, optional_dependencies, has_bin, optional, version, friendly_version, resolution):
    return {
        "name": name,
        "dependencies": dependencies,
        "optional_dependencies": optional_dependencies,
        "has_bin": has_bin,
        "optional": optional,
        "version": version,
        "friendly_version": friendly_version,
        "resolution": resolution,
    }

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

######################### Lockfile v9 #########################

def _v9_snapshot_key_to_package_key(snapshot_key):
    peer_meta_index = snapshot_key.find("(")
    package_key = snapshot_key[:peer_meta_index] if peer_meta_index > 0 else snapshot_key
    return package_key

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

def _convert_pnpm_v9_package_dependency_version(packages, snapshots, snapshot_key, name, version):
    if version.startswith("link:"):
        # Resolve link: deps to be workspace root relative
        version = "link:" + _v9_resolve_link_version(packages, snapshot_key, name, version[5:])

    # Detect when an alias is just a direct reference to another snapshot
    is_alias = version in snapshots

    # Convert peer dependency data to rules_js ~v5 format
    version = _convert_pnpm_v6_v9_version_peer_dep(version)

    return "npm:{}".format(version) if is_alias else version

def _convert_pnpm_v9_package_dependency_map(packages, snapshots, snapshot_key, deps):
    result = {}
    for name, version in deps.items():
        result[name] = _convert_pnpm_v9_package_dependency_version(packages, snapshots, snapshot_key, name, version)
    return result

def _convert_pnpm_v9_importer_dependency_map(import_path, deps):
    result = {}
    for name, attributes in deps.items():
        specifier = attributes["specifier"]
        version = attributes["version"]

        # Transition version[(patch)(peer)(data)] to a rules_js version format
        version = _convert_pnpm_v6_v9_version_peer_dep(version)

        if specifier.startswith("npm:") and not specifier.startswith("npm:{}@".format(name)):
            # Keep the npm: specifier for aliased dependencies
            version = "npm:{}".format(version)
        elif version.startswith("link:"):
            # Convert link: to be relative to the workspace root instead of importer
            version = version[:5] + paths.normalize(paths.join(import_path, version[5:]))

        result[name] = version
    return result

def _convert_v9_importers(importers, no_dev, no_optional):
    # Convert pnpm lockfile v9 importers to a rules_js compatible ~v5 format.
    # Almost identical to v6 but with fewer odd edge cases.

    result = {}
    for import_path, importer in importers.items():
        result[import_path] = _new_import_info(
            dependencies = _convert_pnpm_v9_importer_dependency_map(import_path, importer.get("dependencies", {})),
            dev_dependencies = {} if no_dev else _convert_pnpm_v9_importer_dependency_map(import_path, importer.get("devDependencies", {})),
            optional_dependencies = {} if no_optional else _convert_pnpm_v9_importer_dependency_map(import_path, importer.get("optionalDependencies", {})),
        )
    return result

def _convert_v9_packages(packages, snapshots, no_optional):
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
    for snapshot_key, package_snapshot in snapshots.items():
        static_key = _v9_snapshot_key_to_package_key(snapshot_key)
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

        package_key = _convert_pnpm_v6_v9_version_peer_dep(snapshot_key)

        optional = package_snapshot.get("optional", False)
        if optional and no_optional:
            # when no_optional attribute is set, skip optionalDependencies
            continue

        # Extract the version including peerDeps+patch from the key
        version = _convert_pnpm_v6_v9_version_peer_dep(package_key[package_key.index("@", 1) + 1:])

        # package_data can have the resolved "version" for things like https:// deps
        friendly_version = package_data["version"] if "version" in package_data else static_key[version_index + 1:]

        package_info = _new_package_info(
            name = name,
            version = version,
            friendly_version = friendly_version,
            dependencies = _convert_pnpm_v9_package_dependency_map(packages, snapshots, snapshot_key, package_snapshot.get("dependencies", {})),
            optional_dependencies = {} if no_optional else _convert_pnpm_v9_package_dependency_map(packages, snapshots, snapshot_key, package_snapshot.get("optionalDependencies", {})),
            has_bin = package_data.get("hasBin", False),
            optional = optional,
            resolution = package_data["resolution"],
        )

        if package_key in result:
            msg = "ERROR: duplicate package: {}\n\t{}\n\t{}".format(package_key, result[package_key], package_info)
            fail(msg)

        result[package_key] = package_info

    return result

######################### Pnpm API #########################

def _parse_pnpm_lock_json(content, no_dev, no_optional):
    """Parse the content of a pnpm-lock.yaml file.

    Args:
        content: lockfile content as json
        no_dev: if True, devDependencies are not included
        no_optional: If true, optionalDependencies are not included

    Returns:
        A tuple of (importers dict, packages dict, patched_dependencies dict, error string)
    """
    return _parse_lockfile(json.decode(content) if content else None, no_dev, no_optional, None)

def _parse_lockfile(parsed, no_dev, no_optional, err):
    """Helper function used by _parse_pnpm_lock_json.

    Args:
        parsed: lockfile content object
        no_dev: if True, devDependencies are not included
        no_optional: If true, optionalDependencies are not included
        err: any errors from parsing

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

    # Fallback to {".": parsed} for non-workspace lockfiles where the deps are at the root.
    importers = parsed.get("importers", {".": parsed})
    packages = parsed.get("packages", {})
    patched_dependencies = parsed.get("patchedDependencies", {})

    snapshots = parsed.get("snapshots", {})
    importers = _convert_v9_importers(importers, no_dev, no_optional)
    packages = _convert_v9_packages(packages, snapshots, no_optional)

    importers = utils.sorted_map(importers)
    packages = utils.sorted_map(packages)

    _validate_lockfile_data(importers, packages)

    return importers, packages, patched_dependencies, None

def _validate_lockfile_data(importers, packages):
    for name, deps in importers.items():
        _validate_lockfile_deps(importers, packages, "importer", name, deps["dependencies"])
        _validate_lockfile_deps(importers, packages, "importer", name, deps["dev_dependencies"])
        _validate_lockfile_deps(importers, packages, "importer", name, deps["optional_dependencies"])

    for name, info in packages.items():
        _validate_lockfile_deps(importers, packages, "package", name, info["dependencies"])
        _validate_lockfile_deps(importers, packages, "package", name, info["optional_dependencies"])

def _validate_lockfile_deps(importers, packages, importer_type, importer, deps):
    for dep, version in deps.items():
        if version.startswith("npm:"):
            version = version[4:]

        if version.startswith("link:"):
            if version[5:] not in importers:
                msg = "ERROR: {} '{}' depends on package '{}' at link path '{}' which is not in the importers: {}".format(
                    importer_type,
                    importer,
                    dep,
                    version,
                    importers.keys(),
                )
                fail(msg)
        elif version not in packages and not ("{}@{}".format(dep, version) in packages):
            msg = "ERROR: {} '{}' depends on package '{}' at version '{}' which is not in the packages: {}".format(
                importer_type,
                importer,
                dep,
                version,
                packages.keys(),
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
