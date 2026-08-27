"""Repository rules to import pnpm.
"""

load("@bazel_lib//lib:repo_utils.bzl", "patch")
load(":npm_import.bzl", _npm_import_links_rule = "npm_import_links_rule", _npm_import_rule = "npm_import_rule")
load(":utils.bzl", "utils")
load(":versions.bzl", "PNPM_EXE_VERSIONS", "PNPM_VERSIONS")

LATEST_PNPM_VERSION = PNPM_VERSIONS.keys()[-1]

# Default to the latest pnpm v10
DEFAULT_PNPM_VERSION = [v for v in PNPM_VERSIONS.keys() if v.startswith("10")][-1]

# The platform packages shipping the native pnpm binary for pnpm 12+,
# each holding the binary of one @pnpm/exe.<platform> package.
PNPM_EXE_PLATFORMS = [
    "darwin-arm64",
    "darwin-x64",
    "linux-arm64",
    "linux-arm64-musl",
    "linux-x64",
    "linux-x64-musl",
    "win32-arm64",
    "win32-x64",
]

def _is_native_pnpm_version(pnpm_version):
    # pnpm 12+ is distributed as a native binary per platform (the @pnpm/exe.*
    # packages); the `pnpm` npm package is only a Node.js wrapper around it.
    major = pnpm_version.split(".")[0]
    return major.isdigit() and int(major) >= 12

def _js_entry_point(pnpm_version):
    major = pnpm_version.split(".")[0]
    if _is_native_pnpm_version(pnpm_version):
        # The corepack entry point, which spawns the native binary installed
        # alongside the wrapper at node_modules/@pnpm/exe.<platform>.
        return "package/bin/pnpm.mjs"
    if major.isdigit() and int(major) >= 11:
        # pnpm 11 switched the bundled entry from CJS to ESM.
        return "package/dist/pnpm.mjs"
    return "package/dist/pnpm.cjs"

def _pnpm_exe_platform(os_name, os_arch, is_musl):
    """Map a repository_ctx.os (name, arch) pair to a @pnpm/exe.* platform.

    Args:
        os_name: value of repository_ctx.os.name
        os_arch: value of repository_ctx.os.arch
        is_musl: True if the host is a musl-based Linux

    Returns:
        The @pnpm/exe.* platform suffix such as "darwin-arm64"
    """
    os_name = os_name.lower()
    if os_name.startswith("mac") or os_name.find("darwin") != -1:
        os_part = "darwin"
    elif os_name.startswith("windows"):
        os_part = "win32"
    elif os_name.find("linux") != -1:
        os_part = "linux"
    else:
        fail("pnpm 12+ does not provide a native binary for host os '{}'".format(os_name))

    os_arch = os_arch.lower()
    if os_arch in ["aarch64", "arm64"]:
        cpu_part = "arm64"
    elif os_arch in ["amd64", "x86_64", "x64"]:
        cpu_part = "x64"
    else:
        fail("pnpm 12+ does not provide a native binary for host cpu '{}'".format(os_arch))

    platform = "{}-{}".format(os_part, cpu_part)
    if os_part == "linux" and is_musl:
        platform = "{}-musl".format(platform)
    return platform

def _is_linux_musl(rctx):
    if rctx.os.name.lower().find("linux") == -1:
        return False
    ldd = rctx.which("ldd")
    if not ldd:
        return False

    # glibc ldd prints a GNU version banner; musl ldd prints usage mentioning musl.
    result = rctx.execute([ldd, "--version"])
    return (result.stdout + result.stderr).find("musl") != -1

