"Utility functions for npm rules"

load("@aspect_bazel_lib//lib:utils.bzl", "is_bazel_6_or_greater")
load("@aspect_bazel_lib//lib:paths.bzl", "relative_file")
load("@aspect_bazel_lib//lib:repo_utils.bzl", "repo_utils")
load("@bazel_skylib//lib:paths.bzl", "paths")
load("@bazel_skylib//lib:types.bzl", "types")
load(":yaml.bzl", _parse_yaml = "parse")

INTERNAL_ERROR_MSG = "ERROR: rules_js internal error, please file an issue: https://github.com/aspect-build/rules_js/issues"
DEFAULT_REGISTRY_PROTOCOL = "https"

def _sanitize_string(string):
    # Workspace names may contain only A-Z, a-z, 0-9, '-', '_' and '.'
    result = ""
    for i in range(0, len(string)):
        c = string[i]
        if c == "@" and (not result or result[-1] == "_"):
            result += "at"
        if not c.isalnum() and c != "-" and c != "_" and c != ".":
            c = "_"
        result += c
    return result

def _bazel_name(name, version = None):
    "Make a bazel friendly name from a package name and (optionally) a version that can be used in repository and target names"
    escaped_name = _sanitize_string(name)
    if not version:
        return escaped_name
    version_segments = version.split("_")
    escaped_version = _sanitize_string(version_segments[0])
    peer_version = "_".join(version_segments[1:])
    if peer_version:
        escaped_version = "%s__%s" % (escaped_version, _sanitize_string(peer_version))
    return "%s__%s" % (escaped_name, escaped_version)

def _strip_peer_dep_version(version):
    "Remove peer dependency syntax from version string"

    # 21.1.0_rollup@2.70.2 becomes 21.1.0
    index = version.find("_")
    if index != -1:
        return version[:index]
    return version

def _pnpm_name(name, version):
    "Make a name/version pnpm-style name for a package name and version"
    return "%s/%s" % (name, version)

def _parse_pnpm_name(pnpmName):
    # Parse a name/version or @scope/name/version string and return
    # a (name, version) tuple
    segments = pnpmName.rsplit("/", 1)
    if len(segments) != 2:
        msg = "unexpected pnpm versioned name {}".format(pnpmName)
        fail(msg)
    return (segments[0], segments[1])

def _parse_pnpm_lock(content):
    """Parse the content of a pnpm-lock.yaml file.

    Args:
        content: lockfile content

    Returns:
        A tuple of (importers dict, packages dict)
    """
    parsed = _parse_yaml(content)

    if not types.is_dict(parsed):
        fail("lockfile should be a starlark dict")
    if "lockfileVersion" not in parsed.keys():
        fail("expected lockfileVersion key in lockfile")
    _assert_lockfile_version(parsed["lockfileVersion"])

    importers = parsed.get("importers", {
        ".": {
            "specifiers": parsed.get("specifiers", {}),
            "dependencies": parsed.get("dependencies", {}),
            "optionalDependencies": parsed.get("optionalDependencies", {}),
            "devDependencies": parsed.get("devDependencies", {}),
        },
    })

    packages = parsed.get("packages", {})

    return importers, packages

def _assert_lockfile_version(version, testonly = False):
    if type(version) != type(1.0):
        fail("version should be passed as a float")

    # Restrict the supported lock file versions to what this code has been tested with:
    #   5.3 - pnpm v6.x.x
    #   5.4 - pnpm v7.0.0 bumped the lockfile version to 5.4
    min_lock_version = 5.3
    max_lock_version = 5.4
    msg = None

    if version < min_lock_version:
        msg = "npm_translate_lock requires lock_version at least {min}, but found {actual}. Please upgrade to pnpm v6 or greater.".format(
            min = min_lock_version,
            actual = version,
        )
    if version > max_lock_version:
        msg = "npm_translate_lock currently supports a maximum lock_version of {max}, but found {actual}. Please file an issue on rules_js".format(
            max = max_lock_version,
            actual = version,
        )
    if msg and not testonly:
        fail(msg)
    return msg

def _friendly_name(name, version):
    "Make a name@version developer-friendly name for a package name and version"
    return "%s@%s" % (name, version)

def _virtual_store_name(name, version):
    "Make a virtual store name for a given package and version"
    if version.startswith("@"):
        # Special case where the package name should _not_ be included in the virtual store name.
        # See https://github.com/aspect-build/rules_js/issues/423 for more context.
        return version.replace("/", "+")
    else:
        escaped_name = name.replace("/", "+")
        escaped_version = version.replace("/", "+")
        return "%s@%s" % (escaped_name, escaped_version)

