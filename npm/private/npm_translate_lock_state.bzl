"""npm_translate_lock state management abstraction so main impl is easier to read
and maintain"""

load("@bazel_skylib//lib:paths.bzl", "paths")
load("@bazel_skylib//lib:dicts.bzl", "dicts")
load("@aspect_bazel_lib//lib:base64.bzl", "base64")
load("@aspect_bazel_lib//lib:repo_utils.bzl", "repo_utils")
load(":repository_label_store.bzl", "repository_label_store")
load(":npm_translate_lock_generate.bzl", "helpers")
load(":utils.bzl", "INTERNAL_ERROR_MSG", "utils")
load(":npmrc.bzl", "parse_npmrc")

NPM_RC_FILENAME = ".npmrc"
PACKAGE_JSON_FILENAME = "package.json"
PNPM_LOCK_FILENAME = "pnpm-lock.yaml"
PNPM_WORKSPACE_FILENAME = "pnpm-workspace.yaml"
PNPM_LOCK_ACTION_CACHE_PREFIX = "npm_translate_lock_"
DEFAULT_ROOT_PACKAGE = "."

################################################################################
def _init(priv, rctx, label_store):
    is_windows = repo_utils.is_windows(rctx)
    if is_windows and _should_update_pnpm_lock(priv):
        # buildifier: disable=print
        print("""
WARNING: `update_pnpm_lock` attribute in `npm_translate_lock(name = "{rctx_name}")` is not yet supported on Windows. This feature
         will be disabled for this build.
""".format(rctx_name = rctx.name))
        priv["should_update_pnpm_lock"] = False

    _validate_attrs(rctx.attr, is_windows)

    _init_external_repository_action_cache(priv, rctx)

    _init_common_labels(rctx, label_store)

    if _should_update_pnpm_lock(priv) or not rctx.attr.pnpm_lock:
        # labels only needed when updating or bootstrapping the pnpm lock file
        _init_pnpm_labels(label_store, rctx)

    if _should_update_pnpm_lock(priv):
        # labels only needed when updating the pnpm lock file
        _init_update_labels(priv, rctx, label_store)

    _init_link_workspace(priv, rctx, label_store)

    # parse the pnpm lock file incase since we need the importers list for additional init
    # TODO(windows): utils.exists is not yet support on Windows
    pnpm_lock_exists = is_windows or utils.exists(rctx, label_store.path("pnpm_lock"))
    if pnpm_lock_exists:
        _load_lockfile(priv, rctx, label_store)

    if _should_update_pnpm_lock(priv):
        _init_importer_labels(priv, label_store)

    _init_patch_labels(priv, rctx, label_store)

    _init_root_package(priv, rctx, label_store)

    _init_npmrc(priv, rctx, label_store)

    _copy_common_input_files(priv, rctx, label_store, pnpm_lock_exists)

    if _should_update_pnpm_lock(priv):
        _copy_update_input_files(priv, rctx, label_store)
        _copy_unspecified_input_files(priv, rctx, label_store)

def _reload_lockfile(priv, rctx, label_store):
    _load_lockfile(priv, rctx, label_store)

    if _should_update_pnpm_lock(priv):
        _init_importer_labels(priv, label_store)

    _init_root_package(priv, rctx, label_store)

    if _should_update_pnpm_lock(priv):
        _copy_unspecified_input_files(priv, rctx, label_store)

################################################################################
def _validate_attrs(attr, is_windows):
    if is_windows and not attr.pnpm_lock:
        fail("pnpm_lock must be set on Windows")
    if not attr.pnpm_lock and not attr.npm_package_lock and not attr.yarn_lock:
        fail("at least one of pnpm_lock, npm_package_lock or yarn_lock must be set")
    if attr.npm_package_lock and attr.yarn_lock:
        fail("only one of npm_package_lock or yarn_lock may be set")

