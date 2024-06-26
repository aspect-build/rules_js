"Utility functions for npm rules"

load("@aspect_bazel_lib//lib:paths.bzl", "relative_file")
load("@aspect_bazel_lib//lib:repo_utils.bzl", "repo_utils")
load("@bazel_skylib//lib:paths.bzl", "paths")

INTERNAL_ERROR_MSG = "ERROR: rules_js internal error, please file an issue: https://github.com/aspect-build/rules_js/issues"
DEFAULT_REGISTRY_DOMAIN = "registry.npmjs.org"
DEFAULT_REGISTRY_DOMAIN_SLASH = "{}/".format(DEFAULT_REGISTRY_DOMAIN)
DEFAULT_REGISTRY_PROTOCOL = "https"
DEFAULT_EXTERNAL_REPOSITORY_ACTION_CACHE = ".aspect/rules/external_repository_action_cache"

def _sorted_map(m):
    result = dict()
    for key in sorted(m.keys()):
        result[key] = m[key]

    return result

def _sanitize_string(string):
    # Workspace names may contain only A-Z, a-z, 0-9, '-', '_' and '.'
    result = ""
    for c in string.elems():
        if c == "@" and (not result or result[-1] == "_"):
            result += "at"
        if not c.isalnum() and c != "-" and c != "_" and c != ".":
            c = "_"
        result += c
    return result.strip("_-")

def _bazel_name(name, version = None):
    "Make a bazel friendly name from a package name and (optionally) a version that can be used in repository and target names"
    escaped_name = _sanitize_string(name)
    if not version:
        return escaped_name

    # Add an extra _ before the first segment
    version_segments_start = version.find("_")
    if version_segments_start != -1:
        version = version[:version_segments_start] + "_" + version[version_segments_start:]

    # Separate name + version with extra _
    return "%s__%s" % (escaped_name, _sanitize_string(version))

def _package_key(name, version):
    "Make a name/version pnpm-style name for a package name and version"
    return "%s@%s" % (name, version)

def _friendly_name(name, version):
    "Make a name@version developer-friendly name for a package name and version"
    return "%s@%s" % (name, version)

def _package_store_name(pnpm_name, pnpm_version):
    "Make a package store name for a given package and version"

    if pnpm_version.startswith("link:") or pnpm_version.startswith("file:"):
        name = pnpm_name
        version = "0.0.0"
    elif pnpm_version.startswith("npm:"):
        name, version = pnpm_version[4:].rsplit("@", 1)
    else:
        name = pnpm_name
        version = pnpm_version

    if version.startswith("@"):
        # Special case where the package name should _not_ be included in the package store name.
        # See https://github.com/aspect-build/rules_js/issues/423 for more context.
        return version.replace("/", "+")
    else:
        escaped_name = name.replace("/", "+")
        escaped_version = version.replace("://", "/").replace("/", "+")
        return "%s@%s" % (escaped_name, escaped_version)

def _make_symlink(ctx, symlink_path, target_path):
    symlink = ctx.actions.declare_symlink(symlink_path)
    ctx.actions.symlink(
        output = symlink,
        target_path = relative_file(target_path, symlink.path),
    )
    return symlink

def _parse_package_name(package):
    # Parse a @scope/name string and return a (scope, name) tuple
    if package[0] == "@":
        segments = package.split("/", 1)
        if len(segments) == 2:
            return (segments[0], segments[1])
    return ("", package)

def _npm_registry_url(package, registries, default_registry):
    (package_scope, _) = _parse_package_name(package)

    return registries[package_scope] if package_scope in registries else default_registry

def _npm_registry_download_url(package, version, registries, default_registry):
    "Make a registry download URL for a given package and version"

    (_, package_name_no_scope) = _parse_package_name(package)
    registry = _npm_registry_url(package, registries, default_registry)

    return "{0}/{1}/-/{2}-{3}.tgz".format(
        registry.removesuffix("/"),
        package,
        package_name_no_scope,
        # Strip the rules_js peer/patch metadata off the version. See pnpm.bzl
        version[:version.find("_")] if version.find("_") != -1 else version,
    )

def _is_git_repository_url(url):
    return url.startswith("git+ssh://") or url.startswith("git+https://") or url.startswith("git@")

def _to_registry_url(url):
    return "{}://{}".format(DEFAULT_REGISTRY_PROTOCOL, url) if url.find("//") == -1 else url

def _default_registry_url():
    return _to_registry_url(DEFAULT_REGISTRY_DOMAIN_SLASH)

def _hash(s):
    # Bazel's hash() resolves to a 32-bit signed integer [-2,147,483,648 to 2,147,483,647].
    # NB: There has been discussion of adding a sha256 built-in hash function to Starlark but no
    # work has been done to date.
    # See https://github.com/bazelbuild/starlark/issues/36#issuecomment-1115352085.
    return str(hash(s))

def _dicts_match(a, b):
    if len(a) != len(b):
        return False
    for key in a.keys():
        if not key in b:
            return False
        if a[key] != b[key]:
            return False
    return True

