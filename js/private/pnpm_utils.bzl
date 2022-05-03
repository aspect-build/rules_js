"Utility functions for npm rules"

def _bazel_name(name, pnpm_version = None):
    "Make a bazel friendly name from a package name and (optionally) a version that can be used in repository and target names"
    escaped_name = name.replace("@", "at_").replace("/", "_")
    if not pnpm_version:
        return escaped_name
    pnpm_version_segments = pnpm_version.split("_")
    escaped_version = pnpm_version_segments[0]
    peer_version = "_".join(pnpm_version_segments[1:])
    if peer_version.startswith("@"):
        peer_version = "at_" + peer_version[1:]
    if peer_version:
        escaped_version = "%s__%s" % (escaped_version, peer_version.replace("/", "_").replace("@", "_").replace("+", "_"))
    return "%s_%s" % (escaped_name, escaped_version)

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
    friendly_name = _friendly_name,
    virtual_store_name = _virtual_store_name,
    strip_peer_dep_version = _strip_peer_dep_version,
    # Prefix namespace to use for generated js_binary targets and aliases
    js_package_target_namespace = "jsp__",
    # Symlinked node_modules structure virtual store path under node_modules
    virtual_store_root = ".aspect_rules_js",
)
