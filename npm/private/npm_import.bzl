"Repository rules for importing packages from npm"

load("@aspect_bazel_lib//lib:repo_utils.bzl", "patch", "repo_utils")
load("@aspect_bazel_lib//lib:utils.bzl", "is_bazel_6_or_greater")
load("@bazel_skylib//lib:paths.bzl", "paths")
load("@bazel_skylib//lib:dicts.bzl", "dicts")
load(
    "@bazel_tools//tools/build_defs/repo:git_worker.bzl",
    _git_add_origin = "add_origin",
    _git_clean = "clean",
    _git_fetch = "fetch",
    _git_init = "init",
    _git_reset = "reset",
)
load(":utils.bzl", "utils")
load(":npm_translate_lock.bzl", "DEFAULT_REGISTRY")
load(":starlark_codegen_utils.bzl", "starlark_codegen_utils")

_LINK_JS_PACKAGE_TMPL = """load("@aspect_rules_js//js:defs.bzl", _js_run_binary = "js_run_binary")
load("@aspect_rules_js//npm/private:npm_package_store_internal.bzl", _npm_package_store = "npm_package_store_internal")
load("@aspect_rules_js//npm/private:npm_link_package_store.bzl", _npm_link_package_store = "npm_link_package_store")
load("@aspect_rules_js//npm/private:npm_package_internal.bzl", _npm_package_internal = "npm_package_internal")
load("@aspect_rules_js//npm/private:utils.bzl", _utils = "utils")
load("@bazel_skylib//lib:paths.bzl", _paths = "paths")

def npm_imported_package_store(
    name,
    visibility = ["//visibility:public"]):
    "Generated npm_package_store targets for npm package {package}@{version}"

    root_package = "{root_package}"
    is_root = native.package_name() == root_package
    if not is_root:
        msg = "No store links in bazel package '%s' for npm package npm package {package}@{version}. This is neither the root package nor a link package of this package." % native.package_name()
        fail(msg)
    if not name.endswith("/{package}"):
        msg = "name must end with one of '/{package}' when linking the store in package '{package}'; recommended value is 'node_modules/{package}'"
        fail(msg)
    link_root_name = name[:-len("/{package}")]

    deps = {deps}
    lc_deps = {lc_deps}
    ref_deps = {ref_deps}

    has_lifecycle_build_target = {has_lifecycle_build_target}
    store_target_name = "{virtual_store_root}/{{}}/{virtual_store_name}".format(link_root_name)

    # reference target used to avoid circular deps
    _npm_package_store(
        name = "{{}}/ref".format(store_target_name),
        package = "{package}",
        version = "{version}",
        tags = ["manual"],
        use_declare_symlink = select({{
            "@aspect_rules_js//js/private:experimental_allow_unresolved_symlinks": True,
            "//conditions:default": False,
        }}),
    )

    # post-lifecycle target with reference deps for use in terminal target with transitive closure
    _npm_package_store(
        name = "{{}}/pkg".format(store_target_name),
        src = "{{}}/pkg_lc".format(store_target_name) if has_lifecycle_build_target else "{npm_package_target}",
        package = "{package}",
        version = "{version}",
        deps = ref_deps,
        tags = ["manual"],
        use_declare_symlink = select({{
            "@aspect_rules_js//js/private:experimental_allow_unresolved_symlinks": True,
            "//conditions:default": False,
        }}),
    )

    # virtual store target with transitive closure of all npm package dependencies
    _npm_package_store(
        name = store_target_name,
        src = None if {transitive_closure_pattern} else "{npm_package_target}",
        package = "{package}",
        version = "{version}",
        deps = deps,
        visibility = visibility,
        tags = ["manual"],
        use_declare_symlink = select({{
            "@aspect_rules_js//js/private:experimental_allow_unresolved_symlinks": True,
            "//conditions:default": False,
        }}),
    )

    # filegroup target that provides a single file which is
    # package directory for use in $(execpath) and $(rootpath)
    native.filegroup(
        name = "{{}}/dir".format(store_target_name),
        srcs = [":{{}}".format(store_target_name)],
        output_group = _utils.package_directory_output_group,
        visibility = visibility,
        tags = ["manual"],
    )

    if has_lifecycle_build_target:
        # pre-lifecycle target with reference deps for use terminal pre-lifecycle target
        _npm_package_store(
            name = "{{}}/pkg_pre_lc_lite".format(store_target_name),
            package = "{package}",
            version = "{version}",
            deps = ref_deps,
            tags = ["manual"],
            use_declare_symlink = select({{
                "@aspect_rules_js//js/private:experimental_allow_unresolved_symlinks": True,
                "//conditions:default": False,
            }}),
        )

        # terminal pre-lifecycle target for use in lifecycle build target below
        _npm_package_store(
            name = "{{}}/pkg_pre_lc".format(store_target_name),
            package = "{package}",
            version = "{version}",
            deps = lc_deps,
            tags = ["manual"],
            use_declare_symlink = select({{
                "@aspect_rules_js//js/private:experimental_allow_unresolved_symlinks": True,
                "//conditions:default": False,
            }}),
        )

        # lifecycle build action
        _js_run_binary(
            name = "{{}}/lc".format(store_target_name),
            srcs = [
                "{npm_package_target_lc}",
                ":{{}}/pkg_pre_lc".format(store_target_name)
            ],
            # js_run_binary runs in the output dir; must add "../../../" because paths are relative to the exec root
            args = [
                "{package}",
                "../../../$(execpath {npm_package_target_lc})",
                "../../../$(@D)",
            ],
            copy_srcs_to_bin = False,
            tool = "@aspect_rules_js//npm/private/lifecycle:lifecycle-hooks",
            out_dirs = ["{lifecycle_output_dir}"],
            tags = ["manual"],
            execution_requirements = {lifecycle_hooks_execution_requirements},
            mnemonic = "NpmLifecycleHook",
            progress_message = "Running lifecycle hooks on npm package {package}@{version}",
            env = {lifecycle_hooks_env},
        )

        # post-lifecycle npm_package
        _npm_package_internal(
            name = "{{}}/pkg_lc".format(store_target_name),
            src = ":{{}}/lc".format(store_target_name),
            package = "{package}",
            version = "{version}",
            tags = ["manual"],
        )

def npm_link_imported_package_store(
    name,
    visibility = ["//visibility:public"]):
    "Generated npm_package_store and npm_link_package_store targets for npm package {package}@{version}"

    link_packages = {link_packages}
    if native.package_name() in link_packages:
        link_aliases = link_packages[native.package_name()]
    else:
        link_aliases = ["{package}"]

    link_alias = None
    for _link_alias in link_aliases:
        if name.endswith("/{{}}".format(_link_alias)):
            # longest match wins
            if not link_alias or len(_link_alias) > len(link_alias):
                link_alias = _link_alias
    if not link_alias:
        msg = "name must end with one of '/{{{{ {{link_aliases_comma_separated}} }}}}' when called from package '{package}'; recommended value(s) are 'node_modules/{{{{ {{link_aliases_comma_separated}} }}}}'".format(link_aliases_comma_separated = ", ".join(link_aliases))
        fail(msg)

    link_root_name = name[:-len("/{{}}".format(link_alias))]
    store_target_name = "{virtual_store_root}/{{}}/{virtual_store_name}".format(link_root_name)

    # terminal package store target to link
    _npm_link_package_store(
        name = name,
        package = link_alias,
        src = "//{root_package}:{{}}".format(store_target_name),
        visibility = visibility,
        tags = ["manual"],
        use_declare_symlink = select({{
            "@aspect_rules_js//js/private:experimental_allow_unresolved_symlinks": True,
            "//conditions:default": False,
        }}),{maybe_bins}
    )

    # filegroup target that provides a single file which is
    # package directory for use in $(execpath) and $(rootpath)
    native.filegroup(
        name = "{{}}/dir".format(name),
        srcs = [":{{}}".format(name)],
        output_group = _utils.package_directory_output_group,
        visibility = visibility,
        tags = ["manual"],
    )

    return ":{{}}".format(name)

def npm_link_imported_package(
    name = "node_modules",
    link = {link_default},
    fail_if_no_link = True,
    visibility = ["//visibility:public"]):
    "Generated npm_package_store and npm_link_package_store targets for npm package {package}@{version}"

    root_package = "{root_package}"
    link_packages = {link_packages}

    if link_packages and link != None:
        fail("link attribute cannot be specified when link_packages are set")

    is_link = (link == True) or (link == None and native.package_name() in link_packages)
    is_root = native.package_name() == root_package

    if fail_if_no_link and not is_root and not link:
        msg = "Nothing to link in bazel package '%s' for npm package npm package {package}@{version}. This is neither the root package nor a link package of this package." % native.package_name()
        fail(msg)

    link_targets = []
    scoped_targets = {{}}

    if is_link:
        link_aliases = []
        if native.package_name() in link_packages:
            link_aliases = link_packages[native.package_name()]
        if not link_aliases:
            link_aliases = ["{package}"]
        for link_alias in link_aliases:
            link_target_name = "{{}}/{{}}".format(name, link_alias)
            npm_link_imported_package_store(
                name = link_target_name,
                visibility = visibility,
            )
            link_targets.append(":{{}}".format(link_target_name))
            if len(link_alias.split("/", 1)) > 1:
                link_scope = link_alias.split("/", 1)[0]
                if link_scope not in scoped_targets:
                    scoped_targets[link_scope] = []
                scoped_targets[link_scope].append(link_target_name)

    if is_root:
        npm_imported_package_store(
            "{{}}/{package}".format(name),
            visibility = visibility,
        )

    return (link_targets, scoped_targets)
"""