def _pnpm_exe_repository_impl(rctx):
    version = rctx.attr.pnpm_version

    # The `pnpm` npm package: the Node.js wrapper entry points that locate and
    # spawn the native binary.
    rctx.download_and_extract(
        url = utils.npm_registry_download_url("pnpm", version, {}, utils.default_registry()),
        integrity = rctx.attr.integrity if rctx.attr.integrity else "",
    )

    # Apply patches inside the extracted package, same as npm_import.
    patch(
        rctx,
        patches = rctx.attr.patches,
        patch_tool = "patch",
        patch_args = rctx.attr.patch_args,
        patch_directory = "package",
    )

    # The native binary for the host platform, laid out where the wrapper
    # resolves the installed platform package.
    platform = _pnpm_exe_platform(rctx.os.name, rctx.os.arch, _is_linux_musl(rctx))
    exe_package = "@pnpm/exe.{}".format(platform)
    if platform not in rctx.attr.exe_integrity:
        fail("No known integrity for the {}@{} binary. Use a pnpm version mirrored in rules_js (see npm/private/versions.bzl) or upgrade rules_js.".format(exe_package, version))
    rctx.download_and_extract(
        url = utils.npm_registry_download_url(exe_package, version, {}, utils.default_registry()),
        integrity = rctx.attr.exe_integrity[platform],
        output = "package/node_modules/{}".format(exe_package),
        stripPrefix = "package",
    )

    # Compatibility entry for consumers of the pre-12 CJS entry point, such as
    # the default `use_pnpm` label of npm_translate_lock; pnpm 12+ only ships
    # the ESM corepack entry.
    # TODO: delete when pnpm <11 support is dropped and the default `use_pnpm`
    # label can change to `bin/pnpm.mjs`, which exists in pnpm 11+.
    if not rctx.path("package/bin/pnpm.cjs").exists:
        rctx.file("package/bin/pnpm.cjs", """\
const { spawnSync } = require('node:child_process')
const path = require('node:path')
const result = spawnSync(
    process.execPath,
    [path.join(__dirname, 'pnpm.mjs'), ...process.argv.slice(2)],
    { stdio: 'inherit' }
)
process.exit(result.status === null ? 1 : result.status)
""")

    rctx.file("BUILD.bazel", "\n".join([
        """load("@aspect_rules_js//js:defs.bzl", "js_binary")""",
        """load("@aspect_rules_js//npm/private:npm_package_internal.bzl", "npm_package_internal")""",
        # The package target referenced by the links repository, same as npm_import.
        """npm_package_internal(
    name = "pkg",
    src = ":package",
    package = "pnpm",
    version = "{version}",
    visibility = ["//visibility:public"],
)""".format(version = version),
        """js_binary(
    name = "pnpm",
    data = glob(["package/**"]),
    entry_point = "{entry_point}",
    include_npm = {include_npm},
    visibility = ["//visibility:public"],
)""".format(
            entry_point = _js_entry_point(version),
            include_npm = rctx.attr.include_npm,
        ),
    ]))

_pnpm_exe_repository_rule = repository_rule(
    implementation = _pnpm_exe_repository_impl,
    attrs = {
        "pnpm_version": attr.string(mandatory = True),
        "integrity": attr.string(),
        "exe_integrity": attr.string_dict(),
        "include_npm": attr.bool(),
        "patches": attr.label_list(),
        "patch_args": attr.string_list(default = ["-p1"]),
    },
)

def pnpm_repository(name, pnpm_version, include_npm, integrity, patches = [], patch_args = ["-p1"], exe_integrity = None):
    """Import https://npmjs.com/package/pnpm and provide a js_binary to run the tool.

    Useful as a way to run exactly the same pnpm as Bazel does, for example with:
    bazel run -- @pnpm//:pnpm --dir $PWD

    NOTE: pnpm 12+ is distributed as a native binary per platform. The imported
    repository contains the binary for the host platform the repository was
    fetched on, so running it on a different execution platform (e.g. remote
    execution) is not supported yet.

    Args:
        name: name of the resulting external repository
        pnpm_version: version of pnpm, see https://www.npmjs.com/package/pnpm?activeTab=versions

            May also be a tuple of (version, integrity) where the integrity value may be fetched like:
            `curl --silent https://registry.npmjs.org/pnpm | jq '.versions["8.6.11"].dist.integrity'`
        integrity: integrity hash for the pnpm version (optional)
        include_npm: if True, include the npm package along with pnpm binary
        patches: list of Label targets pointing to .patch files to apply to the
            extracted pnpm package (paths relative to the tarball root, which
            starts with "package/"). Forwarded to the underlying npm_import.
        patch_args: list of arguments for the patch tool. Defaults to ["-p1"].
        exe_integrity: integrity hashes of the @pnpm/exe.* platform binaries for
            pnpm 12+, as a dict of platform (e.g. "darwin-arm64") to integrity.
            Defaults to the hashes mirrored in versions.bzl.
    """

    if native.existing_rule(name):
        fail("Repository with name '{}' already exists".format(name))

    key = "{}@{}".format("pnpm", pnpm_version)

    if _is_native_pnpm_version(pnpm_version):
        _pnpm_exe_repository_rule(
            name = name,
            pnpm_version = pnpm_version,
            integrity = integrity,
            exe_integrity = exe_integrity if exe_integrity else PNPM_EXE_VERSIONS.get(pnpm_version, {}),
            include_npm = include_npm,
            patches = patches,
            patch_args = patch_args,
        )
    else:
        _npm_import_rule(
            name = name,
            key = key,
            integrity = integrity,
            package = "pnpm",
            root_package = "",
            version = pnpm_version,
            patches = patches,
            patch_args = patch_args,
            extra_build_content = "\n".join([
                """load("@aspect_rules_js//js:defs.bzl", "js_binary")""",
                """js_binary(
    name = "pnpm",
    data = glob(["package/**"]),
    entry_point = "{entry_point}",
    include_npm = {include_npm},
    visibility = ["//visibility:public"],
)""".format(entry_point = _js_entry_point(pnpm_version), include_npm = include_npm),
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

is_native_pnpm_version = _is_native_pnpm_version

# Exported for testing only.
pnpm_repository_internal = struct(
    exe_platform = _pnpm_exe_platform,
    is_native_pnpm_version = _is_native_pnpm_version,
    js_entry_point = _js_entry_point,
)
