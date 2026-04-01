"Pnpm lockfile parsing and conversion to rules_js format."

load("@bazel_skylib//lib:paths.bzl", "paths")
load("@bazel_skylib//lib:types.bzl", "types")
load("//platforms/pnpm:index.bzl", "PNPM_ARCHS", "PNPM_ARCH_ALIASES", "PNPM_PLATFORMS")
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
#   cpu: list of allowed cpu architectures or None
#   os: list of allowed operating systems or None

def _new_package_info(name, dependencies, optional_dependencies, has_bin, optional, version, friendly_version, resolution, cpu, os):
    return {
        "name": name,
        "dependencies": dependencies,
        "optional_dependencies": optional_dependencies,
        "has_bin": has_bin,
        "optional": optional,
        "version": version,
        "friendly_version": friendly_version,
        "resolution": resolution,
        "cpu": cpu,
        "os": os,
    }

def _to_bazel_os_cpu_constraints(oss, cpus):
    oss = _resolve_pnpm_constraint_values(oss, PNPM_PLATFORMS, {}, "os")
    cpus = _resolve_pnpm_constraint_values(cpus, PNPM_ARCHS, PNPM_ARCH_ALIASES, "cpu")
    r = []
    for cpu in cpus:
        for os in oss:
            r.append("@aspect_rules_js//platforms/pnpm:{}_{}".format(os, cpu))
    return r

def _to_bazel_os_constraints(oss):
    oss = _resolve_pnpm_constraint_values(oss, PNPM_PLATFORMS, {}, "os")
    return ["@aspect_rules_js//platforms/pnpm:{}".format(os) for os in oss]

def _to_bazel_cpu_constraints(cpus):
    cpus = _resolve_pnpm_constraint_values(cpus, PNPM_ARCHS, PNPM_ARCH_ALIASES, "cpu")
    return ["@aspect_rules_js//platforms/pnpm:{}".format(cpu) for cpu in cpus]

def _resolve_pnpm_constraint_values(values, known_map, aliases_map, kind):
    if not values:
        return []

    is_negated = values[0].startswith("!")

    normalized = {}
    for value in values:
        key = value[1:] if is_negated else value

        # Validate all values are either negated or not negated
        if value.startswith("!") != is_negated:
            fail("Unsupported mixing {} negations: {}".format(kind, values))

        # Validate the key is known
        if key not in known_map and key not in aliases_map:
            fail("Unknown pnpm {}: {}".format(kind, value))

        # Convert aliases to the aliased
        if key in aliases_map:
            key = aliases_map[key]
        if key:
            normalized[key] = True

    if is_negated:
        return [x for x in known_map.keys() if x not in normalized and known_map[x]]
    return [x for x in normalized.keys() if known_map[x]]

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
        return utils.importer_to_link(name, _v9_resolve_link_version(packages, snapshot_key, name, version[5:]))

    if version in snapshots:
        return version

    name_version = name + "@" + version
    if name_version in snapshots:
        return name_version

    fail("Unknown package {} ({}) not in snapshots: {}".format(name, version, snapshots.keys()))

def _convert_pnpm_v9_package_dependency_map(packages, snapshots, snapshot_key, deps):
    result = {}
    for name, version in deps.items():
        result[name] = _convert_pnpm_v9_package_dependency_version(packages, snapshots, snapshot_key, name, version)
    return result

def _convert_pnpm_v9_importer_dependency_map(snapshots, import_path, deps):
    result = {}
    for name, attributes in deps.items():
        version = attributes["version"]

        if version.startswith("link:"):
            workspace_rel_link = paths.normalize(paths.join(import_path, version[5:]))
            result[name] = utils.importer_to_link(name, workspace_rel_link)
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