_BIN_MACRO_TMPL = """
def _{bin_name}_internal(name, link_root_name, **kwargs):
    store_target_name = "{virtual_store_root}/{{}}/{virtual_store_name}".format(link_root_name)
    _directory_path(
        name = "%s__entry_point" % name,
        directory = "@{link_workspace}//{root_package}:{{}}/dir".format(store_target_name),
        path = "{bin_path}",
        tags = ["manual"],
    )
    _js_binary(
        name = "%s__js_binary" % name,
        entry_point = ":%s__entry_point" % name,
        data = ["@{link_workspace}//{root_package}:{{}}".format(store_target_name)],
        include_npm = kwargs.pop("include_npm", False),
        tags = ["manual"],
    )
    _js_run_binary(
        name = name,
        tool = ":%s__js_binary" % name,
        mnemonic = kwargs.pop("mnemonic", "{bin_mnemonic}"),
        **kwargs
    )

def _{bin_name}_test_internal(name, link_root_name, **kwargs):
    store_target_name = "{virtual_store_root}/{{}}/{virtual_store_name}".format(link_root_name)
    _directory_path(
        name = "%s__entry_point" % name,
        directory = "@{link_workspace}//{root_package}:{{}}/dir".format(store_target_name),
        path = "{bin_path}",
        tags = ["manual"],
    )
    _js_test(
        name = name,
        entry_point = ":%s__entry_point" % name,
        data = kwargs.pop("data", []) + ["@{link_workspace}//{root_package}:{{}}".format(store_target_name)],
        **kwargs
    )

def _{bin_name}_binary_internal(name, link_root_name, **kwargs):
    store_target_name = "{virtual_store_root}/{{}}/{virtual_store_name}".format(link_root_name)
    _directory_path(
        name = "%s__entry_point" % name,
        directory = "@{link_workspace}//{root_package}:{{}}/dir".format(store_target_name),
        path = "{bin_path}",
        tags = ["manual"],
    )
    _js_binary(
        name = name,
        entry_point = ":%s__entry_point" % name,
        data = kwargs.pop("data", []) + ["@{link_workspace}//{root_package}:{{}}".format(store_target_name)],
        **kwargs
    )

def {bin_name}(name, **kwargs):
    _{bin_name}_internal(name, "node_modules", **kwargs)

def {bin_name}_test(name, **kwargs):
    _{bin_name}_test_internal(name, "node_modules", **kwargs)

def {bin_name}_binary(name, **kwargs):
    _{bin_name}_binary_internal(name, "node_modules", **kwargs)
"""