################################################################################
def _init_common_labels(rctx, label_store):
    attr = rctx.attr

    # lock files
    if attr.pnpm_lock:
        label_store.add("pnpm_lock", attr.pnpm_lock, seed_root = True)
        label_store.add("lock", attr.pnpm_lock)
    else:
        if attr.npm_package_lock:
            label_store.add("lock", attr.npm_package_lock, seed_root = True)
        elif attr.yarn_lock:
            label_store.add("lock", attr.yarn_lock, seed_root = True)
        label_store.add_sibling("lock", "pnpm_lock", PNPM_LOCK_FILENAME)

    # .npmrc files
    if attr.npmrc:
        label_store.add("npmrc", attr.npmrc)
    label_store.add_sibling("lock", "sibling_npmrc", NPM_RC_FILENAME)

    # pnpm-workspace.yaml file
    label_store.add_sibling("lock", "pnpm_workspace", PNPM_WORKSPACE_FILENAME)

    # root package.json file
    label_store.add_sibling("lock", "package_json_root", PACKAGE_JSON_FILENAME)

################################################################################
def _init_pnpm_labels(label_store, rctx):
    # Note that we must reference the node binary under the platform-specific node
    # toolchain repository rather than under @nodejs_host since running rctx.path
    # (called outside this function) on the alias in the host repo fails under bzlmod.
    # It appears to fail because the platform-specific repository does not exist
    # unless we reference the label here.
    #
    # TODO: Try to understand this better and see if we can go back to using
    #  Label("@nodejs_host//:bin/node")
    label_store.add("host_node", Label("@nodejs_%s//:bin/node" % repo_utils.platform(rctx)))

    label_store.add("pnpm_entry", Label("@pnpm//:package/bin/pnpm.cjs"))

################################################################################
def _init_update_labels(priv, rctx, label_store):
    attr = rctx.attr

    action_cache_path = paths.join(
        priv["external_repository_action_cache"],
        PNPM_LOCK_ACTION_CACHE_PREFIX + base64.encode(utils.hash(helpers.to_apparent_repo_name(rctx.name) + utils.consistent_label_str(label_store.label("pnpm_lock")))),
    )
    label_store.add_root("action_cache", action_cache_path)
    for i, d in enumerate(attr.preupdate):
        label_store.add("preupdate_{}".format(i), d)
    for i, d in enumerate(attr.data):
        label_store.add("data_{}".format(i), d)

    if attr.npm_package_lock:
        label_store.add("npm_package_lock", attr.npm_package_lock, seed_root = True)
    if attr.yarn_lock:
        label_store.add("yarn_lock", attr.yarn_lock, seed_root = True)

################################################################################
def _init_patch_labels(priv, rctx, label_store):
    if rctx.attr.verify_patches:
        label_store.add("verify_patches", rctx.attr.verify_patches)

    patches = []

    # Add patches from `pnpm.patchedDependencies`
    root_package_json = _read_root_package_json(priv, rctx, label_store)
    for patch in root_package_json.get("pnpm", {}).get("patchedDependencies", {}).values():
        patches.append("//:%s" % patch)

    # Add patches in `patches` attribute
    for pkg_patches in rctx.attr.patches.values():
        patches.extend(pkg_patches)

    # Convert patch label strings to labels
    patches = [rctx.attr.pnpm_lock.relative(p) for p in patches]

    for i, d in enumerate(patches):
        label_store.add("patches_{}".format(i), d)

    priv["num_patches"] = len(patches)

################################################################################
def _init_importer_labels(priv, label_store):
    for i, p in enumerate(priv["importers"].keys()):
        label_store.add_sibling("lock", "package_json_{}".format(i), paths.join(p, PACKAGE_JSON_FILENAME))

################################################################################
def _init_link_workspace(priv, rctx, label_store):
    # initialize link_workspace either from pnpm_lock label or from override
    priv["link_workspace"] = rctx.attr.link_workspace if rctx.attr.link_workspace else label_store.label("pnpm_lock").workspace_name

################################################################################
def _init_external_repository_action_cache(priv, rctx):
    # initialize external_repository_action_cache
    priv["external_repository_action_cache"] = rctx.attr.external_repository_action_cache if rctx.attr.external_repository_action_cache else utils.default_external_repository_action_cache()

