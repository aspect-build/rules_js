"Repository rules for importing packages from npm"

load("@aspect_bazel_lib//lib:repo_utils.bzl", "patch", "repo_utils")
load("@bazel_skylib//lib:paths.bzl", "paths")
load("@bazel_skylib//lib:dicts.bzl", "dicts")
load(":pnpm_utils.bzl", "pnpm_utils")
load(":starlark_codegen_utils.bzl", "starlark_codegen_utils")
load(":repo_toolchains.bzl", "yq_path")

_LINK_JS_PACKAGE_TMPL = """
# buildifier: disable=unnamed-macro
def link_js_package():
    "Generated intermediate and terminal link_js_package targets for npm package {package}@{version}"
    if "{link_package_guard}" != "." and native.package_name() != "{link_package_guard}":
        fail("The link_js_package() macro loaded from {link_js_package_bzl} may only be called in the '{link_package_guard}' package. Move the call to the '{link_package_guard}' package BUILD file.")

    # reference node package used to avoid circular deps
    _link_js_package(
        name = "{namespace}{bazel_name}__ref",
        package = "{package}",
        version = "{version}",
        indirect = True,
    )

    {maybe_lifecycle_hooks}
    # post-lifecycle node package with reference deps for use in terminal node package with
    # transitive closure
    _link_js_package(
        name = "{namespace}{bazel_name}__pkg",
        src = "{js_package_src}",
        package = "{package}",
        version = "{version}",
        # direct dep references
        deps = {ref_deps},
        visibility = ["//visibility:public"],{maybe_indirect}
    )

    # terminal node package with transitive closure of node package dependencies
    _link_js_package(
        name = "{namespace}{bazel_name}",{maybe_js_package_src}
        package = "{package}",
        version = "{version}",
        # transitive closure of {namespace}*__pkg deps
        deps = {deps},
        visibility = ["//visibility:public"],{maybe_indirect}
    )
"""

_RUN_LIFECYCLE_HOOKS_TMPL = """
    # post-lifecycle node package with reference deps for use in terminal node package with
    # transitive closure
    _link_js_package(
        name = "{namespace}{bazel_name}__pkg_lite",
        package = "{package}",
        version = "{version}",
        # direct dep references
        deps = {ref_deps},
        visibility = ["//visibility:public"],{maybe_indirect}
    )

    # terminal pre-lifecycle node package for use in lifecycle build target below
    _link_js_package(
        name = "{namespace}{bazel_name}__lc",
        package = "{package}",
        version = "{version}",
        # transitive closure of {namespace}*__pkg deps with a carve out for {namespace}{bazel_name}__pkg_lite
        deps = {lc_deps},
        visibility = ["//visibility:public"],{maybe_indirect}
    )

    # runs lifecycle hooks on the package
    lifecycle_target_name = "node_modules/{virtual_store_root}/%s/node_modules/{package}" % _pnpm_utils.virtual_store_name("{package}", "{version}")

    _run_js_binary(
        name = lifecycle_target_name,
        srcs = [
            "@{rctx_name}_sources//:{extract_to_dirname}",
            ":{namespace}{bazel_name}__lc"
        ],
        # run_js_binary runs in the output dir; must add "../../../" because paths are relative to the exec root
        args = [
            "../../../$(execpath @{rctx_name}_sources//:{extract_to_dirname})",
            "../../../$(@D)",
        ],
        copy_srcs_to_bin = False,
        tool = "@aspect_rules_js//js/private/lifecycle:lifecycle-hooks",
        output_dir = True,
    )

    native.alias(
        name = "{namespace}{bazel_name}__lifecycle",
        actual = lifecycle_target_name,
        visibility = ["//visibility:public"],
    )
"""

_ALIAS_TMPL = """    native.alias(
        name = "{namespace}{alias}",
        actual = ":{namespace}{bazel_name}",
        visibility = ["//visibility:public"],
    )

    native.alias(
        name = "{namespace}{alias}__dir",
        actual = ":{namespace}{bazel_name}__dir",
        visibility = ["//visibility:public"],
    )
"""

_BIN_MACRO_TMPL = """
def {bin_name}(name, **kwargs):
    _directory_path(
        name = "%s__entry_point" % name,
        directory = ":{namespace}{bazel_name}__dir",
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
        directory = ":{namespace}{bazel_name}__dir",
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
        directory = ":{namespace}{bazel_name}__dir",
        path = "{bin_path}",
    )
    _js_binary(
        name = name,
        entry_point = ":%s__entry_point" % name,
        **kwargs
    )
"""

_TARBALL_FILENAME = "package.tgz"
_EXTRACT_TO_DIRNAME = "package"
_LINK_JS_PACKAGE_BZL_FILENAME = "link_js_package.bzl"

def _impl_sources(rctx):
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
                    bin_name = name,
                    namespace = pnpm_utils.js_package_target_namespace,
                    bazel_name = bazel_name,
                    bin_path = bins[name],
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

    rctx.file("BUILD.bazel", "exports_files(%s)" % starlark_codegen_utils.to_list_attr([_EXTRACT_TO_DIRNAME] + ([bin_bzl_file] if bin_bzl_file else [])))

