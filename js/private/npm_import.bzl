"Repository rules for importing packages from npm"

load("@aspect_bazel_lib//lib:repo_utils.bzl", "patch", "repo_utils")
load("@bazel_skylib//lib:paths.bzl", "paths")
load(":pnpm_utils.bzl", "pnpm_utils")
load(":starlark_codegen_utils.bzl", "starlark_codegen_utils")
load(":repo_toolchains.bzl", "yq_path")

_DOC = """Import a single npm package into Bazel.

Normally you'd want to use `translate_pnpm_lock` to import all your packages at once.
It generates `npm_import` rules.
You can create these manually if you want to have exact control.

Bazel will only fetch the given package from an external registry if the package is
required for the user-requested targets to be build/tested.

This is a repository rule, which should be called from your `WORKSPACE` file
or some `.bzl` file loaded from it. For example, with this code in `WORKSPACE`:

```starlark
npm_import(
    name = "npm__at_types_node_15.12.2",
    package = "@types/node",
    version = "15.12.2",
    integrity = "sha512-zjQ69G564OCIWIOHSXyQEEDpdpGl+G348RAKY0XXy9Z5kU9Vzv1GMNnkar/ZJ8dzXB3COzD9Mo9NtRZ4xfgUww==",
)
```

> This is similar to Bazel rules in other ecosystems named "_import" like
> `apple_bundle_import`, `scala_import`, `java_import`, and `py_import`.
> `go_repository` is also a model for this rule.

The name of this repository should contain the version number, so that multiple versions of the same
package don't collide.
(Note that the npm ecosystem always supports multiple versions of a library depending on where
it is required, unlike other languages like Go or Python.)

To consume the downloaded package in rules, it must be "linked" into the link package in the
package's `BUILD.bazel` file:

```
load("@npm__at_types_node_15.12.2//:node_package.bzl", node_package_types_node = "node_package")

node_package_types_node()
```

This instantiates a `node_package` target for this package that can be referenced by the alias
`@//link/package:npm__name` and `@//link/package:npm__@scope+name` for scoped packages.
The `npm` prefix of these alias is configurable via the `namespace` attribute.

When using `translate_pnpm_lock`, you can `link` all the npm dependencies in the lock file with:

```
load("@npm//:node_modules.bzl", "node_modules")

node_modules()
```

`translate_pnpm_lock` also creates convienence aliases in the external repository that reference
the linked `node_package` targets. For example, `@npm//name` and `@npm//@scope/name`.

To change the proxy URL we use to fetch, configure the Bazel downloader:

1. Make a file containing a rewrite rule like

    rewrite (registry.nodejs.org)/(.*) artifactory.build.internal.net/artifactory/$1/$2

1. To understand the rewrites, see [UrlRewriterConfig] in Bazel sources.

1. Point bazel to the config with a line in .bazelrc like
common --experimental_downloader_config=.bazel_downloader_config

[UrlRewriterConfig]: https://github.com/bazelbuild/bazel/blob/4.2.1/src/main/java/com/google/devtools/build/lib/bazel/repository/downloader/UrlRewriterConfig.java#L66
"""

