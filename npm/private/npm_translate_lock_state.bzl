"""npm_translate_lock state management abstraction so main impl is easier to read
and maintain"""

load("@bazel_lib//lib:base64.bzl", "base64")
load("@bazel_lib//lib:repo_utils.bzl", "repo_utils")
load("@bazel_skylib//lib:paths.bzl", "paths")
load(":npm_translate_lock_helpers.bzl", "helpers")
load(":npmrc.bzl", "parse_npmrc")
load(":pnpm.bzl", "pnpm")
load(":transitive_closure.bzl", "calculate_transitive_closures")
load(":utils.bzl", "INTERNAL_ERROR_MSG", "utils")

NPM_RC_FILENAME = ".npmrc"
PACKAGE_JSON_FILENAME = "package.json"
PNPM_LOCK_FILENAME = "pnpm-lock.yaml"
PNPM_WORKSPACE_FILENAME = "pnpm-workspace.yaml"
PNPM_LOCK_ACTION_CACHE_PREFIX = "npm_translate_lock_"
RULES_JS_DISABLE_UPDATE_PNPM_LOCK_ENV = "ASPECT_RULES_JS_DISABLE_UPDATE_PNPM_LOCK"

################################################################################
def _init(priv, rctx, attr):
    is_windows = repo_utils.is_windows(rctx)

    _validate_attrs(attr)

    _init_external_repository_action_cache(priv, attr)

    _init_common_labels(priv, rctx, attr)

    if _should_update_pnpm_lock(priv):
        # labels only needed when updating the pnpm lock file
        _init_update_labels(priv, rctx, attr)

    # parse the pnpm lock file incase since we need the importers list for additional init
    if attr.pnpm_lock and rctx.path(attr.pnpm_lock).exists:
        rctx.report_progress("Translating {}".format(attr.pnpm_lock))

        _load_lockfile(priv, rctx, attr, rctx.path(attr.pnpm_lock), is_windows)

    # May depend on lockfile state
    _init_root_package(priv)
    _init_workspace(priv, rctx, is_windows)

    _init_npmrc(priv, rctx, attr)

    if _should_update_pnpm_lock(priv):
        _copy_update_input_files(priv, rctx, attr)
        _copy_unspecified_input_files(priv, rctx, attr)

################################################################################
def _validate_attrs(attr):
    if not attr.pnpm_lock and not attr.npm_package_lock and not attr.yarn_lock:
        fail("at least one of pnpm_lock, npm_package_lock or yarn_lock must be set")
    if attr.npm_package_lock and attr.yarn_lock:
        fail("only one of npm_package_lock or yarn_lock may be set")

################################################################################
def _init_common_labels(priv, rctx, attr):
    # lock files
    if attr.pnpm_lock:
        rctx.watch(attr.pnpm_lock)
        priv["pnpm_lock_label"] = attr.pnpm_lock
    elif attr.npm_package_lock or attr.yarn_lock:
        priv["pnpm_lock_label"] = (attr.npm_package_lock or attr.yarn_lock).same_package_label("pnpm-lock.yaml")

    priv["pnpm_root_package_json"] = priv["pnpm_lock_label"].same_package_label(PACKAGE_JSON_FILENAME)

################################################################################
def _init_update_labels(priv, rctx, attr):
    pnpm_lock_label = priv["pnpm_lock_label"]
    pnpm_lock_label_str = "//{}:{}".format(pnpm_lock_label.package, pnpm_lock_label.name)
    action_cache_path = paths.join(
        priv["external_repository_action_cache"],
        PNPM_LOCK_ACTION_CACHE_PREFIX + base64.encode(utils.hash(helpers.to_apparent_repo_name(priv["rctx_name"]) + pnpm_lock_label_str)),
    )
    priv["action_cache_label"] = Label("@@//:" + action_cache_path)

    if attr.pnpm_lock:
        _copy_input_file(
            priv,
            rctx,
            attr,
            rctx.path(attr.pnpm_lock),
            paths.join(attr.pnpm_lock.package, attr.pnpm_lock.name),
        )
    if attr.npm_package_lock:
        _copy_input_file(
            priv,
            rctx,
            attr,
            rctx.path(attr.npm_package_lock),
            paths.join(attr.npm_package_lock.package, attr.npm_package_lock.name),
        )
    if attr.yarn_lock:
        _copy_input_file(
            priv,
            rctx,
            attr,
            rctx.path(attr.yarn_lock),
            paths.join(attr.yarn_lock.package, attr.yarn_lock.name),
        )

