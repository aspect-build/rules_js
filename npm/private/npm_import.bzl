"Repository rules for importing packages from npm"

load("@aspect_bazel_lib//lib:repo_utils.bzl", "patch", "repo_utils")
load("@bazel_skylib//lib:paths.bzl", "paths")
load("@bazel_skylib//lib:dicts.bzl", "dicts")
load(":utils.bzl", "utils")
load(":starlark_codegen_utils.bzl", "starlark_codegen_utils")

_LINK_JS_PACKAGE_TMPL = """load("@aspect_rules_js//npm:defs.bzl", _npm_package = "npm_package")
load("@aspect_rules_js//js:defs.bzl", _js_run_binary = "js_run_binary")
load("@aspect_rules_js//npm/private:npm_link_package_store_internal.bzl", _npm_link_package_store = "npm_link_package_store_internal")
load("@aspect_rules_js//npm/private:npm_link_package.bzl", _npm_link_package_direct = "npm_link_package_direct")
load("@bazel_skylib//lib:paths.bzl", _paths = "paths")

# buildifier: disable=unnamed-macro
def npm_link_package(
    name,
    direct = {direct_default},
    fail_if_no_link = True,
    visibility = ["//visibility:public"]):
    "Generated npm_link_package_store and npm_link_package_direct targets for npm package {package}@{version}"

    root_package = "{root_package}"

    link_packages = {link_packages}

    if link_packages and direct != None:
        fail("direct attribute cannot be specified when link_packages are set")

    is_root = native.package_name() == root_package
    is_direct = (direct == True) or (direct == None and native.package_name() in link_packages)

    if fail_if_no_link and not is_root and not is_direct:
        msg = "Nothing to link in bazel package '%s' for npm package npm package {package}@{version}. This is neither the root package nor a link package of this package." % native.package_name()
        fail(msg)

    if is_root:
        # link the virtual store when linking at the root

        lifecycle_build_target = {lifecycle_build_target}

        deps = {deps}

        lc_deps = {lc_deps}

        ref_deps = {ref_deps}

        # reference target used to avoid circular deps
        _npm_link_package_store(
            name = "{store_link_prefix}{bazel_name}__ref",
            package = "{package}",
            version = "{version}",
            tags = ["manual"],
        )

        # post-lifecycle target with reference deps for use in terminal target with transitive closure
        _npm_link_package_store(
            name = "{store_link_prefix}{bazel_name}__pkg",
            src = "{store_link_prefix}{bazel_name}__pkg_lc" if lifecycle_build_target else "{npm_package_target}",
            package = "{package}",
            version = "{version}",
            deps = ref_deps,
            tags = ["manual"],
        )

        # virtual store target with transitive closure of all node package dependencies
        _npm_link_package_store(
            name = "{store_link_prefix}{bazel_name}",
            src = None if {transitive_closure_pattern} else "{npm_package_target}",
            package = "{package}",
            version = "{version}",
            deps = deps,
            visibility = visibility,
            tags = ["manual"],
        )

        # filegroup target that provides a single file which is
        # package directory for use in $(execpath) and $(rootpath)
        native.filegroup(
            name = "{store_link_prefix}{bazel_name}{dir_suffix}",
            srcs = [":{store_link_prefix}{bazel_name}"],
            output_group = "{package_directory_output_group}",
            visibility = visibility,
            tags = ["manual"],
        )

        if lifecycle_build_target:
            # pre-lifecycle target with reference deps for use terminal pre-lifecycle target
            _npm_link_package_store(
                name = "{store_link_prefix}{bazel_name}__pkg_pre_lc_lite",
                package = "{package}",
                version = "{version}",
                deps = ref_deps,
                tags = ["manual"],
            )

            # terminal pre-lifecycle target for use in lifecycle build target below
            _npm_link_package_store(
                name = "{store_link_prefix}{bazel_name}__pkg_pre_lc",
                package = "{package}",
                version = "{version}",
                deps = lc_deps,
                tags = ["manual"],
            )

            # lifecycle build action
            _js_run_binary(
                name = "{lifecycle_target_name}",
                srcs = [
                    "{npm_package_target_lc}",
                    ":{store_link_prefix}{bazel_name}__pkg_pre_lc"
                ],
                # js_run_binary runs in the output dir; must add "../../../" because paths are relative to the exec root
                args = [
                    "{package}",
                    "../../../$(execpath {npm_package_target_lc})",
                    "../../../$(@D)",
                ],
                copy_srcs_to_bin = False,
                tool = "@aspect_rules_js//npm/private/lifecycle:lifecycle-hooks",
                output_dir = True,
                tags = ["manual"],
            )

            # post-lifecycle npm_package
            _npm_package(
                name = "{store_link_prefix}{bazel_name}__pkg_lc",
                src = ":{lifecycle_target_name}",
                package = "{package}",
                version = "{version}",
                tags = ["manual"],
            )

    direct_target = None
    if is_direct:
        # terminal target for direct dependencies
        _npm_link_package_direct(
            name = name,
            src = "//{root_package}:{store_link_prefix}{bazel_name}",
            visibility = visibility,
            tags = ["manual"],
        )
        direct_target = ":{{}}".format(name)

        # filegroup target that provides a single file which is
        # package directory for use in $(execpath) and $(rootpath)
        native.filegroup(
            name = "{{}}/dir".format(name),
            srcs = [direct_target],
            output_group = "{package_directory_output_group}",
            visibility = visibility,
            tags = ["manual"],
        )

    return direct_target
"""