################################################################################
def _init_root_package(priv, rctx, label_store):
    pnpm_lock_label = label_store.label("pnpm_lock")

    # use the directory of the pnpm_lock file as the root_package unless overridden by the root_package attribute
    if rctx.attr.root_package == DEFAULT_ROOT_PACKAGE:
        # Don't allow a pnpm lock file that isn't in the root directory of a bazel package
        if paths.dirname(pnpm_lock_label.name):
            msg = "expected pnpm lock file {} to be at the root of a bazel package".format(pnpm_lock_label)
            fail(msg)
        priv["root_package"] = pnpm_lock_label.package
    else:
        # Don't allow root_package override if there are workspace importers; this is not supported as
        # paths to workspace packages will not work in this case
        if _has_workspaces(priv):
            fail("root_package cannot be overridden if there are pnpm workspace packages specified")
        priv["root_package"] = rctx.attr.root_package

################################################################################
def _init_npmrc(priv, rctx, label_store):
    if not label_store.has("npmrc"):
        # check for a .npmrc next to the pnpm-lock.yaml file
        _maybe_npmrc(priv, rctx, label_store, "sibling_npmrc")

    if label_store.has("npmrc"):
        _load_npmrc(priv, rctx, label_store.path("npmrc"))

    if rctx.attr.use_home_npmrc:
        _load_home_npmrc(priv, rctx)

################################################################################
def _maybe_npmrc(priv, rctx, label_store, key):
    is_windows = repo_utils.is_windows(rctx)
    if is_windows:
        # TODO(windows): utils.exists is not yet support on Windows
        return
    if utils.exists(rctx, label_store.path(key)):
        npmrc_label = label_store.label(key)

        # buildifier: disable=print
        print("""
WARNING: Implicitly using .npmrc file `{npmrc}`.
        Set the `npmrc` attribute of `npm_translate_lock(name = "{rctx_name}")` to `{npmrc}` suppress this warning.
""".format(npmrc = npmrc_label, rctx_name = rctx.name))
        _copy_input_file(priv, rctx, label_store, key)
        label_store.add("npmrc", npmrc_label)

################################################################################
# pnpm lock and npmrc files are needed so that the repository rule is re-run when those file change.
def _copy_common_input_files(priv, rctx, label_store, pnpm_lock_exists):
    keys = ["npmrc"]
    if pnpm_lock_exists:
        keys.append("pnpm_lock")
    for k in keys:
        if label_store.has(k):
            _copy_input_file(priv, rctx, label_store, k)

################################################################################
# pnpm workspace file and data files are needed incase we run `pnpm install --lockfile-only` or `pnpm import` if updating lock file.
def _copy_update_input_files(priv, rctx, label_store):
    keys = [
        "npm_package_lock",
        "yarn_lock",
    ]
    for i in range(len(rctx.attr.preupdate)):
        keys.append("preupdate_{}".format(i))
    for i in range(len(rctx.attr.data)):
        keys.append("data_{}".format(i))
    for k in keys:
        if label_store.has(k):
            _copy_input_file(priv, rctx, label_store, k)

