"Utility functions for npm rules"

def _bazel_name(name, version):
    "Make a bazel friendly name from a package name and a version that can be used in repository and target names"
    escaped = name.replace("/", "_").replace("@", "at_")
    version_escaped = _normalize_version(version)
    return "%s_%s" % (escaped, version_escaped)

def _normalize_version(version):
    "Make a bazel friendly version information"

    # 21.1.0_rollup@2.70.2            -> 21.1.0_rollup_2.70.2
    # 5.4.3_mobx@5.10.1+react@17.0.1  -> 5.4.3_mobx_5.10.1_plus_react_17.0.1
    return version.replace("@", "_").replace("+", "_plus_")

def _parse_dependency_string(dep):
    "Parse dependency string"

    # mobx-react-lite@3.3.0_mobx_6.5.0_plus_react_17.0.2
    #   -> mobx-react-lite, 3.3.0_mobx_6.5.0_plus_react_17.0.2
    #
    # @typescript-eslint/parser@4.13.0_eslint_7.12.1_plus_typescript_4.5.4
    #   -> @typescript-eslint/parser, 4.13.0_eslint_7.12.1_plus_typescript_4.5.4
    split = dep.rsplit("@", 1)
    return struct(
        name = split[0],
        version = split[1],
    )

def _strip_peer_dep_version(version):
    "Remove peer dependency syntax from version string"

    # 21.1.0_rollup@2.70.2 becomes 21.1.0
    index = version.find("_")
    if index != -1:
        return version[:index]
    return version

def _versioned_name(name, version):
    "Make a developer-friendly name for a package name and version"
    return "%s@%s" % (name, version)

def _virtual_store_name(name, version):
    "Make a virtual store name for a given package and version"
    escaped = name.replace("/", "+")
    return "%s@%s" % (escaped, version)

def _alias_target_name(name):
    "Make an alias target name for a given package"
    return name.replace("/", "+")

npm_utils = struct(
    bazel_name = _bazel_name,
    versioned_name = _versioned_name,
    virtual_store_name = _virtual_store_name,
    alias_target_name = _alias_target_name,
    strip_peer_dep_version = _strip_peer_dep_version,
    normalize_version = _normalize_version,
    parse_dependency_string = _parse_dependency_string,
    # Prefix namespace to use for generated js_binary targets and aliases
    node_package_target_namespace = "npm",
)