_JS_PACKAGE_TMPL = """
_npm_package_internal(
    name = "source_directory",
    src = ":{extract_to_dirname}",
    package = "{package}",
    version = "{version}",
    visibility = ["//visibility:public"],
)

_npm_package_internal(
    name = "pkg",
    src = ":{extract_to_dirname}",
    package = "{package}",
    version = "{version}",
    visibility = ["//visibility:public"],
)
"""

_BZL_LIBRARY_TMPL = \
    """
bzl_library(
    name = "{name}_bzl_library",
    srcs = ["{src}"],
    deps = [
        "@aspect_bazel_lib//lib:directory_path",
        "@aspect_rules_js//js:defs",
    ],
    visibility = ["//visibility:public"],
)"""

_TARBALL_FILENAME = "package.tgz"
_EXTRACT_TO_DIRNAME = "package"
_DEFS_BZL_FILENAME = "defs.bzl"
_PACKAGE_JSON_BZL_FILENAME = "package_json.bzl"

def _fetch_git_repository(rctx):
    if not rctx.attr.commit:
        fail("commit required if url is a git repository")

    # Adapted from git_repo helper function used by git_repository in @bazel_tools//tools/build_defs/repo:git_worker.bzl:
    # https://github.com/bazelbuild/bazel/blob/5bdd2b2ff8d6be4ecbffe82d975983129d459782/tools/build_defs/repo/git_worker.bzl#L34
    git_repo = struct(
        directory = rctx.path(_EXTRACT_TO_DIRNAME),
        shallow = "--depth=1",
        reset_ref = rctx.attr.commit,
        fetch_ref = rctx.attr.commit,
        remote = str(rctx.attr.url),
    )
    rctx.report_progress("Cloning %s of %s" % (git_repo.reset_ref, git_repo.remote))
    _git_init(rctx, git_repo)
    _git_add_origin(rctx, git_repo, rctx.attr.url)
    _git_fetch(rctx, git_repo)
    _git_reset(rctx, git_repo)
    _git_clean(rctx, git_repo)