_NODEJS_PACKAGE_TMPL = """
# buildifier: disable=unnamed-macro
def node_package():
    "Generated intermediate and terminal node_package targets for npm package {package}@{version}"
    if "{link_package_guard}" != "." and native.package_name() != "{link_package_guard}":
        fail("The node_package() macro loaded from {node_package_bzl} may only be called in the '{link_package_guard}' package. Move the call to the '{link_package_guard}' package BUILD file.")

    # reference node package used to avoid circular deps
    _node_package(
        name = "{namespace}{bazel_name}__ref",
        package = "{package}",
        version = "{version}",
        indirect = True,{maybe_bins}
    )

    # pre-lifecycle node package with reference deps for use in pre-lifecycle terminal node packages
    # (linked into lifecycle node_modules tree _lc/node_modules)
    _node_package(
        name = "{namespace}{bazel_name}__lc_pkg",
        src = "@{rctx_name}//:{extract_dirname}",
        package = "{package}",
        version = "{version}",
        # direct dep references
        deps = {ref_deps},
        root_dir = "_lc/node_modules",
        # don't build this unless it is asked for
        tags = ["manual"],
        visibility = ["//visibility:public"],{maybe_indirect}{maybe_bins}
    )

    {maybe_lifecycle_hooks}
    # post-lifecycle node package with reference deps for use in terminal node package with
    # transitive closure
    _node_package(
        name = "{namespace}{bazel_name}__pkg",
        src = "{node_package_src}",
        package = "{package}",
        version = "{version}",
        # direct dep references
        deps = {ref_deps},
        visibility = ["//visibility:public"],{maybe_indirect}{maybe_bins}
    )

    # terminal node package with transitive closure of node package dependencies
    _node_package(
        name = "{namespace}{bazel_name}",{maybe_node_package_src}
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
    _node_package(
        name = "{namespace}{bazel_name}__lc_pkg_lite",
        package = "{package}",
        version = "{version}",
        # direct dep references
        deps = {ref_deps},
        root_dir = "_lc/node_modules",
        # output bins when src is not set
        always_output_bins = True,
        visibility = ["//visibility:public"],{maybe_indirect}{maybe_bins}
    )

    # terminal pre-lifecycle node package for use in lifecycle build target below
    # (linked into lifecycle node_modules tree _lc/node_modules)
    _node_package(
        name = "{namespace}{bazel_name}__lc",
        package = "{package}",
        version = "{version}",
        # transitive closure of {namespace}*__lc_pkg deps
        deps = {lc_deps},
        root_dir = "_lc/node_modules",
        visibility = ["//visibility:public"],{maybe_indirect}
    )

    # runs lifecycle hooks on the package
    lifecycle_target_name = "_lc/node_modules/{virtual_store_root}/%s/node_modules/{package}" % _pnpm_utils.virtual_store_name("{package}", "{version}")

    _run_js_binary(
        name = lifecycle_target_name,
        srcs = [
            "@{rctx_name}//:{extract_dirname}",
            ":{namespace}{bazel_name}__lc"
        ],
        # run_js_binary runs in the output dir; must add "../../../" because paths are relative to the exec root
        args = [ "../../../$(execpath @{rctx_name}//:{extract_dirname})", "../../../$(@D)"],
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
        **kwargs,
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
        **kwargs,
    )   
"""

