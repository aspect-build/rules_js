"Utility functions for npm rules"

def _bazel_name(name, pnpm_version = None):
    "Make a bazel friendly name from a package name and (optionally) a version that can be used in repository and target names"
    escaped_name = name.replace("@", "at_").replace("/", "_")
    if not pnpm_version:
        return escaped_name
    pnpm_version_segments = pnpm_version.split("_")
    escaped_version = pnpm_version_segments[0].replace("/", "_")
    peer_version = "_".join(pnpm_version_segments[1:])
    if peer_version.startswith("@"):
        peer_version = "at_" + peer_version[1:]
    if peer_version:
        escaped_version = "%s__%s" % (escaped_version, peer_version.replace("/", "_").replace("@", "_").replace("+", "_"))
    return "%s__%s" % (escaped_name, escaped_version)

def _strip_peer_dep_version(version):
    "Remove peer dependency syntax from version string"

    # 21.1.0_rollup@2.70.2 becomes 21.1.0
    index = version.find("_")
    if index != -1:
        return version[:index]
    return version

def _pnpm_name(name, version):
    "Make a name/version pnpm-style name for a package name and version"
    return "%s/%s" % (name, version)

def _parse_pnpm_name(pnpmName):
    # Parse a name/version or @scope/name/version string and return
    # a [name, version] list
    segments = pnpmName.rsplit("/", 1)
    if len(segments) != 2:
        fail("unexpected pnpm versioned name " + pnpmName)
    return segments

def _assert_lockfile_version(version, testonly = False):
    if type(version) != type(1.0):
        fail("version should be passed as a float")

    # Restrict the supported lock file versions to what this code has been tested with:
    #   5.3 - pnpm v6.x.x
    #   5.4 - pnpm v7.0.0 bumped the lockfile version to 5.4
    min_lock_version = 5.3
    max_lock_version = 5.4
    msg = None

    if version < min_lock_version:
        msg = "translate_pnpm_lock requires lock_version at least {min}, but found {actual}. Please upgrade to pnpm v6 or greater.".format(
            min = min_lock_version,
            actual = version,
        )
    if version > max_lock_version:
        msg = "translate_pnpm_lock currently supports a maximum lock_version of {max}, but found {actual}. Please file an issue on rules_js".format(
            max = max_lock_version,
            actual = version,
        )
    if msg and not testonly:
        fail(msg)
    return msg

def _friendly_name(name, version):
    "Make a name@version developer-friendly name for a package name and version"
    return "%s@%s" % (name, version)

def _virtual_store_name(name, pnpm_version):
    "Make a virtual store name for a given package and version"
    escaped = name.replace("/", "+")
    return "%s@%s" % (escaped, pnpm_version)

pnpm_utils = struct(
    bazel_name = _bazel_name,
    pnpm_name = _pnpm_name,
    assert_lockfile_version = _assert_lockfile_version,
    parse_pnpm_name = _parse_pnpm_name,
    friendly_name = _friendly_name,
    virtual_store_name = _virtual_store_name,
    strip_peer_dep_version = _strip_peer_dep_version,
    # Prefix namespace to use for generated js_binary targets and aliases
    js_package_target_namespace = "jsp__",
    # Symlinked node_modules structure virtual store path under node_modules
    virtual_store_root = ".aspect_rules_js",
    # Postfix for npm_import links repository
    links_postfix = "__links",
    # Postfix for virtual store target
    store_postfix = "__store",
    # Postfix for package directory filegroup and alias targets
    dir_postfix = "__dir",
    # Output group name for the package directory of a linked package
    package_directory_output_group = "package_directory",
)
