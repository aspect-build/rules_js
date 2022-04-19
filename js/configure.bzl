"Macros for setting up rules_js"

load("@aspect_bazel_lib//lib:repositories.bzl", "register_yq_toolchains")
load("@rules_nodejs//nodejs:repositories.bzl", "nodejs_register_toolchains")
load("@aspect_rules_js//js/private/lifecycle:repositories.bzl", lifecycle_npm_repositories = "npm_repositories")

def js_configure(node_name = "node16", node_version = "16.9.0", yq_name = "yq", yq_version = "4.24.5"):
    """Register toolchains and set up dependencies for rules_js.

    Args:
        node_name: Name of the node toolchain repository
        node_version: Version of node to install
        yq_name: Name of the yq toolchain repository
        yq_version: Version of yq to install
    """
    js_register_toolchains(node_name = node_name, node_version = node_version, yq_name = yq_name, yq_version = yq_version)

    # Install deps for lifecycle hook execution
    lifecycle_npm_repositories()

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