################################################################################
def _init_external_repository_action_cache(priv, attr):
    # initialize external_repository_action_cache
    priv["external_repository_action_cache"] = attr.external_repository_action_cache if attr.external_repository_action_cache else utils.default_external_repository_action_cache()

################################################################################
def _init_root_package(priv):
    pnpm_lock_label = priv["pnpm_lock_label"]

    # Don't allow a pnpm lock file that isn't in the root directory of a bazel package
    if paths.dirname(pnpm_lock_label.name):
        msg = "expected pnpm lock file {} to be at the root of a bazel package".format(pnpm_lock_label)
        fail(msg)
    priv["root_package"] = pnpm_lock_label.package

def _init_workspace(priv, rctx, is_windows):
    root_package_json = {}

    root_package_json_path = rctx.path(priv["pnpm_root_package_json"])
    if root_package_json_path.exists:
        # Load pnpm settings from root package.json for pnpm <= v9.
        root_package_json = json.decode(rctx.read(root_package_json_path))

    priv["pnpm_settings"] = root_package_json.get("pnpm", {})

    # Read settings from pnpm-workspace.yaml for pnpm v10+ (NOTE: pnpm 9-10+ has lockfile version 9).
    # Support scenario where pnpm-lock.yaml was never parsed and "lock_version" is not set.
    pnpm_lock_label = priv["pnpm_lock_label"]
    pnpm_workspace_label = pnpm_lock_label.same_package_label(PNPM_WORKSPACE_FILENAME)
    pnpm_workspace_path = rctx.path(pnpm_workspace_label)
    if pnpm_workspace_path.exists:
        pnpm_workspace_json, workspace_parse_err = _yaml_to_json(rctx, pnpm_workspace_path, is_windows)

        if workspace_parse_err == None:
            pnpm_workspace_settings, workspace_parse_err = pnpm.parse_pnpm_workspace_json(pnpm_workspace_json)

            if pnpm_workspace_settings:
                priv["pnpm_settings"] = priv["pnpm_settings"] | pnpm_workspace_settings

        if workspace_parse_err != None:
            should_update = _should_update_pnpm_lock(priv)
            msg = """
    {type}: pnpm-workspace.yaml parse error {error}`.
    """.format(type = "WARNING" if should_update else "ERROR", error = workspace_parse_err)

            if should_update:
                # buildifier: disable=print
                print(msg)
            else:
                fail(msg)

################################################################################
def _init_npmrc(priv, rctx, attr):
    if attr.npmrc:
        _load_npmrc(priv, rctx, attr, rctx.path(attr.npmrc), attr.npmrc)
    else:
        npmrc_label = attr.pnpm_lock or attr.npm_package_lock or attr.yarn_lock
        if npmrc_label:
            npmrc_label = npmrc_label.same_package_label(NPM_RC_FILENAME)

            # check for a .npmrc next to the pnpm-lock.yaml file and fail if it exists to
            # prevent unexpected behavior from an undeclared inputs
            if rctx.path(npmrc_label).exists:
                fail("""
ERROR: Undeclared .npmrc file `{npmrc}`.
        Set the `npmrc` attribute of `npm_translate_lock(name = "{rctx_name}")` to `{npmrc}` or add it to .bazelignore.
""".format(npmrc = npmrc_label, rctx_name = priv["rctx_name"]))

    if attr.use_home_npmrc:
        _load_home_npmrc(priv, rctx, attr)

################################################################################
def _copy_update_input_files(priv, rctx, attr):
    for script_label in attr.preupdate:
        _copy_input_file(
            priv,
            rctx,
            attr,
            rctx.path(script_label),
            paths.join(script_label.package, script_label.name),
        )
    for data_label in attr.data:
        _copy_input_file(
            priv,
            rctx,
            attr,
            rctx.path(data_label),
            paths.join(data_label.package, data_label.name),
        )

