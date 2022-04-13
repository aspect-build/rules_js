"Utility functions for npm rules"

def _bazel_name(name, version):
    "Make a bazel friendly name from a package name and a version that can be used in repository and target names"
    escaped = name.replace("/", "_").replace("@", "at_")
    return "%s_%s" % (escaped, version)

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
    # Prefix namespace to use for generated js_binary targets and aliases
    js_package_target_namespace = "npm",
)