def _convert_v9_importers(importers, snapshots, no_dev, no_optional):
    # Convert pnpm lockfile v9 importers to the rules_js structure.

    result = {}
    for import_path, importer in importers.items():
        result[import_path] = _new_import_info(
            dependencies = _convert_pnpm_v9_importer_dependency_map(snapshots, import_path, importer.get("dependencies", {})),
            dev_dependencies = {} if no_dev else _convert_pnpm_v9_importer_dependency_map(snapshots, import_path, importer.get("devDependencies", {})),
            optional_dependencies = {} if no_optional else _convert_pnpm_v9_importer_dependency_map(snapshots, import_path, importer.get("optionalDependencies", {})),
        )
    return result

def _convert_v9_packages(packages, snapshots, no_optional):
    # Convert pnpm lockfile v9 importers to the rules_js structure.

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

        optional = package_snapshot.get("optional", False)
        if optional and no_optional:
            # when no_optional attribute is set, skip optionalDependencies
            continue

        # Extract the version including peerDeps+patch from the key
        version = snapshot_key[snapshot_key.index("@", 1) + 1:]

        # package_data can have the resolved "version" for things like https:// deps
        friendly_version = package_data["version"] if "version" in package_data else static_key[version_index + 1:]

        result[snapshot_key] = _new_package_info(
            name = name,
            version = version,
            friendly_version = friendly_version,
            dependencies = _convert_pnpm_v9_package_dependency_map(packages, snapshots, snapshot_key, package_snapshot.get("dependencies", {})),
            optional_dependencies = {} if no_optional else _convert_pnpm_v9_package_dependency_map(packages, snapshots, snapshot_key, package_snapshot.get("optionalDependencies", {})),
            has_bin = package_data.get("hasBin", False),
            optional = optional,
            resolution = package_data["resolution"],
            cpu = package_data.get("cpu", None),
            os = package_data.get("os", None),
        )

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
    importers = _convert_v9_importers(importers, snapshots, no_dev, no_optional)
    packages = _convert_v9_packages(packages, snapshots, no_optional)

    _validate_lockfile_data(importers, packages)

    return importers, packages, patched_dependencies, None

def _validate_lockfile_data(importers, packages):
    for importer_path, importer in importers.items():
        _validate_lockfile_deps(packages, "importer", importer_path, importer["dependencies"])
        _validate_lockfile_deps(packages, "importer", importer_path, importer["dev_dependencies"])
        _validate_lockfile_deps(packages, "importer", importer_path, importer["optional_dependencies"])

    for package_key, info in packages.items():
        _validate_lockfile_deps(packages, "package", package_key, info["dependencies"])
        _validate_lockfile_deps(packages, "package", package_key, info["optional_dependencies"])

def _validate_lockfile_deps(packages, importer_type, importer, deps):
    for dep_name, dep_key in deps.items():
        # can link: to anything
        if dep_key.startswith("link:"):
            continue

        # otherwise the dep must be a known package
        if dep_key not in packages:
            msg = "ERROR: {} '{}' depends on package '{}' at version '{}' which is not in the packages: {}".format(
                importer_type,
                importer,
                dep_name,
                dep_key,
                packages.keys(),
            )
            fail(msg)

def _assert_lockfile_version(version, testonly = False):
    if type(version) != type(1.0):
        fail("version should be passed as a float")

    # Restrict the supported lock file versions to what this code has been tested with.
    # pnpm v9.0.0 bumped the lockfile version to 9.0
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

def _parse_pnpm_workspace_json(content):
    """Parse the content of a pnpm-workspace.yaml file.

    Args:
        content: pnpm-workspace.yaml file content as json

    Returns:
        A tuple of (packages list, error string)
    """
    if not content:
        return {}, None

    parsed = json.decode(content)
    if not parsed:
        return {}, None

    if not types.is_dict(parsed):
        return None, "pnpm-workspace should be a starlark dict"

    return parsed, None

pnpm = struct(
    assert_lockfile_version = _assert_lockfile_version,
    parse_pnpm_lock_json = _parse_pnpm_lock_json,
    parse_pnpm_workspace_json = _parse_pnpm_workspace_json,
    to_bazel_os_cpu_constraints = _to_bazel_os_cpu_constraints,
    to_bazel_os_constraints = _to_bazel_os_constraints,
    to_bazel_cpu_constraints = _to_bazel_cpu_constraints,
)
