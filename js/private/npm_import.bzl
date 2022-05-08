"Repository rules for importing packages from npm"

load("@aspect_bazel_lib//lib:repo_utils.bzl", "patch", "repo_utils")
load("@bazel_skylib//lib:paths.bzl", "paths")
load("@bazel_skylib//lib:dicts.bzl", "dicts")
load(":pnpm_utils.bzl", "pnpm_utils")
load(":starlark_codegen_utils.bzl", "starlark_codegen_utils")
load(":repo_toolchains.bzl", "yq_path")

_LINK_JS_PACKAGE_TMPL = """load("@aspect_rules_js//js:defs.bzl", _js_package = "js_package")
load("@aspect_rules_js//js:run_js_binary.bzl", _run_js_binary = "run_js_binary")
load("@aspect_rules_js//js/private:link_js_package_store_internal.bzl", _link_js_package_store = "link_js_package_store_internal")
load("@aspect_rules_js//js/private:link_js_package.bzl", _link_js_package_direct = "link_js_package_direct")
load("@aspect_rules_js//js/private:pnpm_utils.bzl", _pnpm_utils = "pnpm_utils")
load("@bazel_skylib//lib:paths.bzl", _paths = "paths")

# buildifier: disable=unnamed-macro
def link_js_package(fail_if_no_link = False):
    "Generated link_js_package_store and link_js_package_direct targets for npm package {package}@{version}"

    is_root = native.package_name() == "{root_path}"

    if is_root:
        # link the virtual store if we are linking in the root package

        lifecycle_build_target = {lifecycle_build_target}

        deps = {deps}

        lc_deps = {lc_deps}

        ref_deps = {ref_deps}

        # reference target used to avoid circular deps
        _link_js_package_store(
            name = "{namespace}{bazel_name}__ref",
            package = "{package}",
            version = "{version}",
        )

        # post-lifecycle target with reference deps for use in terminal target with transitive closure
        _link_js_package_store(
            name = "{namespace}{bazel_name}__pkg",
            src = "{namespace}{bazel_name}__jsp" if lifecycle_build_target else "{js_package_target}",
            package = "{package}",
            version = "{version}",
            deps = ref_deps,
        )

        # virtual store target with transitive closure of all node package dependencies
        _link_js_package_store(
            name = "{namespace}{bazel_name}{store_postfix}",
            src = None if {transitive_closure_pattern} else "{js_package_target}",
            package = "{package}",
            version = "{version}",
            deps = deps,
            visibility = ["//visibility:public"],
        )

        if lifecycle_build_target:
            # pre-lifecycle target with reference deps for use terminal pre-lifecycle target
            _link_js_package_store(
                name = "{namespace}{bazel_name}__pkg_lite",
                package = "{package}",
                version = "{version}",
                deps = ref_deps,
            )

            # terminal pre-lifecycle target for use in lifecycle build target below
            _link_js_package_store(
                name = "{namespace}{bazel_name}__pkg_lc",
                package = "{package}",
                version = "{version}",
                deps = lc_deps,
            )

            # lifecycle build action
            _run_js_binary(
                name = "{lifecycle_target_name}",
                srcs = [
                    "{js_package_target}",
                    ":{namespace}{bazel_name}__pkg_lc"
                ],
                # run_js_binary runs in the output dir; must add "../../../" because paths are relative to the exec root
                args = [
                    "{package}",
                    "../../../$(execpath {js_package_target})",
                    "../../../$(@D)",
                ],
                copy_srcs_to_bin = False,
                tool = "@aspect_rules_js//js/private/lifecycle:lifecycle-hooks",
                output_dir = True,
            )

            # post-lifecycle js_package
            _js_package(
                name = "{namespace}{bazel_name}__jsp",
                src = ":{lifecycle_target_name}",
                package = "{package}",
                version = "{version}",
            )

    # link direct deps
    is_direct = False
    for link_path in {link_paths}:
        link_package_path = _paths.normalize(_paths.join("{root_path}", link_path))
        if link_package_path == ".":
            link_package_path = ""
        if link_package_path == native.package_name():
            is_direct = True

            # terminal target for direct dependencies
            _link_js_package_direct(
                name = "{namespace}{bazel_name}",
                src = "//{root_path}:{namespace}{bazel_name}{store_postfix}",
                visibility = ["//visibility:public"],
            )

            # filegroup target that provides a single file which is
            # package directory for use in $(execpath) and $(rootpath)
            native.filegroup(
                name = "{namespace}{bazel_name}{dir_postfix}",
                srcs = [":{namespace}{bazel_name}"],
                output_group = "{package_directory_output_group}",
                visibility = ["//visibility:public"],
            )

            native.alias(
                name = "{namespace}{alias}",
                actual = ":{namespace}{bazel_name}",
                visibility = ["//visibility:public"],
            )

            native.alias(
                name = "{namespace}{alias}{dir_postfix}",
                actual = ":{namespace}{bazel_name}{dir_postfix}",
                visibility = ["//visibility:public"],
            )

    if fail_if_no_link and not is_root and not is_direct:
        msg = "Nothing to link in bazel package '%s' for npm package npm package {package}@{version}. This is neither the root_path of this workspace nor a link_path of this package." % native.package_name()
        fail(msg)
"""