# Copies a file from the external repository to the same relative location in the source tree
def _reverse_force_copy(rctx, label, dst = None):
    if type(label) != "Label":
        fail(INTERNAL_ERROR_MSG)
    dst = dst if dst else str(rctx.path(label))
    src = str(rctx.path(paths.join(label.package, label.name)))
    if repo_utils.is_windows(rctx):
        fail("Not yet implemented for Windows")
        #         rctx.file("_reverse_force_copy.bat", content = """
        # @REM needs a mkdir dirname(%2)
        # xcopy /Y %1 %2
        # """, executable = True)
        #         result = rctx.execute(["cmd.exe", "/C", "_reverse_force_copy.bat", src.replace("/", "\\"), dst.replace("/", "\\")])

    else:
        rctx.file("_reverse_force_copy.sh", content = """#!/usr/bin/env bash
set -o errexit -o nounset -o pipefail
mkdir -p $(dirname $2)
cp -f $1 $2
""", executable = True)
        result = rctx.execute(["./_reverse_force_copy.sh", src, dst])
    if result.return_code != 0:
        msg = """

ERROR: failed to copy file from {src} to {dst}:
STDOUT:
{stdout}
STDERR:
{stderr}
""".format(
            src = src,
            dst = dst,
            stdout = result.stdout,
            stderr = result.stderr,
        )
        fail(msg)

# This uses `rctx.execute` to check if the file exists since `rctx.exists` does not exist.
def _exists(rctx, p):
    if type(p) == "Label":
        fail("ERROR: dynamic labels not accepted since they should be converted paths at the top of the repository rule implementation to avoid restarts after rctx.execute() calls")
    p = str(p)
    if repo_utils.is_windows(rctx):
        fail("Not yet implemented for Windows")
        #         rctx.file("_exists.bat", content = """IF EXIST %1 (
        #     EXIT /b 0
        # ) ELSE (
        #     EXIT /b 42
        # )""", executable = True)
        #         result = rctx.execute(["cmd.exe", "/C", "_exists.bat", str(p).replace("/", "\\")])

    else:
        rctx.file("_exists.sh", content = """#!/usr/bin/env bash
set -o errexit -o nounset -o pipefail
if [ ! -f $1 ]; then exit 42; fi
""", executable = True)
        result = rctx.execute(["./_exists.sh", str(p)])
    if result.return_code == 0:  # file exists
        return True
    elif result.return_code == 42:  # file does not exist
        return False
    else:
        fail(INTERNAL_ERROR_MSG)

def _replace_npmrc_token_envvar(token, npmrc_path, environ):
    # A token can be a reference to an environment variable
    if token.startswith("$"):
        # ${NPM_TOKEN} -> NPM_TOKEN
        # $NPM_TOKEN -> NPM_TOKEN
        token = token.removeprefix("$").removeprefix("{").removesuffix("}")
        if token in environ.keys() and environ[token]:
            token = environ[token]
        else:
            # buildifier: disable=print
            print("""
WARNING: Issue while reading "{npmrc}". Failed to replace env in config: ${{{token}}}
""".format(
                npmrc = npmrc_path,
                token = token,
            ))
    return token

def _default_external_repository_action_cache():
    return DEFAULT_EXTERNAL_REPOSITORY_ACTION_CACHE

def _is_tarball_extension(ext):
    # Takes an extension (without leading dot) and return True if the extension
    # is a common tarball extension as per
    # https://en.wikipedia.org/wiki/Tar_(computing)#Suffixes_for_compressed_files
    tarball_extensions = [
        "tar",
        "tar.bz2",
        "tb2",
        "tbz",
        "tbz2",
        "tz2",
        "tar.gz",
        "taz",
        "tgz",
        "tar.lz",
        "tar.lzma",
        "tlz",
        "tar.lzo",
        "tar.xz",
        "txz",
        "tar.Z",
        "tZ",
        "taZ",
        "tar.zst",
        "tzst",
    ]
    return ext in tarball_extensions

utils = struct(
    bazel_name = _bazel_name,
    sorted_map = _sorted_map,
    package_key = _package_key,
    sanitize_string = _sanitize_string,
    friendly_name = _friendly_name,
    package_store_name = _package_store_name,
    make_symlink = _make_symlink,
    # Symlinked node_modules structure package store path under node_modules
    package_store_root = ".aspect_rules_js",
    # Suffix for npm_import links repository
    links_repo_suffix = "__links",
    # Output group name for the package directory of a linked npm package
    package_directory_output_group = "package_directory",
    npm_registry_url = _npm_registry_url,
    npm_registry_download_url = _npm_registry_download_url,
    is_git_repository_url = _is_git_repository_url,
    to_registry_url = _to_registry_url,
    default_external_repository_action_cache = _default_external_repository_action_cache,
    default_registry = _default_registry_url,
    hash = _hash,
    dicts_match = _dicts_match,
    reverse_force_copy = _reverse_force_copy,
    exists = _exists,
    replace_npmrc_token_envvar = _replace_npmrc_token_envvar,
    is_tarball_extension = _is_tarball_extension,
)

# Exported only to be tested
utils_test = struct(
    parse_package_name = _parse_package_name,
)