_BIN_MACRO_TMPL = """
def {bin_name}(name, **kwargs):
    _directory_path(
        name = "%s__entry_point" % name,
        directory = "@{link_workspace}//{root_package}:{store_link_prefix}{bazel_name}{dir_suffix}",
        path = "{bin_path}",
    )
    _js_binary(
        name = "%s__js_binary" % name,
        entry_point = ":%s__entry_point" % name,
        data = ["@{link_workspace}//{root_package}:{store_link_prefix}{bazel_name}"],
    )
    _js_run_binary(
        name = name,
        tool = ":%s__js_binary" % name,
        **kwargs
    )

def {bin_name}_test(name, **kwargs):
    _directory_path(
        name = "%s__entry_point" % name,
        directory = "@{link_workspace}//{root_package}:{store_link_prefix}{bazel_name}{dir_suffix}",
        path = "{bin_path}",
    )
    _js_test(
        name = name,
        entry_point = ":%s__entry_point" % name,
        data = kwargs.pop("data", []) + ["@{link_workspace}//{root_package}:{store_link_prefix}{bazel_name}"],
        **kwargs
    )

def {bin_name}_binary(name, **kwargs):
    _directory_path(
        name = "%s__entry_point" % name,
        directory = "@{link_workspace}//{root_package}:{store_link_prefix}{bazel_name}{dir_suffix}",
        path = "{bin_path}",
    )
    _js_binary(
        name = name,
        entry_point = ":%s__entry_point" % name,
        data = kwargs.pop("data", []) + ["@{link_workspace}//{root_package}:{store_link_prefix}{bazel_name}"],
        **kwargs
    )
"""

_JS_PACKAGE_TMPL = """
_npm_package(
    name = "source_directory",
    src = ":{extract_to_dirname}",
    provide_source_directory = True,
    package = "{package}",
    version = "{version}",
    visibility = ["//visibility:public"],
)

_npm_package(
    name = "pkg",
    src = ":{extract_to_dirname}",
    package = "{package}",
    version = "{version}",
    visibility = ["//visibility:public"],
)
"""

_TARBALL_FILENAME = "package.tgz"
_EXTRACT_TO_DIRNAME = "package"
_DEFS_BZL_FILENAME = "defs.bzl"
_PACKAGE_JSON_BZL_FILENAME = "package_json.bzl"