################################################################################
# we can derive input files that should be specified but are not and copy these over; we warn the user when we do this
def _copy_unspecified_input_files(priv, rctx, label_store):
    pnpm_lock_label = label_store.label("pnpm_lock")

    # pnpm-workspace.yaml
    pnpm_workspace_key = "pnpm_workspace"
    if _has_workspaces(priv) and not _has_input_hash(priv, label_store.relative_path(pnpm_workspace_key)):
        # there are workspace packages so there must be a pnpm-workspace.yaml file
        # buildifier: disable=print
        print("""
WARNING: Implicitly using pnpm-workspace.yaml file `{pnpm_workspace}` since the `{pnpm_lock}` file contains workspace packages.
    Add `{pnpm_workspace}` to the 'data' attribute of `npm_translate_lock(name = "{rctx_name}")` to suppress this warning.
""".format(
            pnpm_lock = pnpm_lock_label,
            pnpm_workspace = label_store.label(pnpm_workspace_key),
            rctx_name = rctx.name,
        ))
        if not utils.exists(rctx, label_store.path(pnpm_workspace_key)):
            msg = "ERROR: expected `{path}` to exist since the `{pnpm_lock}` file contains workspace packages".format(
                path = label_store.path(pnpm_workspace_key),
                pnpm_lock = pnpm_lock_label,
            )
            fail(msg)
        _copy_input_file(priv, rctx, label_store, pnpm_workspace_key)

    # package.json files
    for i, _ in enumerate(priv["importers"].keys()):
        package_json_key = "package_json_{}".format(i)
        if not _has_input_hash(priv, label_store.relative_path(package_json_key)):
            # there is a workspace package here so there must be a package.json file
            # buildifier: disable=print
            print("""
WARNING: Implicitly using package.json file `{package_json}` since the `{pnpm_lock}` file contains this workspace package.
    Add '{package_json}' to the 'data' attribute of `npm_translate_lock(name = "{rctx_name}")` to suppress this warning.
""".format(
                pnpm_lock = pnpm_lock_label,
                package_json = label_store.label(package_json_key),
                rctx_name = rctx.name,
            ))
            if not utils.exists(rctx, label_store.path(package_json_key)):
                msg = "ERROR: expected {path} to exist since the `{pnpm_lock}` file contains this workspace package".format(
                    path = label_store.path(package_json_key),
                    pnpm_lock = pnpm_lock_label,
                )
                fail(msg)
            _copy_input_file(priv, rctx, label_store, package_json_key)

    # pnpm.patchedDependencies patch files
    root_package_json = _read_root_package_json(priv, rctx, label_store)
    pnpm_patches = root_package_json.get("pnpm", {}).get("patchedDependencies", {}).values()
    root_package_json_label = label_store.label("package_json_root")

    for i, _ in enumerate(pnpm_patches):
        # The key for pnpm.patchesDependencies patches are indexed before other patches and start at 0
        patch_key = "patches_{}".format(i)
        if not _has_input_hash(priv, label_store.relative_path(patch_key)):
            # buildifier: disable=print
            print("""
WARNING: Implicitly using patch file `{patch}` since the `{package_json}` file contains this patch in `pnpm.patchedDependencies`.
    Add '{patch}' to the 'data' attribute of `npm_translate_lock(name = "{rctx_name}")` to suppress this warning.
""".format(
                package_json = root_package_json_label,
                patch = label_store.label(patch_key),
                rctx_name = rctx.name,
            ))
            if not utils.exists(rctx, label_store.path(patch_key)):
                msg = "ERROR: expected {path} to exist since the `{package_json}` file contains this patch in `pnpm.patchedDependencies`.".format(
                    path = label_store.path(patch_key),
                    package_json = root_package_json_label,
                )
                fail(msg)
            _copy_input_file(priv, rctx, label_store, patch_key)

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
def _action_cache_miss(priv, rctx, label_store):
    action_cache_path = label_store.path("action_cache")
    if utils.exists(rctx, action_cache_path):
        input_hashes = parse_npmrc(rctx.read(action_cache_path))
        if utils.dicts_match(input_hashes, priv["input_hashes"]):
            # Calculated input hashes match saved input hashes; nothing to update
            return False
    return True

################################################################################
def _write_action_cache(priv, rctx, label_store):
    contents = [
        "# Input hashes for repository rule npm_translate_lock(name = \"{}\", pnpm_lock = \"{}\").".format(helpers.to_apparent_repo_name(rctx.name), utils.consistent_label_str(label_store.label("pnpm_lock"))),
        "# This file should be checked into version control along with the pnpm-lock.yaml file.",
    ]
    for key, value in priv["input_hashes"].items():
        contents.append("{}={}".format(key, value))
    rctx.file(
        label_store.repository_path("action_cache"),
        "\n".join(contents) + "\n",
    )
    utils.reverse_force_copy(
        rctx,
        label_store.label("action_cache"),
        label_store.path("action_cache"),
    )

################################################################################
def _copy_input_file(priv, rctx, label_store, key):
    if not label_store.has(key):
        fail("key not found '{}'".format(key))

    if _should_update_pnpm_lock(priv):
        # NB: rctx.read will convert binary files to text but that is acceptable for
        # the purposes of calculating a hash of the file
        _set_input_hash(
            priv,
            label_store.relative_path(key),
            utils.hash(rctx.read(label_store.path(key))),
        )

    # use rctx.download to copy the file instead of rctx.read + rctx.file so that
    # binary files are handled correctly
    rctx.download(
        output = label_store.repository_path(key),
        url = "file:" + label_store.path(key),
    )

