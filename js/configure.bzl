"Macros for setting up rules_js"

load("@aspect_bazel_lib//lib:repositories.bzl", "DEFAULT_YQ_VERSION", "register_yq_toolchains")
load("@rules_nodejs//nodejs:repositories.bzl", "DEFAULT_NODE_VERSION", "nodejs_register_toolchains")

def js_configure(node_name = "nodejs", node_version = DEFAULT_NODE_VERSION, yq_name = "yq", yq_version = DEFAULT_YQ_VERSION):
    """Register toolchains and set up dependencies for rules_js.

    Args:
        node_name: Name of the node toolchain repository
        node_version: Version of node to install
        yq_name: Name of the yq toolchain repository
        yq_version: Version of yq to install
    """
    js_register_toolchains(node_name = node_name, node_version = node_version, yq_name = yq_name, yq_version = yq_version)

def js_register_toolchains(node_name, node_version, yq_name, yq_version):
    """Register toolchains for rules_js.

    Args:
        node_name: Name of the node toolchain repository
        node_version: Version of node to install
        yq_name: Name of the yq toolchain repository
        yq_version: Version of yq to install
    """
    nodejs_register_toolchains(
        name = node_name,
        node_version = node_version,
    )
    register_yq_toolchains(
        name = yq_name,
        version = yq_version,
    )