def _impl(rctx):
    download_url = rctx.attr.url if rctx.attr.url else "https://registry.npmjs.org/{0}/-/{1}-{2}.tgz".format(
        rctx.attr.package,
        # scoped packages contain a slash in the name, which doesn't appear in the later part of the URL
        rctx.attr.package.rsplit("/", 1)[-1],
        utils.strip_peer_dep_version(rctx.attr.version),
    )

    rctx.download(
        output = _TARBALL_FILENAME,
        url = download_url,
        integrity = rctx.attr.integrity,
    )

    mkdir_args = ["mkdir", "-p", _EXTRACT_TO_DIRNAME] if not repo_utils.is_windows(rctx) else ["cmd", "/c", "if not exist {extract_to_dirname} (mkdir {extract_to_dirname})".format(_EXTRACT_TO_DIRNAME = _EXTRACT_TO_DIRNAME.replace("/", "\\"))]
    result = rctx.execute(mkdir_args)
    if result.return_code:
        msg = "mkdir %s failed: \nSTDOUT:\n%s\nSTDERR:\n%s" % (_EXTRACT_TO_DIRNAME, result.stdout, result.stderr)
        fail(msg)

    # npm packages are always published with one top-level directory inside the tarball, tho the name is not predictable
    # so we use tar here which takes a --strip-components N argument instead of rctx.download_and_extract
    untar_args = ["tar", "-xf", _TARBALL_FILENAME, "--strip-components", str(1), "-C", _EXTRACT_TO_DIRNAME]

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

    # apply patches to the extracted package before reading the package.json incase
    # the patch targets the package.json itself
    patch(rctx, patch_args = rctx.attr.patch_args, patch_directory = _EXTRACT_TO_DIRNAME)

    pkg_json_path = paths.join(_EXTRACT_TO_DIRNAME, "package.json")

    pkg_json = json.decode(rctx.read(pkg_json_path))

    bins = _get_bin_entries(pkg_json, rctx.attr.package)

    generated_by_lines = _make_generated_by_lines(rctx.attr.package, rctx.attr.version)

    bazel_name = utils.bazel_name(rctx.attr.package, rctx.attr.version)

    root_package_json_bzl = False

    if bins:
        for link_package in rctx.attr.link_packages:
            bin_bzl = generated_by_lines + [
                """load("@aspect_bazel_lib//lib:directory_path.bzl", _directory_path = "directory_path")""",
                """load("@aspect_rules_js//js:defs.bzl", _js_binary = "js_binary", _js_run_binary = "js_run_binary", _js_test = "js_test")""",
            ]
            for name in bins:
                bin_bzl.append(
                    _BIN_MACRO_TMPL.format(
                        bazel_name = bazel_name,
                        bin_name = _sanitize_bin_name(name),
                        bin_path = bins[name],
                        dir_suffix = utils.dir_suffix,
                        root_package = rctx.attr.root_package,
                        link_workspace = rctx.attr.link_workspace,
                        store_link_prefix = utils.store_link_prefix,
                    ),
                )

            bin_struct_fields = [
                "{name} = {name}, {name}_test = {name}_test, {name}_binary = {name}_binary".format(name = _sanitize_bin_name(name))
                for name in bins
            ]
            bin_bzl.append("bin = struct(%s)\n" % ",\n".join(bin_struct_fields))

            if link_package == "":
                root_package_json_bzl = True
            else:
                rctx.file(paths.normalize(paths.join(link_package, "BUILD.bazel")), "\n".join(generated_by_lines + [
                    "exports_files({})".format(starlark_codegen_utils.to_list_attr([_PACKAGE_JSON_BZL_FILENAME])),
                ]))
            rctx.file(paths.normalize(paths.join(link_package, _PACKAGE_JSON_BZL_FILENAME)), "\n".join(bin_bzl))

    if rctx.attr.run_lifecycle_hooks:
        _inject_run_lifecycle_hooks(rctx, pkg_json_path)

    if rctx.attr.custom_postinstall:
        _inject_custom_postinstall(rctx, pkg_json_path, rctx.attr.custom_postinstall)

    build_file = generated_by_lines + [
        """load("@aspect_rules_js//npm/private:npm_package_internal.bzl", _npm_package = "npm_package_internal")""",
    ]

    build_file.append(_JS_PACKAGE_TMPL.format(
        extract_to_dirname = _EXTRACT_TO_DIRNAME,
        package = rctx.attr.package,
        version = rctx.attr.version,
    ))

    if root_package_json_bzl:
        build_file.append("exports_files(%s)" % starlark_codegen_utils.to_list_attr([_PACKAGE_JSON_BZL_FILENAME]))

    rctx.file("BUILD.bazel", "\n".join(build_file))

def _sanitize_bin_name(name):
    """ Sanitize a package name so we can use it in starlark function names """
    return name.replace("-", "_")