################################################################################
def _load_npmrc(priv, rctx, npmrc_path):
    contents = parse_npmrc(rctx.read(npmrc_path))
    if "registry" in contents:
        priv["default_registry"] = utils.to_registry_url(contents["registry"])

    (registries, auth) = helpers.get_npm_auth(contents, npmrc_path, rctx.os.environ)
    priv["npm_registries"] = dicts.add(priv["npm_registries"], registries)
    priv["npm_auth"] = dicts.add(priv["npm_auth"], auth)

################################################################################
def _load_home_npmrc(priv, rctx):
    home_directory = utils.home_directory(rctx)
    if not home_directory:
        # buildifier: disable=print
        print("""
WARNING: Cannot determine home directory in order to load home `.npmrc` file in `npm_translate_lock(name = "{rctx_name}")`.
""".format(rctx_name = rctx.name))
        return

    home_npmrc_path = "{}/{}".format(home_directory, NPM_RC_FILENAME)

    # TODO(windows): utils.exists is not yet support on Windows
    is_windows = repo_utils.is_windows(rctx)
    if is_windows or utils.exists(rctx, home_npmrc_path):
        _load_npmrc(priv, rctx, home_npmrc_path)

################################################################################
def _load_lockfile(priv, rctx, label_store):
    importers, packages, patched_dependencies = utils.parse_pnpm_lock(rctx.read(label_store.path("pnpm_lock")))
    priv["importers"] = importers
    priv["packages"] = packages
    priv["patched_dependencies"] = patched_dependencies

################################################################################
def _has_workspaces(priv):
    importer_paths = priv["importers"].keys()
    return importer_paths and (len(importer_paths) > 1 or importer_paths[0] != ".")

################################################################################
def _read_root_package_json(priv, rctx, label_store):
    has_root_importer = "." in priv["importers"].keys()
    if not has_root_importer:
        # if there is no root importer that means there is no root package.json to read; pnpm allows
        # you to just have a pnpm-workspaces.yaml at the root and no package.json at that location
        return {}
    if "root_package_json" not in priv:
        root_package_json_path = label_store.path("package_json_root")
        priv["root_package_json"] = json.decode(rctx.read(root_package_json_path))
    return priv["root_package_json"]

################################################################################
def _should_update_pnpm_lock(priv):
    return priv["should_update_pnpm_lock"]

def _default_registry(priv):
    return priv["default_registry"]

def _link_workspace(priv):
    return priv["link_workspace"]

def _importers(priv):
    return priv["importers"]

def _packages(priv):
    return priv["packages"]

def _patched_dependencies(priv):
    return priv["patched_dependencies"]

def _num_patches(priv):
    return priv["num_patches"]

def _npm_registries(priv):
    return priv["npm_registries"]

def _npm_auth(priv):
    return priv["npm_auth"]

def _root_package(priv):
    return priv["root_package"]

################################################################################
def _new(rctx):
    label_store = repository_label_store.new(rctx.path)

    priv = {
        "default_registry": utils.default_registry(),
        "external_repository_action_cache": None,
        "importers": {},
        "input_hashes": {},
        "link_workspace": None,
        "npm_auth": {},
        "npm_registries": {},
        "packages": {},
        "root_package": None,
        "should_update_pnpm_lock": rctx.attr.update_pnpm_lock,
    }

    _init(priv, rctx, label_store)

    return struct(
        label_store = label_store,  # pass-through access to the label store
        should_update_pnpm_lock = lambda: _should_update_pnpm_lock(priv),
        default_registry = lambda: _default_registry(priv),
        link_workspace = lambda: _link_workspace(priv),
        importers = lambda: _importers(priv),
        packages = lambda: _packages(priv),
        patched_dependencies = lambda: _patched_dependencies(priv),
        npm_registries = lambda: _npm_registries(priv),
        npm_auth = lambda: _npm_auth(priv),
        num_patches = lambda: _num_patches(priv),
        root_package = lambda: _root_package(priv),
        set_input_hash = lambda label, value: _set_input_hash(priv, label, value),
        action_cache_miss = lambda: _action_cache_miss(priv, rctx, label_store),
        write_action_cache = lambda: _write_action_cache(priv, rctx, label_store),
        reload_lockfile = lambda: _reload_lockfile(priv, rctx, label_store),
    )

npm_translate_lock_state = struct(
    new = _new,
)