################################################################################
# we can derive input files that should be specified but are not and copy these over; we warn the user when we do this
def _copy_unspecified_input_files(priv, rctx, attr):
    src_root = priv["src_root"]

    pnpm_lock_label = priv["pnpm_lock_label"]
    pnpm_workspace_label = pnpm_lock_label.same_package_label(PNPM_WORKSPACE_FILENAME) if pnpm_lock_label else Label("@@//:" + PNPM_WORKSPACE_FILENAME)
    pnpm_workspace_path = rctx.path(pnpm_workspace_label)
    pnpm_workspace_relpath = str(pnpm_workspace_path).removeprefix(src_root)

    # pnpm-workspace.yaml
    if _has_workspaces(priv) and not _has_input_hash(priv, pnpm_workspace_relpath):
        # there are workspace packages so there must be a pnpm-workspace.yaml file
        # buildifier: disable=print
        fail("""
ERROR: Implicitly using pnpm-workspace.yaml file `{pnpm_workspace}` since the `{pnpm_lock}` file contains workspace packages is unsupported.
    Add `{pnpm_workspace}` to the 'data' attribute of `npm_translate_lock(name = "{rctx_name}")`.
""".format(
            pnpm_lock = pnpm_lock_label,
            pnpm_workspace = pnpm_workspace_label,
            rctx_name = priv["rctx_name"],
        ))

    pnpm_lock_dir = str(rctx.path(pnpm_lock_label).dirname) if pnpm_lock_label else src_root
    rel_dir = pnpm_lock_dir.removeprefix(src_root)

    # package.json files
    for package_json in priv["importers"].keys():
        rel_path = paths.normalize(paths.join(rel_dir, package_json, "package.json"))
        workspace_path = paths.join(src_root, rel_path)

        if not _has_input_hash(priv, rel_path):
            if not rctx.path(workspace_path).exists:
                msg = "ERROR: expected {path} to exist since the `{pnpm_lock}` file contains this workspace package".format(
                    path = workspace_path,
                    pnpm_lock = pnpm_lock_label,
                )
                fail(msg)
            _copy_input_file(priv, rctx, attr, workspace_path, str(rctx.path(package_json)))

    # Read patches from pnpm-lock.yaml `patchedDependencies`
    for patch_info in priv["pnpm_patched_dependencies"].values():
        patch = patch_info.get("path")
        rel_path = paths.normalize(paths.join(rel_dir, patch))
        workspace_path = paths.join(src_root, rel_path)

        if not _has_input_hash(priv, rel_path):
            if not rctx.path(workspace_path).exists:
                msg = "ERROR: expected {path} to exist since the `{package_json}` file contains this patch in `pnpm.patchedDependencies`.".format(
                    path = workspace_path,
                    package_json = priv["pnpm_root_package_json"],
                )
                fail(msg)
            _copy_input_file(priv, rctx, attr, workspace_path, str(rctx.path(patch)))

################################################################################
def _has_input_hash(priv, path):
    return path in priv["input_hashes"]

################################################################################
def _set_input_hash(priv, path, value):
    # Sets an input hash. Returns True the value was set/updated, False if the value
    # was already set to the desired hash.
    if type(path) != "string" or type(value) != "string":
        fail(INTERNAL_ERROR_MSG)
    if priv["input_hashes"].get(path) == value:
        return False
    priv["input_hashes"][path] = value
    return True

################################################################################
def _action_cache_miss(priv, rctx):
    action_cache_path = rctx.path(priv["action_cache_label"])
    if action_cache_path.exists:
        input_hashes = parse_npmrc(rctx.read(action_cache_path))
        if utils.dicts_match(input_hashes, priv["input_hashes"]):
            # Calculated input hashes match saved input hashes; nothing to update
            return False
    return True

################################################################################
def _write_action_cache(priv, rctx):
    header = """# @generated
# Input hashes for repository rule npm_translate_lock(name = \"{}\", pnpm_lock = \"{}\").
# This file should be checked into version control along with the pnpm-lock.yaml file.
""".format(helpers.to_apparent_repo_name(priv["rctx_name"]), str(priv["pnpm_lock_label"]))

    contents = []
    for key, value in priv["input_hashes"].items():
        contents.append("{}={}".format(key, value))

    # Sort to reduce diffs when the file is updated
    contents = sorted(contents)

    rctx.file(
        paths.join(priv["action_cache_label"].package, priv["action_cache_label"].name),
        header + "\n".join(contents) + "\n",
    )
    utils.reverse_force_copy(
        rctx,
        priv["action_cache_label"],
        paths.join(priv["src_root"], priv["action_cache_label"].package, priv["action_cache_label"].name),
    )