def _download_and_extract_archive(rctx):
    download_url = rctx.attr.url if rctx.attr.url else utils.npm_registry_download_url(rctx.attr.package, rctx.attr.version, {}, DEFAULT_REGISTRY)

    auth = {}

    if rctx.attr.npm_auth and rctx.attr.npm_auth_username and rctx.attr.npm_auth_password:
        fail("please ensuer either 'npm_auth', or 'npm_auth_username' and 'npm_auth_password'")

    if rctx.attr.npm_auth_username or rctx.attr.npm_auth_password:
        if not rctx.attr.npm_auth_username:
            fail("'npm_auth_password' was provided without 'npm_auth_username'")
        if not rctx.attr.npm_auth_password:
            fail("'npm_auth_username' was provided without 'npm_auth_password'")

    if rctx.attr.npm_auth:
        auth = {
            download_url: {
                "type": "pattern",
                "pattern": "Bearer <password>",
                "password": rctx.attr.npm_auth,
            },
        }
    elif rctx.attr.npm_auth_username and rctx.attr.npm_auth_password:
        auth = {
            download_url: {
                "type": "basic",
                "login": rctx.attr.npm_auth_username,
                "password": rctx.attr.npm_auth_password,
            },
        }

    rctx.download(
        output = _TARBALL_FILENAME,
        url = download_url,
        integrity = rctx.attr.integrity,
        auth = auth,
    )

    mkdir_args = ["mkdir", "-p", _EXTRACT_TO_DIRNAME] if not repo_utils.is_windows(rctx) else ["cmd", "/c", "if not exist {extract_to_dirname} (mkdir {extract_to_dirname})".format(extract_to_dirname = _EXTRACT_TO_DIRNAME.replace("/", "\\"))]
    result = rctx.execute(mkdir_args)
    if result.return_code:
        msg = "mkdir %s failed: \nSTDOUT:\n%s\nSTDERR:\n%s" % (_EXTRACT_TO_DIRNAME, result.stdout, result.stderr)
        fail(msg)

    # npm packages are always published with one top-level directory inside the tarball, tho the name is not predictable
    # so we use tar here which takes a --strip-components N argument instead of rctx.download_and_extract
    untar_args = ["tar", "-xf", _TARBALL_FILENAME, "--strip-components", str(1), "-C", _EXTRACT_TO_DIRNAME, "--no-same-owner", "--no-same-permissions"]

    if repo_utils.is_linux(rctx):
        # Some packages have directory permissions missing the executable bit, which prevents GNU tar from
        # extracting files into the directory. Delay permission restoration for directories until all files
        # have been extracted. We assume that any linux platform is using GNU tar and has this flag available.
        untar_args.append("--delay-directory-restore")

    result = rctx.execute(untar_args)
    if result.return_code:
        msg = "tar %s failed: \nSTDOUT:\n%s\nSTDERR:\n%s" % (_EXTRACT_TO_DIRNAME, result.stdout, result.stderr)
        fail(msg)

    if not repo_utils.is_windows(rctx):
        # Some packages have directory permissions missing executable which
        # make the directories not listable. Fix these cases in order to be able
        # to execute the copy action. https://stackoverflow.com/a/14634721
        chmod_args = ["chmod", "-R", "a+X", _EXTRACT_TO_DIRNAME]
        result = rctx.execute(chmod_args)
        if result.return_code:
            msg = "chmod %s failed: \nSTDOUT:\n%s\nSTDERR:\n%s" % (_EXTRACT_TO_DIRNAME, result.stdout, result.stderr)
            fail(msg)