_BIN_MACRO_TMPL = """
def {bin_name}(name, **kwargs):
    _directory_path(
        name = "%s__entry_point" % name,
        directory = ":{namespace}{bazel_name}{dir_postfix}",
        path = "{bin_path}",
    )
    _js_binary(
        name = "%s__js_binary" % name,
        entry_point = ":%s__entry_point" % name,
    )
    _run_js_binary(
        name = name,
        tool = ":%s__js_binary" % name,
        **kwargs
    )

def {bin_name}_test(name, **kwargs):
    _directory_path(
        name = "%s__entry_point" % name,
        directory = ":{namespace}{bazel_name}{dir_postfix}",
        path = "{bin_path}",
    )
    _js_test(
        name = name,
        entry_point = ":%s__entry_point" % name,
        **kwargs
    )

def {bin_name}_binary(name, **kwargs):
    _directory_path(
        name = "%s__entry_point" % name,
        directory = ":{namespace}{bazel_name}{dir_postfix}",
        path = "{bin_path}",
    )
    _js_binary(
        name = name,
        entry_point = ":%s__entry_point" % name,
        **kwargs
    )
"""

_JS_PACKAGE_TMPL = """
_js_package(
    name = "jsp",
    src = ":{extract_to_dirname}",
    package = "{package}",
    version = "{version}",
    visibility = ["//visibility:public"],
)
"""

_TARBALL_FILENAME = "package.tgz"
_EXTRACT_TO_DIRNAME = "package"
_LINK_JS_PACKAGE_BZL_FILENAME = "link_js_package.bzl"