################################################################################

def _copy_input_file(priv, rctx, attr, path, repository_path):
    if _should_update_pnpm_lock(priv):
        # NB: rctx.read will convert binary files to text but that is acceptable for
        # the purposes of calculating a hash of the file
        _set_input_hash(
            priv,
            str(path).removeprefix(priv["src_root"]),
            utils.hash(rctx.read(path)),
        )

    # Copy the file using cp (linux/macos) or xcopy (windows). Don't use the rctx.template
    # trick with empty substitution as this does not copy over binary files properly. Also do not
    # use the rctx.download with `file:` url trick since that messes with the
    # experimental_remote_downloader option. rctx.read follows by rctx.file also does not
    # work since it can't handle binary files.
    _copy_input_file_action(rctx, attr, path, repository_path)

def _copy_input_file_action(rctx, attr, src, dst):
    is_windows = repo_utils.is_windows(rctx)

    # ensure the destination directory exists
    dst_segments = dst.split("/")
    if len(dst_segments) > 1:
        dirname = "/".join(dst_segments[:-1])
        mkdir_args = ["mkdir", "-p", dirname] if not is_windows else ["cmd", "/c", "if not exist {dir} (mkdir {dir})".format(dir = dirname.replace("/", "\\"))]
        result = rctx.execute(
            mkdir_args,
            quiet = attr.quiet,
        )
        if result.return_code:
            msg = "Failed to create directory for copy. '{}' exited with {}: \nSTDOUT:\n{}\nSTDERR:\n{}".format(" ".join(mkdir_args), result.return_code, result.stdout, result.stderr)
            fail(msg)

    cp_args = ["cp", "-f", src, dst] if not is_windows else ["xcopy", "/Y", str(src).replace("/", "\\"), "\\".join(dst_segments) + "*"]
    result = rctx.execute(
        cp_args,
        quiet = attr.quiet,
    )
    if result.return_code:
        msg = "Failed to copy file. '{}' exited with {}: \nSTDOUT:\n{}\nSTDERR:\n{}".format(" ".join(cp_args), result.return_code, result.stdout, result.stderr)
        fail(msg)

################################################################################
def _load_npmrc(priv, rctx, attr, npmrc_path, npmrc_label):
    contents = parse_npmrc(rctx.read(npmrc_path))
    if "registry" in contents:
        priv["default_registry"] = utils.to_registry_url(contents["registry"])

    (registries, auth) = helpers.get_npm_auth(contents, npmrc_path, rctx)
    priv["npm_registries"].update(registries)
    priv["npm_auth"].update(auth)

    if npmrc_label:
        # If it is a label, copy it as an input file
        _copy_input_file(
            priv,
            rctx,
            attr,
            npmrc_path,
            paths.join(npmrc_label.package, npmrc_label.name),
        )

################################################################################
def _load_home_npmrc(priv, rctx, attr):
    home_directory = repo_utils.get_home_directory(rctx)
    if not home_directory:
        # buildifier: disable=print
        print("""
WARNING: Cannot determine home directory in order to load home `.npmrc` file in `npm_translate_lock(name = "{rctx_name}")`.
""".format(rctx_name = priv["rctx_name"]))
        return

    home_npmrc_path = rctx.path("{}/{}".format(home_directory, NPM_RC_FILENAME))

    if home_npmrc_path.exists:
        _load_npmrc(priv, rctx, attr, home_npmrc_path, None)

################################################################################
def _yaml_to_json(rctx, yaml_path, is_windows):
    host_yq = Label("@yq_{}//:yq{}".format(repo_utils.platform(rctx), ".exe" if is_windows else ""))
    yq_args = [
        rctx.path(host_yq),
        yaml_path,
        "-o=json",
    ]
    result = rctx.execute(yq_args)
    if result.return_code:
        return None, "failed to parse {} with yq. '{}' exited with {}: \nSTDOUT:\n{}\nSTDERR:\n{}".format(" ".join(yq_args), yaml_path, result.return_code, result.stdout, result.stderr)

    # NB: yq will return the string "null" if the yaml file is empty
    if result.stdout != "null":
        return result.stdout, None

    return None, None

