"""Configures transitive deps and registers toolchains required by rules_js.
"""

load(
    "@aspect_bazel_lib//lib:repositories.bzl",
    _register_copy_directory_toolchains = "register_copy_directory_toolchains",
    _register_copy_to_directory_toolchains = "register_copy_to_directory_toolchains",
    _register_coreutils_toolchains = "register_coreutils_toolchains",
    _register_jq_toolchains = "register_jq_toolchains",
    _register_tar_toolchains = "register_tar_toolchains",
    _register_yq_toolchains = "register_yq_toolchains",
)
load("@rules_nodejs//nodejs:repositories.bzl", "nodejs_register_toolchains", _DEFAULT_NODE_REPOSITORY = "DEFAULT_NODE_REPOSITORY", _DEFAULT_NODE_VERSION = "DEFAULT_NODE_VERSION")

DEFAULT_NODE_REPOSITORY = _DEFAULT_NODE_REPOSITORY
DEFAULT_NODE_VERSION = _DEFAULT_NODE_VERSION

def rules_js_register_toolchains(
        node_download_auth = {},
        node_repositories = {},
        node_urls = None,
        node_version = DEFAULT_NODE_VERSION,
        node_version_from_nvmrc = None,
        **kwargs):
    """Configures transitive deps and toolchains required by rules_js.

    Node.js toolchain comes from [rules_nodejs](https://docs.aspect.build/rulesets/rules_nodejs).
    For more details on Node.js toolchain registration see
    https://docs.aspect.build/rulesets/rules_nodejs/docs/core#node_repositories.

    Additional required toolchains (jq, yq, copy_directory and copy_to_directory) come
    from [Aspect bazel-lib](https://docs.aspect.build/rulesets/aspect_bazel_lib).

    Args:
        node_download_auth: Auth to use for all url requests when downloading Node

            Example: {"type": "basic", "login": "<UserName>", "password": "<Password>" }

        node_repositories: Custom list of node repositories to use

            A dictionary mapping NodeJS versions to sets of hosts and their corresponding (filename, strip_prefix, sha256) tuples.
            You should list a node binary for every platform users have, likely Mac, Windows, and Linux.

            By default, if this attribute has no items, we'll use a list of all public NodeJS releases.

        node_urls: Custom list of URLs to use to download NodeJS

            Each entry is a template for downloading a node distribution.

            The `{version}` parameter is substituted with the `node_version` attribute,
            and `{filename}` with the matching entry from the `node_repositories` attribute.

        node_version: The specific version of NodeJS to install

        node_version_from_nvmrc: The label of the .nvmrc file containing the version of node

            If set then the version is set to the version found in the .nvmrc file.

            Requires a minimum rules_nodejs version of 6.1.0.

        **kwargs: Other args
    """
    if kwargs.pop("register_copy_directory_toolchain", True) and not native.existing_rule("copy_directory_toolchains"):
        _register_copy_directory_toolchains()
    if kwargs.pop("register_copy_to_directory_toolchain", True) and not native.existing_rule("copy_to_directory_toolchains"):
        _register_copy_to_directory_toolchains()
    if kwargs.pop("register_coreutils_toolchain", True) and not native.existing_rule("coreutils_toolchains"):
        _register_coreutils_toolchains()
    if kwargs.pop("register_jq_toolchain", True) and not native.existing_rule("jq_toolchains"):
        _register_jq_toolchains()
    if kwargs.pop("register_tar_toolchain", True) and not native.existing_rule("tar_toolchains"):
        _register_tar_toolchains()
    if kwargs.pop("register_yq_toolchain", True) and not native.existing_rule("yq_toolchains"):
        _register_yq_toolchains()
    if kwargs.pop("register_nodejs_toolchain", True) and not native.existing_rule("{}_toolchains".format(DEFAULT_NODE_REPOSITORY)):
        maybe_args = dict()
        if node_version_from_nvmrc:
            maybe_args["node_version_from_nvmrc"] = node_version_from_nvmrc
        nodejs_register_toolchains(
            name = DEFAULT_NODE_REPOSITORY,
            node_download_auth = node_download_auth,
            node_repositories = node_repositories,
            node_urls = node_urls,
            node_version = node_version,
            **maybe_args
        )