def _impl(rctx):
    if utils.is_git_repository_url(rctx.attr.url):
        _fetch_git_repository(rctx)
    else:
        _download_and_extract_archive(rctx)

    # apply patches to the extracted package before reading the package.json incase
    # the patch targets the package.json itself
    patch(rctx, patch_args = rctx.attr.patch_args, patch_directory = _EXTRACT_TO_DIRNAME)

    pkg_json_path = paths.join(_EXTRACT_TO_DIRNAME, "package.json")

    pkg_json = json.decode(rctx.read(pkg_json_path))

    bins = _get_bin_entries(pkg_json, rctx.attr.package)

    generated_by_lines = _make_generated_by_lines(rctx.attr.package, rctx.attr.version)

    bazel_name = utils.bazel_name(rctx.attr.package, rctx.attr.version)

    rctx_files = {
        "BUILD.bazel": generated_by_lines + [
            """load("@aspect_rules_js//npm/private:npm_package_internal.bzl", _npm_package_internal = "npm_package_internal")""",
            """load("@bazel_skylib//:bzl_library.bzl", "bzl_library")""",
        ],
    }

    rctx_files["BUILD.bazel"].append(_JS_PACKAGE_TMPL.format(
        extract_to_dirname = _EXTRACT_TO_DIRNAME,
        package = rctx.attr.package,
        version = rctx.attr.version,
    ))

    if rctx.attr.extra_build_content:
        rctx_files["BUILD.bazel"].append("\n" + rctx.attr.extra_build_content)

    if bins:
        virtual_store_name = utils.virtual_store_name(rctx.attr.package, rctx.attr.version)
        package_name_no_scope = rctx.attr.package.rsplit("/", 1)[-1]

        for link_package in rctx.attr.link_packages.keys():
            bin_bzl = generated_by_lines + [
                """load("@aspect_bazel_lib//lib:directory_path.bzl", _directory_path = "directory_path")""",
                """load("@aspect_rules_js//js:defs.bzl", _js_binary = "js_binary", _js_run_binary = "js_run_binary", _js_test = "js_test")""",
            ]
            for name in bins:
                bin_name = _sanitize_bin_name(name)
                bin_bzl.append(
                    _BIN_MACRO_TMPL.format(
                        bazel_name = bazel_name,
                        bin_name = bin_name,
                        bin_mnemonic = _mnemonic_for_bin(bin_name),
                        bin_path = bins[name],
                        link_workspace = rctx.attr.link_workspace,
                        package = rctx.attr.package,
                        root_package = rctx.attr.root_package,
                        version = rctx.attr.version,
                        virtual_store_name = virtual_store_name,
                        virtual_store_root = utils.virtual_store_root,
                    ),
                )

            bin_struct_fields = []
            for bin_name in bins:
                sanitized_bin_name = _sanitize_bin_name(bin_name)
                bin_struct_fields.append(
                    """        {bin_name} = lambda name, **kwargs: _{bin_name}_internal(name, link_root_name = link_root_name, **kwargs),
        {bin_name}_test = lambda name, **kwargs: _{bin_name}_test_internal(name, link_root_name = link_root_name, **kwargs),
        {bin_name}_binary = lambda name, **kwargs: _{bin_name}_binary_internal(name, link_root_name = link_root_name, **kwargs),""".format(
                        bin_name = sanitized_bin_name,
                    ),
                )

            bin_bzl.append("""def bin_factory(link_root_name):
    # bind link_root_name using lambdas
    return struct(
{bin_struct_fields}
    )

bin = bin_factory("node_modules")
""".format(
                package = rctx.attr.package,
                version = rctx.attr.version,
                bin_struct_fields = "\n".join(bin_struct_fields),
            ))

            rctx_files[paths.join(link_package, _PACKAGE_JSON_BZL_FILENAME)] = bin_bzl

            build_file = paths.join(link_package, "BUILD.bazel")
            if build_file not in rctx_files:
                rctx_files[build_file] = generated_by_lines[:]
            if rctx.attr.generate_bzl_library_targets:
                rctx_files[build_file].append("""load("@bazel_skylib//:bzl_library.bzl", "bzl_library")""")
                rctx_files[build_file].append(_BZL_LIBRARY_TMPL.format(
                    name = link_package.split("/")[-1] or package_name_no_scope,
                    src = _PACKAGE_JSON_BZL_FILENAME,
                ))
            rctx_files[build_file].append("""exports_files(["{}"])""".format(_PACKAGE_JSON_BZL_FILENAME))

    rules_js_metadata = {}
    if rctx.attr.run_lifecycle_hooks:
        rules_js_metadata["run_lifecycle_hooks"] = "1"
    if rctx.attr.custom_postinstall:
        rules_js_metadata["scripts"] = {}
        rules_js_metadata["scripts"]["custom_postinstall"] = rctx.attr.custom_postinstall
    rules_js_json_path = paths.join(_EXTRACT_TO_DIRNAME, "aspect_rules_js_metadata.json")
    rctx.file(rules_js_json_path, json.encode_indent(rules_js_metadata, indent = "  "))

    for filename, contents in rctx_files.items():
        rctx.file(filename, "\n".join(contents))