def _make_symlink(ctx, symlink_path, target_file):
    files = []
    if ctx.attr.use_declare_symlink:
        symlink = ctx.actions.declare_symlink(symlink_path)
        ctx.actions.symlink(
            output = symlink,
            target_path = relative_file(target_file.path, symlink.path),
        )
        files.append(target_file)
    else:
        if _is_at_least_bazel_6() and target_file.is_directory:
            # BREAKING CHANGE in Bazel 6 requires you to use declare_directory if your target_file
            # in ctx.actions.symlink is a directory artifact
            symlink = ctx.actions.declare_directory(symlink_path)
        else:
            symlink = ctx.actions.declare_file(symlink_path)
        ctx.actions.symlink(
            output = symlink,
            target_file = target_file,
        )
    files.append(symlink)
    return files

def _is_at_least_bazel_6():
    # Hacky way to check if the we're using at least Bazel 6. Would be nice if there was a ctx.bazel_version instead.
    # native.bazel_version only works in repository rules.
    return "apple_binary" not in dir(native)

def _parse_package_name(package):
    # Parse a @scope/name string and return a (scope, name) tuple
    segments = package.split("/", 1)
    if len(segments) == 2 and segments[0].startswith("@"):
        return (segments[0], segments[1])
    return ("", segments[0])

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
        _strip_peer_dep_version(version),
    )

def _is_git_repository_url(url):
    return url.startswith("git+ssh://")

def _to_registry_url(url):
    return "{}://{}".format(DEFAULT_REGISTRY_PROTOCOL, url) if url.find("//") == -1 else url

def _default_registry():
    return _to_registry_url("registry.npmjs.org/")

def _hash(s):
    result = str(hash(s))
    if result.startswith("-"):
        # Bazel's hash() resolves to a signed 32bit number [-2,147,483,648 to 2,147,483,647].
        # Convert manually to a unique unsigned number here.
        # -???,???,??x to 3,xxx,xxx,xxx
        # -1,xxx,xxx,xxx to 4,xxx,xxx,xxx
        # -2,xxx,xxx,xxx to 5,xxx,xxx,xxx
        result = result[1:]
        if len(result) <= 9:
            padding = "0" * (9 - len(result))
            result = "3" + padding + result
        elif result[0] == "1":
            result = "4" + result[1:]
        elif result[0] == "2":
            result = "5" + result[1:]
        else:
            fail(INTERNAL_ERROR_MSG)
    return result

def _dicts_match(a, b):
    if len(a) != len(b):
        return False
    for key in a.keys():
        if not key in b:
            return False
        if a[key] != b[key]:
            return False
    return True

# Generate a consistent label string between Bazel versions.
def _consistent_label_str(label):
    return "//{}:{}".format(
        # Starting in Bazel 6, the workspace name is empty for the local workspace and there's no other way to determine it.
        # This behavior differs from Bazel 5 where the local workspace name was fully qualified in str(label).
        label.package,
        label.name,
    )

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

utils = struct(
    bazel_name = _bazel_name,
    pnpm_name = _pnpm_name,
    assert_lockfile_version = _assert_lockfile_version,
    parse_pnpm_name = _parse_pnpm_name,
    parse_pnpm_lock = _parse_pnpm_lock,
    friendly_name = _friendly_name,
    virtual_store_name = _virtual_store_name,
    strip_peer_dep_version = _strip_peer_dep_version,
    make_symlink = _make_symlink,
    # Symlinked node_modules structure virtual store path under node_modules
    virtual_store_root = ".aspect_rules_js",
    # Suffix for npm_import links repository
    links_repo_suffix = "__links",
    # Output group name for the package directory of a linked package
    package_directory_output_group = "package_directory",
    npm_registry_url = _npm_registry_url,
    npm_registry_download_url = _npm_registry_download_url,
    parse_package_name = _parse_package_name,
    is_git_repository_url = _is_git_repository_url,
    to_registry_url = _to_registry_url,
    default_registry = _default_registry,
    hash = _hash,
    dicts_match = _dicts_match,
    consistent_label_str = _consistent_label_str,
    bzlmod_supported = is_bazel_6_or_greater(),
    reverse_force_copy = _reverse_force_copy,
    exists = _exists,
)