def _impl(rctx):
    numeric_version = pnpm_utils.strip_peer_dep_version(rctx.attr.version)

    rctx.download(
        output = _TARBALL_FILENAME,
        url = "https://registry.npmjs.org/{0}/-/{1}-{2}.tgz".format(
            rctx.attr.package,
            # scoped packages contain a slash in the name, which doesn't appear in the later part of the URL
            rctx.attr.package.split("/")[-1],
            numeric_version,
        ),
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
    result = rctx.execute(untar_args)
    if result.return_code:
        msg = "tar %s failed: \nSTDOUT:\n%s\nSTDERR:\n%s" % (_EXTRACT_TO_DIRNAME, result.stdout, result.stderr)
        fail(msg)

    pkg_json_path = paths.join(_EXTRACT_TO_DIRNAME, "package.json")

    pkg_json = json.decode(rctx.read(pkg_json_path))

    bins = _get_bin_entries(pkg_json, rctx.attr.package)

    generated_by_lines = _make_generated_by_lines(rctx.attr.package, rctx.attr.version)

    bazel_name = pnpm_utils.bazel_name(rctx.attr.package, rctx.attr.version)

    bin_bzl_file = None
    if bins:
        bin_bzl_file = "package_json.bzl"
        bin_bzl = generated_by_lines + [
            """load("@aspect_bazel_lib//lib:directory_path.bzl", _directory_path = "directory_path")""",
            """load("@aspect_rules_js//js:defs.bzl", _js_binary = "js_binary", _js_test = "js_test")""",
            """load("@aspect_rules_js//js:run_js_binary.bzl", _run_js_binary = "run_js_binary")""",
        ]
        for name in bins:
            bin_bzl.append(
                _BIN_MACRO_TMPL.format(
                    bazel_name = bazel_name,
                    bin_name = name,
                    bin_path = bins[name],
                    dir_postfix = pnpm_utils.dir_postfix,
                    namespace = pnpm_utils.js_package_target_namespace,
                ),
            )

        rctx.file(bin_bzl_file, "\n".join(bin_bzl + [
            "bin = struct(%s)\n" % ",\n".join([
                "{name} = {name}, {name}_test = {name}_test, {name}_binary = {name}_binary".format(name = name)
                for name in bins
            ]),
        ]))

    if rctx.attr.run_lifecycle_hooks:
        _inject_run_lifecycle_hooks(rctx, pkg_json_path)

    if rctx.attr.custom_postinstall:
        _inject_custom_postinstall(rctx, pkg_json_path, rctx.attr.custom_postinstall)

    # Apply patches to the extracted package
    patch(rctx, patch_args = rctx.attr.patch_args, patch_directory = _EXTRACT_TO_DIRNAME)

    build_file = generated_by_lines + [
        """load("@aspect_rules_js//js:defs.bzl", _js_package = "js_package")""",
    ]

    build_file.append(_JS_PACKAGE_TMPL.format(
        extract_to_dirname = _EXTRACT_TO_DIRNAME,
        package = rctx.attr.package,
        version = rctx.attr.version,
    ))

    if bin_bzl_file:
        build_file.append("exports_files(%s)" % starlark_codegen_utils.to_list_attr([bin_bzl_file]))

    rctx.file("BUILD.bazel", "\n".join(build_file))

def _impl_links(rctx):
    ref_deps = []
    lc_deps = []
    deps = []

    for (dep_name, dep_version) in rctx.attr.deps.items():
        ref_deps.append("{namespace}{bazel_name}__ref".format(
            namespace = pnpm_utils.js_package_target_namespace,
            bazel_name = pnpm_utils.bazel_name(dep_name, dep_version),
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
                    lc_deps.append("{namespace}{bazel_name}__pkg_lite".format(
                        namespace = pnpm_utils.js_package_target_namespace,
                        bazel_name = pnpm_utils.bazel_name(dep_name, dep_version),
                    ))
                else:
                    lc_deps.append("{namespace}{bazel_name}__pkg".format(
                        namespace = pnpm_utils.js_package_target_namespace,
                        bazel_name = pnpm_utils.bazel_name(dep_name, dep_version),
                    ))
                deps.append("{namespace}{bazel_name}__pkg".format(
                    namespace = pnpm_utils.js_package_target_namespace,
                    bazel_name = pnpm_utils.bazel_name(dep_name, dep_version),
                ))
    else:
        for (dep_name, dep_version) in rctx.attr.deps.items():
            lc_deps.append("{namespace}{bazel_name}{store_postfix}".format(
                namespace = pnpm_utils.js_package_target_namespace,
                bazel_name = pnpm_utils.bazel_name(dep_name, dep_version),
                store_postfix = pnpm_utils.store_postfix,
            ))
            deps.append("{namespace}{bazel_name}{store_postfix}".format(
                namespace = pnpm_utils.js_package_target_namespace,
                bazel_name = pnpm_utils.bazel_name(dep_name, dep_version),
                store_postfix = pnpm_utils.store_postfix,
            ))

    virtual_store_name = pnpm_utils.virtual_store_name(rctx.attr.package, rctx.attr.version)

    # "node_modules/{virtual_store_root}/{virtual_store_name}/node_modules/{package}"
    lifecycle_target_name = paths.join("node_modules", pnpm_utils.virtual_store_root, virtual_store_name, "node_modules", rctx.attr.package)

    # strip _links post-fix to get the repository name of the npm sources
    npm_import_sources_repo_name = rctx.name[:-len(pnpm_utils.links_postfix)]

    js_package_target = "@{}//:jsp".format(npm_import_sources_repo_name)

    link_js_package_bzl = [_LINK_JS_PACKAGE_TMPL.format(
        alias = pnpm_utils.bazel_name(rctx.attr.package),
        bazel_name = pnpm_utils.bazel_name(rctx.attr.package, rctx.attr.version),
        deps = starlark_codegen_utils.to_list_attr(deps, 1),
        dir_postfix = pnpm_utils.dir_postfix,
        extract_to_dirname = _EXTRACT_TO_DIRNAME,
        js_package_target = js_package_target,
        lc_deps = starlark_codegen_utils.to_list_attr(lc_deps, 1),
        lifecycle_build_target = str(rctx.attr.lifecycle_build_target),
        lifecycle_target_name = lifecycle_target_name,
        link_js_package_bzl = "@%s//:%s" % (rctx.name, _LINK_JS_PACKAGE_BZL_FILENAME),
        link_paths = rctx.attr.link_paths,
        namespace = pnpm_utils.js_package_target_namespace,
        package = rctx.attr.package,
        package_directory_output_group = pnpm_utils.package_directory_output_group,
        rctx_name = rctx.name,
        ref_deps = starlark_codegen_utils.to_list_attr(ref_deps, 1),
        root_path = rctx.attr.root_path,
        store_postfix = pnpm_utils.store_postfix,
        transitive_closure_pattern = str(transitive_closure_pattern),
        version = rctx.attr.version,
        virtual_store_root = pnpm_utils.virtual_store_root,
    )]

    generated_by_lines = _make_generated_by_lines(rctx.attr.package, rctx.attr.version)

    rctx.file(_LINK_JS_PACKAGE_BZL_FILENAME, "\n".join(generated_by_lines + link_js_package_bzl))

    rctx.file("BUILD.bazel", "exports_files(%s)" % starlark_codegen_utils.to_list_attr([_LINK_JS_PACKAGE_BZL_FILENAME]))

_COMMON_ATTRS = {
    "package": attr.string(mandatory = True),
    "version": attr.string(mandatory = True),
}

_ATTRS_LINKS = dicts.add(_COMMON_ATTRS, {
    "deps": attr.string_dict(),
    "transitive_closure": attr.string_list_dict(),
    "root_path": attr.string(),
    "link_paths": attr.string_list(),
    "lifecycle_build_target": attr.bool(),
})

_ATTRS = dicts.add(_COMMON_ATTRS, {
    "integrity": attr.string(),
    "patch_args": attr.string_list(default = ["-p0"]),
    "patches": attr.label_list(),
    "run_lifecycle_hooks": attr.bool(),
    "custom_postinstall": attr.string(),
    "yq": attr.label(default = "@yq//:yq"),
})

def _inject_run_lifecycle_hooks(rctx, pkg_json_path):
    rctx.execute([
        yq_path(rctx),
        "-P",
        "-o=json",
        "--inplace",
        ".scripts._rules_js_run_lifecycle_hooks=\"1\"",
        pkg_json_path,
    ], quiet = False)

def _inject_custom_postinstall(rctx, pkg_json_path, custom_postinstall):
    rctx.execute([
        yq_path(rctx),
        "-P",
        "-o=json",
        "--inplace",
        ".scripts._rules_js_custom_postinstall=\"%s\"" % custom_postinstall,
        pkg_json_path,
    ], quiet = False)

def _get_bin_entries(pkg_json, package):
    # https://docs.npmjs.com/cli/v7/configuring-npm/package-json#bin
    bin = pkg_json.get("bin", {})
    if type(bin) != "dict":
        bin = {paths.basename(package): bin}
    return bin

def _make_generated_by_lines(package, version):
    return [
        "\"@generated by @aspect_rules_js//js/private:npm_import.bzl for npm package {package}@{version}\"".format(
            package = package,
            version = version,
        ),
        "",  # empty line after bzl docstring since buildifier expects this if this file is vendored in
    ]

npm_import_links = repository_rule(
    implementation = _impl_links,
    attrs = _ATTRS_LINKS,
)

npm_import = repository_rule(
    implementation = _impl,
    attrs = _ATTRS,
)
