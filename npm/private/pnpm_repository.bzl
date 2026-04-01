"""Repository rules to import pnpm.
"""

load(":npm_import.bzl", _npm_import_links_rule = "npm_import_links_rule", _npm_import_rule = "npm_import_rule")
load(":utils.bzl", "utils")
load(":versions.bzl", "PNPM_VERSIONS")

LATEST_PNPM_VERSION = PNPM_VERSIONS.keys()[-1]

# Default to the latest pnpm v10
DEFAULT_PNPM_VERSION = [v for v in PNPM_VERSIONS.keys() if v.startswith("10")][-1]

def pnpm_repository(name, pnpm_version, include_npm, integrity):
    """Import https://npmjs.com/package/pnpm and provide a js_binary to run the tool.

    Useful as a way to run exactly the same pnpm as Bazel does, for example with:
    bazel run -- @pnpm//:pnpm --dir $PWD

    Args:
        name: name of the resulting external repository
        pnpm_version: version of pnpm, see https://www.npmjs.com/package/pnpm?activeTab=versions

            May also be a tuple of (version, integrity) where the integrity value may be fetched like:
            `curl --silent https://registry.npmjs.org/pnpm | jq '.versions["8.6.11"].dist.integrity'`
        integrity: integrity hash for the pnpm version (optional)
        include_npm: if True, include the npm package along with pnpm binary
    """

    if native.existing_rule(name):
        fail("Repository with name '{}' already exists".format(name))

    key = "{}@{}".format("pnpm", pnpm_version)

    _npm_import_rule(
        name = name,
        key = key,
        integrity = integrity,
        package = "pnpm",
        root_package = "",
        version = pnpm_version,
        extra_build_content = "\n".join([
            """load("@aspect_rules_js//js:defs.bzl", "js_binary")""",
            """js_binary(
    name = "pnpm",
    data = glob(["package/**"]),
    entry_point = "package/dist/pnpm.cjs",
    include_npm = {include_npm},
    visibility = ["//visibility:public"],
)""".format(include_npm = include_npm),
        ]),
        extract_full_archive = True,
    )

    _npm_import_links_rule(
        name = "{}{}".format(name, utils.links_repo_suffix),
        key = key,
        package = "pnpm",
        root_package = "",
        version = pnpm_version,
    )