def _sanitize_bin_name(name):
    """ Sanitize a package name so we can use it in starlark function names """
    return name.replace("-", "_")

def _mnemonic_for_bin(bin_name):
    """ Sanitize a bin name so we can use it as a mnemonic.

    Creates a CamelCase version of the bin name.
    """
    bin_words = bin_name.split("_")
    return "".join([word.capitalize() for word in bin_words])

def _impl_links(rctx):
    ref_deps = {}
    lc_deps = {}
    deps = {}

    bzlmod_supported = is_bazel_6_or_greater()

    for (dep_name, dep_version) in rctx.attr.deps.items():
        if dep_version.startswith("link:") or dep_version.startswith("file:"):
            dep_store_target = """"//{root_package}:{virtual_store_root}/{{}}/{virtual_store_name}".format(link_root_name)""".format(
                root_package = rctx.attr.root_package,
                virtual_store_name = utils.virtual_store_name(dep_name, "0.0.0"),
                virtual_store_root = utils.virtual_store_root,
            )
        else:
            if dep_version.startswith("/"):
                store_package, store_version = utils.parse_pnpm_name(dep_version[1:])
            else:
                store_package = dep_name
                store_version = dep_version
            dep_store_target = """":{virtual_store_root}/{{}}/{virtual_store_name}/ref".format(link_root_name)""".format(
                virtual_store_name = utils.virtual_store_name(store_package, store_version),
                virtual_store_root = utils.virtual_store_root,
            )
        ref_deps[dep_store_target] = ref_deps[dep_store_target] + [dep_name] if dep_store_target in ref_deps else [dep_name]

    transitive_closure_pattern = len(rctx.attr.transitive_closure) > 0
    if transitive_closure_pattern:
        # transitive closure deps pattern is used for breaking circular deps;
        # this pattern is used to break circular dependencies between 3rd
        # party npm deps; it is not recommended for 1st party deps
        for (dep_name, dep_versions) in rctx.attr.transitive_closure.items():
            for dep_version in dep_versions:
                if dep_version.startswith("link:") or dep_version.startswith("file:"):
                    dep_store_target = """"//{root_package}:{virtual_store_root}/{{}}/{virtual_store_name}".format(link_root_name)""".format(
                        root_package = rctx.attr.root_package,
                        virtual_store_name = utils.virtual_store_name(dep_name, "0.0.0"),
                        virtual_store_root = utils.virtual_store_root,
                    )
                    lc_deps[dep_store_target] = lc_deps[dep_store_target] + [dep_name] if dep_store_target in lc_deps else [dep_name]
                    deps[dep_store_target] = deps[dep_store_target] + [dep_name] if dep_store_target in deps else [dep_name]
                else:
                    if dep_version.startswith("/"):
                        store_package, store_version = utils.parse_pnpm_name(dep_version[1:])
                    else:
                        store_package = dep_name
                        store_version = dep_version
                    dep_store_target_pkg = """":{virtual_store_root}/{{}}/{virtual_store_name}/pkg".format(link_root_name)""".format(
                        virtual_store_name = utils.virtual_store_name(store_package, store_version),
                        virtual_store_root = utils.virtual_store_root,
                    )
                    if dep_name == rctx.attr.package and dep_version == rctx.attr.version:
                        dep_store_target_pkg_pre_lc_lite = """":{virtual_store_root}/{{}}/{virtual_store_name}/pkg_pre_lc_lite".format(link_root_name)""".format(
                            virtual_store_name = utils.virtual_store_name(store_package, store_version),
                            virtual_store_root = utils.virtual_store_root,
                        )

                        # special case for lifecycle transitive closure deps; do not depend on
                        # the __pkg of this package as that will be the output directory
                        # of the lifecycle action
                        lc_deps[dep_store_target_pkg_pre_lc_lite] = lc_deps[dep_store_target_pkg_pre_lc_lite] + [dep_name] if dep_store_target_pkg_pre_lc_lite in lc_deps else [dep_name]
                    else:
                        lc_deps[dep_store_target_pkg] = lc_deps[dep_store_target_pkg] + [dep_name] if dep_store_target_pkg in lc_deps else [dep_name]
                    deps[dep_store_target_pkg] = deps[dep_store_target_pkg] + [dep_name] if dep_store_target_pkg in deps else [dep_name]
    else:
        for (dep_name, dep_version) in rctx.attr.deps.items():
            if dep_version.startswith("link:") or dep_version.startswith("file:"):
                dep_store_target = """"//{root_package}:{virtual_store_root}/{{}}/{virtual_store_name}".format(link_root_name)""".format(
                    root_package = rctx.attr.root_package,
                    virtual_store_name = utils.virtual_store_name(dep_name, "0.0.0"),
                    virtual_store_root = utils.virtual_store_root,
                )
            else:
                if dep_version.startswith("/"):
                    store_package, store_version = utils.parse_pnpm_name(dep_version[1:])
                else:
                    store_package = dep_name
                    store_version = dep_version
                dep_store_target = """":{virtual_store_root}/{{}}/{virtual_store_name}/pkg".format(link_root_name)""".format(
                    virtual_store_name = utils.virtual_store_name(store_package, store_version),
                    virtual_store_root = utils.virtual_store_root,
                )
            lc_deps[dep_store_target] = lc_deps[dep_store_target] + [dep_name] if dep_store_target in lc_deps else [dep_name]
            deps[dep_store_target] = deps[dep_store_target] + [dep_name] if dep_store_target in deps else [dep_name]

    virtual_store_name = utils.virtual_store_name(rctx.attr.package, rctx.attr.version)

    # "node_modules/{virtual_store_root}/{virtual_store_name}/node_modules/{package}"
    lifecycle_output_dir = paths.join("node_modules", utils.virtual_store_root, virtual_store_name, "node_modules", rctx.attr.package)

    # strip _links post-fix to get the repository name of the npm sources
    npm_import_sources_repo_name = rctx.name[:-len(utils.links_repo_suffix)]
    if npm_import_sources_repo_name.startswith("aspect_rules_js.npm."):
        npm_import_sources_repo_name = npm_import_sources_repo_name[len("aspect_rules_js.npm."):]

    if rctx.attr.npm_translate_lock_repo:
        npm_package_target = "@{}//:{}_source_directory".format(
            rctx.attr.npm_translate_lock_repo,
            npm_import_sources_repo_name,
        )
    else:
        npm_package_target = "{}{}//:source_directory".format(
            "@@" if bzlmod_supported else "@",
            npm_import_sources_repo_name,
        )
    npm_package_target_lc = "@{}//:pkg".format(npm_import_sources_repo_name)

    link_packages = {}
    for package, link_aliases in rctx.attr.link_packages.items():
        link_packages[package] = link_aliases or [rctx.attr.package]

    # collapse link aliases lists into comma separated strings
    for dep in deps.keys():
        deps[dep] = ",".join(deps[dep])
    for dep in lc_deps.keys():
        lc_deps[dep] = ",".join(lc_deps[dep])
    for dep in ref_deps.keys():
        ref_deps[dep] = ",".join(ref_deps[dep])

    lifecycle_hooks_env = {}
    for env in rctx.attr.lifecycle_hooks_env:
        key_value = env.split("=", 1)
        if len(key_value) == 2:
            lifecycle_hooks_env[key_value[0]] = key_value[1]
        else:
            msg = "lifecycle_hooks_env contains invalid key value pair '%s', required '=' separator not found" % env
            fail(msg)

    lifecycle_hooks_execution_requirements = {}
    for ec in rctx.attr.lifecycle_hooks_execution_requirements:
        lifecycle_hooks_execution_requirements[ec] = "1"
    if rctx.attr.lifecycle_hooks_no_sandbox and "no-sandbox" not in lifecycle_hooks_execution_requirements:
        lifecycle_hooks_execution_requirements["no-sandbox"] = "1"

    maybe_bins = ("""
        bins = %s,""" % starlark_codegen_utils.to_dict_attr(rctx.attr.bins, 3)) if len(rctx.attr.bins) > 0 else ""

    virtual_store_name = utils.virtual_store_name(rctx.attr.package, rctx.attr.version)

    npm_link_package_bzl = [_LINK_JS_PACKAGE_TMPL.format(
        deps = starlark_codegen_utils.to_dict_attr(deps, 2, quote_key = False),
        link_default = "None" if rctx.attr.link_packages else "True",
        extract_to_dirname = _EXTRACT_TO_DIRNAME,
        npm_package_target = npm_package_target,
        npm_package_target_lc = npm_package_target_lc,
        lc_deps = starlark_codegen_utils.to_dict_attr(lc_deps, 2, quote_key = False),
        has_lifecycle_build_target = str(rctx.attr.lifecycle_build_target),
        lifecycle_hooks_execution_requirements = starlark_codegen_utils.to_dict_attr(lifecycle_hooks_execution_requirements),
        lifecycle_hooks_env = starlark_codegen_utils.to_dict_attr(lifecycle_hooks_env),
        lifecycle_output_dir = lifecycle_output_dir,
        npm_link_package_bzl = "@%s//:%s" % (rctx.name, _DEFS_BZL_FILENAME),
        link_packages = starlark_codegen_utils.to_dict_attr(link_packages, 1, quote_value = False),
        package = rctx.attr.package,
        rctx_name = rctx.name,
        ref_deps = starlark_codegen_utils.to_dict_attr(ref_deps, 2, quote_key = False),
        root_package = rctx.attr.root_package,
        transitive_closure_pattern = str(transitive_closure_pattern),
        version = rctx.attr.version,
        virtual_store_name = virtual_store_name,
        virtual_store_root = utils.virtual_store_root,
        maybe_bins = maybe_bins,
    )]

    generated_by_lines = _make_generated_by_lines(rctx.attr.package, rctx.attr.version)

    rctx.file(_DEFS_BZL_FILENAME, "\n".join(generated_by_lines + npm_link_package_bzl))

    rctx.file("BUILD.bazel", "exports_files(%s)" % starlark_codegen_utils.to_list_attr([_DEFS_BZL_FILENAME]))

