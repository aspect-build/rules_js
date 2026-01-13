"Utility functions for npm rules"

load("@bazel_lib//lib:paths.bzl", "relative_file")
load("@bazel_lib//lib:repo_utils.bzl", "repo_utils")
load("@bazel_skylib//lib:paths.bzl", "paths")

INTERNAL_ERROR_MSG = "ERROR: rules_js internal error, please file an issue: https://github.com/aspect-build/rules_js/issues"
DEFAULT_REGISTRY_DOMAIN = "registry.npmjs.org"
DEFAULT_REGISTRY_DOMAIN_SLASH = "{}/".format(DEFAULT_REGISTRY_DOMAIN)
DEFAULT_REGISTRY_PROTOCOL = "https"
DEFAULT_EXTERNAL_REPOSITORY_ACTION_CACHE = ".aspect/rules/external_repository_action_cache"

# Maximum package store name length before hashing to prevent long paths
# Similar to pnpm's limit: https://github.com/pnpm/pnpm/blob/9d4c16876f899146a45f21d93f041b42e3413011/packages/dependency-path/src/index.ts#L165
_MAX_STORE_LENGTH = 120

# Maximum length of peer dependency string before hashing to prevent long paths
_MAX_PEER_DEP_LENGTH = 32

# A unique separator for link: dependencies to separate the link name vs path
_LINK_SEPARATOR = "|"

def _sorted_map(m):
    # TODO(zbarsky): maybe faster as `dict(sorted(m.items()))`?
    return {k: m[k] for k in sorted(m.keys())}

def _importer_to_link(package, path):
    # Convert a pnpm-workspace relative path to a link: key
    return "link:{}{}{}".format(package, _LINK_SEPARATOR, path)

def _link_to_importer(link):
    # Convert a link: key to a pnpm-workspace relative path
    p_idx = link.find(_LINK_SEPARATOR)
    if p_idx == -1 or not link.startswith("link:"):
        msg = "invalid link dependency key '{}'".format(link)
        fail(msg)
    return link[p_idx + 1:]

def _link_to_alias(link):
    # Convert a link: key to the link alias (package name)
    p_idx = link.find(_LINK_SEPARATOR)
    if p_idx == -1 or not link.startswith("link:"):
        msg = "invalid link dependency key '{}'".format(link)
        fail(msg)
    return link[5:p_idx]

def _package_shorten_key(s):
    # Prevent long paths similar to pnpm. The pnpm lockfile v6+ does not shorten long versions
    # and instead relies on the lockfile processing to handle it depending on the platform.
    #
    # Long file paths can lead to "File name too long" build failures in bazel
    #
    # See:
    #  https://github.com/pnpm/pnpm/blob/9d4c16876f899146a45f21d93f041b42e3413011/packages/dependency-path/src/index.ts#L165
    #  https://github.com/pnpm/pnpm/blob/c5d4d81f56e53d824a8ed1a0f2b0e830ccaa9a0e/packages/dependency-path/src/index.ts#L169-L180
    version_index = s.find("@", 1)
    peers_index = s.find("(", version_index)

    # Shorten long peer deps
    if peers_index != -1:
        if len(s) - peers_index > _MAX_PEER_DEP_LENGTH or len(s) > _MAX_STORE_LENGTH:
            s = s[:peers_index] + "(" + _hash(s[peers_index:]).lstrip("-") + ")"
    else:
        peers_index = len(s)

    # If the full key is still too long, shorten the version
    if len(s) > _MAX_STORE_LENGTH:
        # If hashing peers was not enough, hash the version too
        s = s[:version_index] + "@" + _hash(s[version_index:peers_index]).lstrip("-") + s[peers_index:]

    return s

def _package_store_name(s):
    # Target names may contain only A-Z, a-z, 0-9, '-', '_', '.', '+', '@' and probably more.
    # Package store target names try to align with pnpm v9+ store naming conventions.
    # Compare with the pnpm v9+ virtual store before modifying.

    # Convert link: to {name}@0.0.0 for naming of local workspace packages
    if s.startswith("link:"):
        s = _link_to_alias(s) + "@0.0.0"
    else:
        s = _package_shorten_key(s)

    r = ""
    for c in s.elems():
        if (c == "/" or c == ":"):
            # use "+" path/protocol symbols like pnpm
            r += "+"
        elif not c.isalnum() and c != "-" and c != "_" and c != "." and c != "+" and c != "@":
            # use "_" for all other other characters not friendly with target names
            if r and r[-1] != "_":
                r += "_"
        else:
            r += c

    r = r.rstrip("_-.")

    return r

def _package_repo_name(prefix, s):
    # Workspace names may contain only A-Z, a-z, 0-9, '-', '_' and '.'
    # Package repo names handle '/' and other characters unique to better represent npm packages.

    # link: packages are not supported
    if s.startswith("link:"):
        fail("link: packages should not be repositories")

    s = _package_shorten_key(s)
    version_index = s.find("@", 1)

    r = prefix + "__"
    for i, c in enumerate(s.elems()):
        if i == version_index:
            # Separate package name and version with double underscore
            r += "__"
        elif c == "@" and (i == 0 or s[i - 1] == "("):
            # Replace scope and peer/patch separator with 'at_'
            if r and r[-1] != "_":
                r += "_"
            r += "at_"
        elif c == ")":
            pass  # skip closing peer/patch parentheses
        elif not c.isalnum() and c != "-" and c != "_" and c != ".":
            r += "_"
        else:
            r += c

    return r.rstrip("_-.")

def _friendly_name(name, version):
    "Make a name@version developer-friendly name for a package name and version"
    return "%s@%s" % (name, version)

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
        version,
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
    dst = dst if dst else rctx.path(label)
    src = rctx.path(paths.join(label.package, label.name))
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

def _replace_npmrc_token_envvar(token, npmrc_path, rctx):
    # A token can be a reference to an environment variable
    if token.startswith("$"):
        # ${NPM_TOKEN} -> NPM_TOKEN
        # $NPM_TOKEN -> NPM_TOKEN
        token = token.removeprefix("$").removeprefix("{").removesuffix("}")
        if rctx.getenv(token) != None:
            token = rctx.getenv(token)
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
    sorted_map = _sorted_map,
    friendly_name = _friendly_name,
    link_to_importer = _link_to_importer,
    importer_to_link = _importer_to_link,
    package_repo_name = _package_repo_name,
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
    replace_npmrc_token_envvar = _replace_npmrc_token_envvar,
    is_tarball_extension = _is_tarball_extension,
)

# Exported only to be tested
utils_test = struct(
    parse_package_name = _parse_package_name,
)
