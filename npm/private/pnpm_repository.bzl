"""Repository rules to import pnpm.
"""

load(":npm_import.bzl", _npm_import = "npm_import")
load(":versions.bzl", "PNPM_VERSIONS")

LATEST_PNPM_VERSION = PNPM_VERSIONS.keys()[-1]

def pnpm_repository(name, pnpm_version = LATEST_PNPM_VERSION):
    """Import https://npmjs.com/package/pnpm and provide a js_binary to run the tool.

    Useful as a way to run exactly the same pnpm as Bazel does, for example with:
    bazel run -- @pnpm//:pnpm --dir $PWD

    Args:
        name: name of the resulting external repository
        pnpm_version: version of pnpm, see https://www.npmjs.com/package/pnpm?activeTab=versions
    """

    if not native.existing_rule(name):
        _npm_import(
            name = name,
            integrity = PNPM_VERSIONS[pnpm_version],
            package = "pnpm",
            root_package = "",
            version = pnpm_version,
            extra_build_content = "\n".join([
                """load("@aspect_rules_js//js:defs.bzl", "js_binary")""",
                """js_binary(name = "pnpm", entry_point = "package/dist/pnpm.cjs", visibility = ["//visibility:public"])""",
            ]),
            register_copy_directory_toolchains = False,  # this code path should work for both WORKSPACE and bzlmod
            register_copy_to_directory_toolchains = False,  # this code path should work for both WORKSPACE and bzlmod
        )