_COMMON_ATTRS = {
    "package": attr.string(mandatory = True),
    "version": attr.string(mandatory = True),
    "root_package": attr.string(),
    "link_packages": attr.string_list_dict(),
}

_ATTRS_LINKS = dicts.add(_COMMON_ATTRS, {
    "bins": attr.string_dict(),
    "deps": attr.string_dict(),
    "transitive_closure": attr.string_list_dict(),
    "lifecycle_build_target": attr.bool(),
    "lifecycle_hooks_env": attr.string_list(),
    "lifecycle_hooks_execution_requirements": attr.string_list(),
    "lifecycle_hooks_no_sandbox": attr.bool(default = True),
    "npm_translate_lock_repo": attr.string(),
})

_ATTRS = dicts.add(_COMMON_ATTRS, {
    "extra_build_content": attr.string(),
    "integrity": attr.string(),
    "patch_args": attr.string_list(default = ["-p0"]),
    "patches": attr.label_list(),
    "run_lifecycle_hooks": attr.bool(),
    "custom_postinstall": attr.string(),
    "link_workspace": attr.string(),
    "url": attr.string(),
    "commit": attr.string(),
    "npm_auth": attr.string(),
    "npm_auth_username": attr.string(),
    "npm_auth_password": attr.string(),
    "generate_bzl_library_targets": attr.bool(),
})

def _get_bin_entries(pkg_json, package):
    # https://docs.npmjs.com/cli/v7/configuring-npm/package-json#bin
    bin = pkg_json.get("bin", {})
    if type(bin) != "dict":
        bin = {paths.basename(package): bin}
    return bin

def _make_generated_by_lines(package, version):
    return [
        "\"@generated by @aspect_rules_js//npm/private:npm_import.bzl for npm package {package}@{version}\"".format(
            package = package,
            version = version,
        ),
        "",  # empty line after bzl docstring since buildifier expects this if this file is vendored in
    ]

npm_import_links = struct(
    implementation = _impl_links,
    attrs = _ATTRS_LINKS,
)

npm_import = struct(
    implementation = _impl,
    attrs = _ATTRS,
)