def _load_lockfile(priv, rctx, attr, pnpm_lock_path, is_windows):
    importers = {}
    packages = {}
    pnpm_patched_dependencies = {}
    lock_parse_err = None

    lockfile_content, lock_parse_err = _yaml_to_json(rctx, pnpm_lock_path, is_windows)
    if lock_parse_err == None:
        importers, packages, pnpm_patched_dependencies, lock_parse_err = pnpm.parse_pnpm_lock_json(
            lockfile_content,
            attr.no_dev,
            attr.no_optional,
        )

    calculate_transitive_closures(packages)

    priv["importers"] = importers
    priv["packages"] = packages
    priv["pnpm_patched_dependencies"] = pnpm_patched_dependencies

    if lock_parse_err != None:
        should_update = _should_update_pnpm_lock(priv)

        msg = """
{type}: pnpm-lock.yaml parse error {error}`.
""".format(type = "WARNING" if should_update else "ERROR", error = lock_parse_err)

        if should_update:
            # buildifier: disable=print
            print(msg)
        else:
            fail(msg)

################################################################################
def _has_workspaces(priv):
    importer_paths = priv["importers"].keys()
    return importer_paths and (len(importer_paths) > 1 or importer_paths[0] != ".")

################################################################################
def _should_update_pnpm_lock(priv):
    return priv["should_update_pnpm_lock"]

def _default_registry(priv):
    return priv["default_registry"]

def _importers(priv):
    return priv["importers"]

def _packages(priv):
    return priv["packages"]

def _pnpm_patched_dependencies(priv):
    return priv["pnpm_patched_dependencies"]

def _only_built_dependencies(priv):
    return _pnpm_settings(priv).get("onlyBuiltDependencies", None)

def _npm_registries(priv):
    return priv["npm_registries"]

def _npm_auth(priv):
    return priv["npm_auth"]

def _root_package(priv):
    return priv["root_package"]

def _pnpm_settings(priv):
    return priv["pnpm_settings"]

def _action_cache_label(priv):
    return priv["action_cache_label"]

def _pnpm_lock_label(priv):
    return priv["pnpm_lock_label"]

################################################################################
def _new(rctx_name, rctx, attr):
    should_update_pnpm_lock = attr.update_pnpm_lock
    if rctx.getenv(RULES_JS_DISABLE_UPDATE_PNPM_LOCK_ENV):
        # Force disabled update_pnpm_lock via environment variable. This is useful for some CI use cases.
        should_update_pnpm_lock = False

    priv = {
        "rctx_name": rctx_name,
        "repo_root": str(rctx.path("")),
        "src_root": str(rctx.path(Label("@@//:all"))).removesuffix("all"),
        "default_registry": utils.default_registry(),
        "external_repository_action_cache": None,
        "importers": {},
        "input_hashes": {},
        "npm_auth": {},
        "npm_registries": {},
        "packages": {},
        "root_package": attr.pnpm_lock.package if attr.pnpm_lock else "",
        "pnpm_settings": {},
        "pnpm_patched_dependencies": {},
        "should_update_pnpm_lock": should_update_pnpm_lock,
    }

    _init(priv, rctx, attr)

    return struct(
        repo_root = priv["repo_root"],
        action_cache_label = lambda: _action_cache_label(priv),
        pnpm_lock_label = lambda: _pnpm_lock_label(priv),
        should_update_pnpm_lock = lambda: _should_update_pnpm_lock(priv),
        default_registry = lambda: _default_registry(priv),
        importers = lambda: _importers(priv),
        packages = lambda: _packages(priv),
        pnpm_patched_dependencies = lambda: _pnpm_patched_dependencies(priv),
        only_built_dependencies = lambda: _only_built_dependencies(priv),
        npm_registries = lambda: _npm_registries(priv),
        npm_auth = lambda: _npm_auth(priv),
        root_package = lambda: _root_package(priv),
        set_input_hash = lambda label, value: _set_input_hash(priv, label, value),
        action_cache_miss = lambda: _action_cache_miss(priv, rctx),
        write_action_cache = lambda: _write_action_cache(priv, rctx),
    )

npm_translate_lock_state = struct(
    new = _new,
)