def _impl(rctx):
    numeric_version = pnpm_utils.strip_peer_dep_version(rctx.attr.version)

    tarball = "package.tgz"
    rctx.download(
        output = tarball,
        url = "https://registry.npmjs.org/{0}/-/{1}-{2}.tgz".format(
            rctx.attr.package,
            # scoped packages contain a slash in the name, which doesn't appear in the later part of the URL
            rctx.attr.package.split("/")[-1],
            numeric_version,
        ),
        integrity = rctx.attr.integrity,
    )

    extract_dirname = "package"
    mkdir_args = ["mkdir", "-p", extract_dirname] if not repo_utils.is_windows(rctx) else ["cmd", "/c", "if not exist {extract_dirname} (mkdir {extract_dirname})".format(extract_dirname = extract_dirname.replace("/", "\\"))]
    result = rctx.execute(mkdir_args)
    if result.return_code:
        msg = "mkdir %s failed: \nSTDOUT:\n%s\nSTDERR:\n%s" % (extract_dirname, result.stdout, result.stderr)
        fail(msg)

    # npm packages are always published with one top-level directory inside the tarball, tho the name is not predictable
    # so we use tar here which takes a --strip-components N argument instead of rctx.download_and_extract
    untar_args = ["tar", "-xf", tarball, "--strip-components", str(1), "-C", extract_dirname]
    result = rctx.execute(untar_args)
    if result.return_code:
        msg = "tar %s failed: \nSTDOUT:\n%s\nSTDERR:\n%s" % (extract_dirname, result.stdout, result.stderr)
        fail(msg)

    rctx.file("BUILD.bazel", "exports_files([\"{extract_dirname}\"])".format(extract_dirname = extract_dirname))

    ref_deps = []
    lc_deps = []
    deps = []

    for (dep_name, dep_version) in rctx.attr.deps.items():
        ref_deps.append("{namespace}{bazel_name}__ref".format(
            namespace = pnpm_utils.node_package_target_namespace,
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
                    # the __lc_pkg of this package as that will be the output directory
                    # of the lifecycle action
                    lc_deps.append("{namespace}{bazel_name}__lc_pkg_lite".format(
                        namespace = pnpm_utils.node_package_target_namespace,
                        bazel_name = pnpm_utils.bazel_name(dep_name, dep_version),
                    ))
                else:
                    lc_deps.append("{namespace}{bazel_name}__lc_pkg".format(
                        namespace = pnpm_utils.node_package_target_namespace,
                        bazel_name = pnpm_utils.bazel_name(dep_name, dep_version),
                    ))
                deps.append("{namespace}{bazel_name}__pkg".format(
                    namespace = pnpm_utils.node_package_target_namespace,
                    bazel_name = pnpm_utils.bazel_name(dep_name, dep_version),
                ))
    else:
        for (dep_name, dep_version) in rctx.attr.deps.items():
            lc_deps.append("{namespace}{bazel_name}__lc".format(
                namespace = pnpm_utils.node_package_target_namespace,
                bazel_name = pnpm_utils.bazel_name(dep_name, dep_version),
            ))
            deps.append("{namespace}{bazel_name}".format(
                namespace = pnpm_utils.node_package_target_namespace,
                bazel_name = pnpm_utils.bazel_name(dep_name, dep_version),
            ))

    pkg_json_path = paths.join(extract_dirname, "package.json")

    if rctx.attr.postinstall and rctx.attr.enable_lifecycle_hooks:
        _inject_custom_postinstall(rctx, pkg_json_path, rctx.attr.postinstall)

    pkg_json = json.decode(rctx.read(pkg_json_path))

    bins = _get_bin_entries(pkg_json, rctx.attr.package)

    enable_lifecycle_hooks = rctx.attr.enable_lifecycle_hooks and _has_lifecycle_hooks(pkg_json)

    bazel_name = pnpm_utils.bazel_name(rctx.attr.package, rctx.attr.version)

    if enable_lifecycle_hooks:
        node_package_src = ":{namespace}{bazel_name}__lifecycle".format(
            namespace = pnpm_utils.node_package_target_namespace,
            bazel_name = bazel_name,
        )
    else:
        node_package_src = "@%s//:%s" % (rctx.name, extract_dirname)

    node_package_bzl_file = "node_package.bzl"

    maybe_bins = """
        bins = %s,""" % starlark_codegen_utils.to_dict_attr(bins, 2) if bins else ""
    maybe_indirect = """
        indirect = True,""" if rctx.attr.indirect else ""
    maybe_node_package_src = """
        src = \"%s\",""" % node_package_src if not transitive_closure_pattern else ""
    maybe_lifecycle_hooks = _RUN_LIFECYCLE_HOOKS_TMPL.format(
        namespace = pnpm_utils.node_package_target_namespace,
        extract_dirname = extract_dirname,
        rctx_name = rctx.name,
        bazel_name = bazel_name,
        ref_deps = ref_deps,
        virtual_store_root = pnpm_utils.virtual_store_root,
        package = rctx.attr.package,
        version = rctx.attr.version,
        lc_deps = starlark_codegen_utils.to_list_attr(lc_deps, 2),
        maybe_bins = maybe_bins,
        maybe_indirect = maybe_indirect,
    ) if enable_lifecycle_hooks else ""

    node_package_bzl = [_NODEJS_PACKAGE_TMPL.format(
        namespace = pnpm_utils.node_package_target_namespace,
        extract_dirname = extract_dirname,
        link_package_guard = rctx.attr.link_package_guard,
        package = rctx.attr.package,
        version = rctx.attr.version,
        rctx_name = rctx.name,
        node_package_bzl = "@%s//:%s" % (rctx.name, node_package_bzl_file),
        bazel_name = bazel_name,
        ref_deps = starlark_codegen_utils.to_list_attr(ref_deps, 2),
        deps = starlark_codegen_utils.to_list_attr(deps, 2),
        node_package_src = node_package_src,
        maybe_bins = maybe_bins,
        maybe_indirect = maybe_indirect,
        maybe_node_package_src = maybe_node_package_src,
        maybe_lifecycle_hooks = maybe_lifecycle_hooks,
    )]

    generated_by_lines = [
        "\"@generated by @aspect_rules_js//js/private:npm_import.bzl for npm package {package}@{version}\"".format(
            package = rctx.attr.package,
            version = rctx.attr.version,
        ),
        "",  # empty line after bzl docstring since buildifier expects this if this file is vendored in
    ]

    bin_bzl_file = "package_json.bzl"
    if not rctx.attr.indirect and bins:
        bin_bzl = generated_by_lines + [
            """load("@aspect_bazel_lib//lib:directory_path.bzl", _directory_path = "directory_path")""",
            """load("@aspect_rules_js//js:defs.bzl", _js_binary = "js_binary", _js_test = "js_test")""",
            """load("@aspect_rules_js//js:run_js_binary.bzl", _run_js_binary = "run_js_binary")""",
        ]
        for name in bins:
            bin_bzl.append(
                _BIN_MACRO_TMPL.format(
                    bin_name = name,
                    namespace = pnpm_utils.node_package_target_namespace,
                    bazel_name = bazel_name,
                    bin_path = bins[name],
                ),
            )

        rctx.file(bin_bzl_file, "\n".join(bin_bzl + [
            "bin = struct(%s)" % ",\n".join([
                "{name} = {name}, {name}_test = {name}_test, {name}_binary = {name}_binary".format(name = name)
                for name in bins
            ]),
        ]))

    # Add an namespace if this is a direct dependency
    if not rctx.attr.indirect:
        node_package_bzl.append(_ALIAS_TMPL.format(
            alias = pnpm_utils.bazel_name(rctx.attr.package),
            namespace = pnpm_utils.node_package_target_namespace,
            bazel_name = bazel_name,
        ))

    node_package_bzl_header = generated_by_lines + [
        """load("@aspect_rules_js//js:node_package.bzl", _node_package = "node_package")""",
    ]
    if enable_lifecycle_hooks:
        node_package_bzl_header.extend([
            """load("@aspect_rules_js//js:run_js_binary.bzl", _run_js_binary = "run_js_binary")""",
            """load("@aspect_rules_js//js/private:pnpm_utils.bzl", _pnpm_utils = "pnpm_utils")""",
        ])

    rctx.file(node_package_bzl_file, "\n".join(node_package_bzl_header + node_package_bzl))

    # Apply patches to the extracted package
    patch(rctx, patch_args = rctx.attr.patch_args, patch_directory = extract_dirname)

_ATTRS = {
    "deps": attr.string_dict(
        doc = """A dict other npm packages this one depends on where the key is
        the package name and value is the version""",
    ),
    "transitive_closure": attr.string_list_dict(
        doc = """A dict all npm packages this one depends on directly or transitively where the key
        is the package name and value is a list of version(s) depended on in the closure.""",
    ),
    "integrity": attr.string(
        doc = """Expected checksum of the file downloaded, in Subresource Integrity format.
        This must match the checksum of the file downloaded.

        This is the same as appears in the pnpm-lock.yaml, yarn.lock or package-lock.json file.

        It is a security risk to omit the checksum as remote files can change.
        At best omitting this field will make your build non-hermetic.
        It is optional to make development easier but should be set before shipping.""",
    ),
    "package": attr.string(
        doc = """Name of the npm package, such as `acorn` or `@types/node`""",
        mandatory = True,
    ),
    "version": attr.string(
        doc = """Version of the npm package, such as `8.4.0`""",
        mandatory = True,
    ),
    "patch_args": attr.string_list(
        doc = """Arguments to pass to the patch tool.
        `-p1` will usually be needed for patches generated by git.""",
        default = ["-p0"],
    ),
    "patches": attr.label_list(
        doc = """Patch files to apply onto the downloaded npm package.""",
    ),
    "postinstall": attr.string(
        doc = """Custom string postinstall script to run against the installed npm package. Runs after any existing lifecycle hooks.""",
    ),
    "indirect": attr.bool(
        doc = """If True, this is a indirect npm dependency which will not be linked as a top-level node_module.""",
    ),
    "link_package_guard": attr.string(
        doc = """When explictly set, check that the generated node_package() marcro
        in package.bzl is called within the specified package.

        Default value of "." implies no gaurd.

        This is set by automatically when using translate_pnpm_lock via npm_import
        to guard against linking the generated node_modules into the wrong
        location.""",
        default = ".",
    ),
    "enable_lifecycle_hooks": attr.bool(
        doc = """If true, runs lifecycle hooks declared in this package and the custom postinstall script if one exists.""",
        default = True,
    ),
    "yq": attr.label(
        doc = """The label to the yq binary to use. If executing on a windows host, the .exe extension will be appended if there is no .exe, .bat, or .cmd extension on the label.""",
        default = "@yq//:yq",
    ),
}

npm_import = struct(
    doc = _DOC,
    implementation = _impl,
    attrs = _ATTRS,
)

def _inject_custom_postinstall(rctx, pkg_json_path, custom_postinstall):
    rctx.execute([yq_path(rctx), "-P", "-o=json", "--inplace", ".scripts._rules_js_postinstall=\"%s\"" % custom_postinstall, pkg_json_path], quiet = False)

def _has_lifecycle_hooks(pkg_json):
    return "scripts" in pkg_json and (
        "preinstall" in pkg_json["scripts"] or
        "install" in pkg_json["scripts"] or
        "postinstall" in pkg_json["scripts"] or
        "_rules_js_postinstall" in pkg_json["scripts"]
    )

def _get_bin_entries(pkg_json, package):
    # https://docs.npmjs.com/cli/v7/configuring-npm/package-json#bin
    bin = pkg_json.get("bin", {})
    if type(bin) != "dict":
        bin = {paths.basename(package): bin}
    return bin
