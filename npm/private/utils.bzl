"Utility functions for npm rules"

load("@aspect_bazel_lib//lib:paths.bzl", "relative_file")
load("@aspect_bazel_lib//lib:repo_utils.bzl", "repo_utils")
load("@bazel_skylib//lib:paths.bzl", "paths")

INTERNAL_ERROR_MSG = "ERROR: rules_js internal error, please file an issue: https://github.com/aspect-build/rules_js/issues"
DEFAULT_REGISTRY_DOMAIN = "registry.npmjs.org"
DEFAULT_REGISTRY_DOMAIN_SLASH = "{}/".format(DEFAULT_REGISTRY_DOMAIN)
DEFAULT_REGISTRY_PROTOCOL = "https"
DEFAULT_EXTERNAL_REPOSITORY_ACTION_CACHE = ".aspect/rules/external_repository_action_cache"

# Alphabet for base64 strings.
_B64_CHARS = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

def _sorted_map(m):
    # TODO(zbarsky): maybe faster as `dict(sorted(m.items()))`?
    return {k: m[k] for k in sorted(m.keys())}

def _sanitize_rule_name(string):
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
    escaped_name = _sanitize_rule_name(name)
    if not version:
        return escaped_name

    # Separate name + version with extra _
    return "%s__%s" % (escaped_name, _sanitize_rule_name(version))

def _package_key(name, version):
    "Make a name/version pnpm-style name for a package name and version"
    return "%s@%s" % (name, version)

def _friendly_name(name, version):
    "Make a name@version developer-friendly name for a package name and version"
    return "%s@%s" % (name, version)

def _escape_target_name(name):
    return name.replace("://", "/").replace("/", "+").replace(":", "+")

def _package_store_name(pnpm_name, pnpm_version):
    "Make a package store name for a given package and version"

    if pnpm_version.startswith("link:"):
        # Distinguish local links a 0.0.0 version. This is unlike pnpm which symlinks
        # local links into the source tree instead of storing them in the package store.
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
        return _escape_target_name(version)
    else:
        return "%s@%s" % (_escape_target_name(name), _escape_target_name(version))

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
        scope_end = package.find("/", 1)
        if scope_end > 0:
            return (package[0:scope_end], package[scope_end + 1:])
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
        if environ.get(token, False):
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

def _hex_to_base64(hex_string):
    """Converts a non-delimited hex string (like a SHA-512 checksum) to base64."""

    # 1. Convert hex string to a list of integer bytes
    bytes_list = []

    # Loop with step 2 to grab hex pairs
    for i in range(0, len(hex_string), 2):
        bytes_list.append(int(hex_string[i:i + 2], 16))

    output = []
    length = len(bytes_list)

    # 2. Process bytes in chunks of 3 using range(start, stop, step)
    for i in range(0, length, 3):
        b1 = bytes_list[i]

        # Check if 2nd byte exists
        if i + 1 < length:
            b2 = bytes_list[i + 1]
        else:
            b2 = -1

        # Check if 3rd byte exists
        if i + 2 < length:
            b3 = bytes_list[i + 2]
        else:
            b3 = -1

        # Construct 24-bit buffer
        # Use 0 for missing bytes during bitwise ops
        val = (b1 << 16) | ((b2 if b2 != -1 else 0) << 8) | (b3 if b3 != -1 else 0)

        # Extract 6-bit indices
        c1 = (val >> 18) & 0x3F
        c2 = (val >> 12) & 0x3F
        c3 = (val >> 6) & 0x3F
        c4 = val & 0x3F

        output.append(_B64_CHARS[c1])
        output.append(_B64_CHARS[c2])

        # Handle Padding
        if b2 == -1:
            # Only 1 byte available -> Pad 2
            output.append("=")
            output.append("=")
        elif b3 == -1:
            # Only 2 bytes available -> Pad 1
            output.append(_B64_CHARS[c3])
            output.append("=")
        else:
            # All 3 bytes available -> No padding
            output.append(_B64_CHARS[c3])
            output.append(_B64_CHARS[c4])

    return "".join(output)

utils = struct(
    bazel_name = _bazel_name,
    sorted_map = _sorted_map,
    package_key = _package_key,
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
    to_registry_url = _to_registry_url,
    default_external_repository_action_cache = _default_external_repository_action_cache,
    default_registry = _default_registry_url,
    hash = _hash,
    dicts_match = _dicts_match,
    reverse_force_copy = _reverse_force_copy,
    exists = _exists,
    replace_npmrc_token_envvar = _replace_npmrc_token_envvar,
    is_tarball_extension = _is_tarball_extension,
    hex_to_base64 = _hex_to_base64,
)

# Exported only to be tested
utils_test = struct(
    parse_package_name = _parse_package_name,
)