def _impl_links(rctx):
    ref_deps = []
    lc_deps = []
    deps = []

    for (dep_name, dep_version) in rctx.attr.deps.items():
        ref_deps.append("{store_link_prefix}{bazel_name}__ref".format(
            bazel_name = utils.bazel_name(dep_name, dep_version),
            store_link_prefix = utils.store_link_prefix,
        ))

    transitive_closure_pattern = len(rctx.attr.transitive_closure) > 0
    if transitive_closure_pattern:
        # transitive closure deps pattern is used for breaking circular deps;
        # this pattern is used to break circular dependencies between 3rd
        # party npm deps; it is not recommended for 1st party deps
        for (dep_name, dep_versions) in rctx.attr.transitive_closure.items():
            for dep_version in dep_versions:
                if dep_name == rctx.attr.package and dep_version == rctx.attr.version:
                    # special case for lifecycle transitive closure deps; do not depend on
                    # the __pkg of this package as that will be the output directory
                    # of the lifecycle action
                    lc_deps.append("{store_link_prefix}{bazel_name}__pkg_pre_lc_lite".format(
                        bazel_name = utils.bazel_name(dep_name, dep_version),
                        store_link_prefix = utils.store_link_prefix,
                    ))
                else:
                    lc_deps.append("{store_link_prefix}{bazel_name}__pkg".format(
                        bazel_name = utils.bazel_name(dep_name, dep_version),
                        store_link_prefix = utils.store_link_prefix,
                    ))
                deps.append("{store_link_prefix}{bazel_name}__pkg".format(
                    bazel_name = utils.bazel_name(dep_name, dep_version),
                    store_link_prefix = utils.store_link_prefix,
                ))
    else:
        for (dep_name, dep_version) in rctx.attr.deps.items():
            lc_deps.append("{store_link_prefix}{bazel_name}".format(
                bazel_name = utils.bazel_name(dep_name, dep_version),
                store_link_prefix = utils.store_link_prefix,
            ))
            deps.append("{store_link_prefix}{bazel_name}".format(
                bazel_name = utils.bazel_name(dep_name, dep_version),
                store_link_prefix = utils.store_link_prefix,
            ))

    virtual_store_name = utils.virtual_store_name(rctx.attr.package, rctx.attr.version)

    # "node_modules/{virtual_store_root}/{virtual_store_name}/node_modules/{package}"
    lifecycle_target_name = paths.join("node_modules", utils.virtual_store_root, virtual_store_name, "node_modules", rctx.attr.package)

    # strip _links post-fix to get the repository name of the npm sources
    npm_import_sources_repo_name = rctx.name[:-len(utils.links_suffix)]
    if npm_import_sources_repo_name.startswith("aspect_rules_js.npm."):
        npm_import_sources_repo_name = npm_import_sources_repo_name[len("aspect_rules_js.npm."):]

    npm_package_target = "@{}//:source_directory".format(npm_import_sources_repo_name)
    npm_package_target_lc = "@{}//:pkg".format(npm_import_sources_repo_name)

    npm_link_package_bzl = [_LINK_JS_PACKAGE_TMPL.format(
        bazel_name = utils.bazel_name(rctx.attr.package, rctx.attr.version),
        deps = starlark_codegen_utils.to_list_attr(deps, 1),
        dir_suffix = utils.dir_suffix,
        direct_default = "None" if rctx.attr.link_packages else "True",
        extract_to_dirname = _EXTRACT_TO_DIRNAME,
        npm_package_target = npm_package_target,
        npm_package_target_lc = npm_package_target_lc,
        lc_deps = starlark_codegen_utils.to_list_attr(lc_deps, 1),
        lifecycle_build_target = str(rctx.attr.lifecycle_build_target),
        lifecycle_target_name = lifecycle_target_name,
        npm_link_package_bzl = "@%s//:%s" % (rctx.name, _DEFS_BZL_FILENAME),
        link_packages = rctx.attr.link_packages,
        package = rctx.attr.package,
        package_directory_output_group = utils.package_directory_output_group,
        rctx_name = rctx.name,
        ref_deps = starlark_codegen_utils.to_list_attr(ref_deps, 1),
        root_package = rctx.attr.root_package,
        store_link_prefix = utils.store_link_prefix,
        transitive_closure_pattern = str(transitive_closure_pattern),
        version = rctx.attr.version,
        virtual_store_root = utils.virtual_store_root,
    )]

    generated_by_lines = _make_generated_by_lines(rctx.attr.package, rctx.attr.version)

    rctx.file(_DEFS_BZL_FILENAME, "\n".join(generated_by_lines + npm_link_package_bzl))

    rctx.file("BUILD.bazel", "exports_files(%s)" % starlark_codegen_utils.to_list_attr([_DEFS_BZL_FILENAME]))

_COMMON_ATTRS = {
    "package": attr.string(mandatory = True),
    "version": attr.string(mandatory = True),
    "root_package": attr.string(),
    "link_packages": attr.string_list(),
}

_ATTRS_LINKS = dicts.add(_COMMON_ATTRS, {
    "deps": attr.string_dict(),
    "transitive_closure": attr.string_list_dict(),
    "lifecycle_build_target": attr.bool(),
})

_ATTRS = dicts.add(_COMMON_ATTRS, {
    "integrity": attr.string(),
    "patch_args": attr.string_list(default = ["-p0"]),
    "patches": attr.label_list(),
    "run_lifecycle_hooks": attr.bool(),
    "custom_postinstall": attr.string(),
    "link_workspace": attr.string(),
    "url": attr.string(),
})

def _inject_run_lifecycle_hooks(rctx, pkg_json_path):
    package_json = json.decode(rctx.read(pkg_json_path))
    package_json.setdefault("scripts", {})["_rules_js_run_lifecycle_hooks"] = "1"

    # TODO: The order of fields in package.json is not preserved making it harder to read
    rctx.file(pkg_json_path, json.encode_indent(package_json, indent = "  "))

def _inject_custom_postinstall(rctx, pkg_json_path, custom_postinstall):
    package_json = json.decode(rctx.read(pkg_json_path))
    package_json.setdefault("scripts", {})["_rules_js_custom_postinstall"] = custom_postinstall

    # TODO: The order of fields in package.json is not preserved making it harder to read
    rctx.file(pkg_json_path, json.encode_indent(package_json, indent = "  "))

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