def _impl(rctx):
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
            lc_deps.append("{namespace}{bazel_name}".format(
                namespace = pnpm_utils.js_package_target_namespace,
                bazel_name = pnpm_utils.bazel_name(dep_name, dep_version),
            ))
            deps.append("{namespace}{bazel_name}".format(
                namespace = pnpm_utils.js_package_target_namespace,
                bazel_name = pnpm_utils.bazel_name(dep_name, dep_version),
            ))

    bazel_name = pnpm_utils.bazel_name(rctx.attr.package, rctx.attr.version)

    if rctx.attr.lifecycle_build_target:
        js_package_src = ":{namespace}{bazel_name}__lifecycle".format(
            namespace = pnpm_utils.js_package_target_namespace,
            bazel_name = bazel_name,
        )
    else:
        js_package_src = "@{}_sources//:{}".format(rctx.name, _EXTRACT_TO_DIRNAME)

    maybe_indirect = """
        indirect = True,""" if rctx.attr.indirect else ""
    maybe_js_package_src = """
        src = \"%s\",""" % js_package_src if not transitive_closure_pattern else ""
    maybe_lifecycle_hooks = _RUN_LIFECYCLE_HOOKS_TMPL.format(
        namespace = pnpm_utils.js_package_target_namespace,
        extract_to_dirname = _EXTRACT_TO_DIRNAME,
        rctx_name = rctx.name,
        bazel_name = bazel_name,
        ref_deps = ref_deps,
        virtual_store_root = pnpm_utils.virtual_store_root,
        package = rctx.attr.package,
        version = rctx.attr.version,
        lc_deps = starlark_codegen_utils.to_list_attr(lc_deps, 2),
        maybe_indirect = maybe_indirect,
    ) if rctx.attr.lifecycle_build_target else ""

    link_js_package_bzl = [_LINK_JS_PACKAGE_TMPL.format(
        namespace = pnpm_utils.js_package_target_namespace,
        extract_to_dirname = _EXTRACT_TO_DIRNAME,
        link_package_guard = rctx.attr.link_package_guard,
        package = rctx.attr.package,
        version = rctx.attr.version,
        rctx_name = rctx.name,
        link_js_package_bzl = "@%s//:%s" % (rctx.name, _LINK_JS_PACKAGE_BZL_FILENAME),
        bazel_name = bazel_name,
        ref_deps = starlark_codegen_utils.to_list_attr(ref_deps, 2),
        deps = starlark_codegen_utils.to_list_attr(deps, 2),
        js_package_src = js_package_src,
        maybe_indirect = maybe_indirect,
        maybe_js_package_src = maybe_js_package_src,
        maybe_lifecycle_hooks = maybe_lifecycle_hooks,
    )]

    generated_by_lines = _make_generated_by_lines(rctx.attr.package, rctx.attr.version)

    # Add an namespace if this is a direct dependency
    if not rctx.attr.indirect:
        link_js_package_bzl.append(_ALIAS_TMPL.format(
            alias = pnpm_utils.bazel_name(rctx.attr.package),
            namespace = pnpm_utils.js_package_target_namespace,
            bazel_name = bazel_name,
        ))

    link_js_package_bzl_header = generated_by_lines + [
        """load("@aspect_rules_js//js:%s", _link_js_package = "link_js_package")""" % _LINK_JS_PACKAGE_BZL_FILENAME,
    ]
    if rctx.attr.lifecycle_build_target:
        link_js_package_bzl_header.extend([
            """load("@aspect_rules_js//js:run_js_binary.bzl", _run_js_binary = "run_js_binary")""",
            """load("@aspect_rules_js//js/private:pnpm_utils.bzl", _pnpm_utils = "pnpm_utils")""",
        ])

    rctx.file(_LINK_JS_PACKAGE_BZL_FILENAME, "\n".join(link_js_package_bzl_header + link_js_package_bzl))
    rctx.file("BUILD.bazel", "exports_files(%s)" % starlark_codegen_utils.to_list_attr([_LINK_JS_PACKAGE_BZL_FILENAME]))

_COMMON_ATTRS = {
    "package": attr.string(mandatory = True),
    "version": attr.string(mandatory = True),
}

_ATTRS = dicts.add(_COMMON_ATTRS, {
    "deps": attr.string_dict(),
    "transitive_closure": attr.string_list_dict(),
    "indirect": attr.bool(),
    "link_package_guard": attr.string(default = "."),
    "lifecycle_build_target": attr.bool(),
})

_ATTRS_SOURCES = dicts.add(_COMMON_ATTRS, {
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

npm_import = repository_rule(
    implementation = _impl,
    attrs = _ATTRS,
)

npm_import_sources = repository_rule(
    implementation = _impl_sources,
    attrs = _ATTRS_SOURCES,
)
