"Repository rules for importing packages from npm"

load("@aspect_bazel_lib//lib:repo_utils.bzl", "is_windows_os", "patch")
load(":pnpm_utils.bzl", "pnpm_utils")
load(":yq.bzl", "yq_bin")

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

The instantiates an `js_binary` target for this package that can be referenced by the alias
`@//link/package:npm__name` and `@//link/package:npm__@scope+name` for scoped packages.
The `npm` prefix of these alias is configurable via the `namespace` attribute.

When using `translate_pnpm_lock`, you can `link` all the npm dependencies in the lock files with:

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

_NODEJS_PACKAGE_TMPL = """{maybe_load_run_js_binary}
def node_package():
    if "{link_package_guard}" != "." and native.package_name() != "{link_package_guard}":
        fail("The node_package() macro loaded from {node_package_bzl} may only be called in the '{link_package_guard}' package. Move the call to the '{link_package_guard}' package BUILD file.")

    # ref node_package used to prevent circular deps
    _node_package(
        name = "{namespace}{bazel_name}__ref",
        package = "{package}",
        version = "{version}",
        indirect = True,
    )

    # pre-lifecycle refs package linked to _lc/node_modules for use in postinstall actions
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
        visibility = ["//visibility:public"],{maybe_indirect}
    )

    # terminal pre-lifecycle package linked to _lc/node_modules for use in postinstall actions
    _node_package(
        name = "{namespace}{bazel_name}__lc",
        package = "{package}",
        version = "{version}",
        # transitive closure of {namespace}*__lc_pkg deps
        deps = {lc_deps},
        root_dir = "_lc/node_modules",
        # don't build this unless it is asked for
        tags = ["manual"],
        visibility = ["//visibility:public"],{maybe_indirect}
    )
    {maybe_lifecycle_hooks}
    # refs package for use in terminal package transitive closure
    _node_package(
        name = "{namespace}{bazel_name}__pkg",
        src = "{node_package_src}",
        package = "{package}",
        version = "{version}",
        # direct dep references
        deps = {ref_deps},
        visibility = ["//visibility:public"],{maybe_indirect}
    )

    # terminal package target with transitive closure of postinstall npm packages
    _node_package(
        name = "{namespace}{bazel_name}",{maybe_node_package_src}
        package = "{package}",
        version = "{version}",
        # transitive closure of {namespace}*__pkg deps
        deps = {deps},
        visibility = ["//visibility:public"],{maybe_indirect}
    )
"""

_RUN_LIFECYCLE_HOOKS_TMPL = """# runs lifecycle hooks on the package
    run_js_binary(
        name = "{namespace}{bazel_name}_postinstall",
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

def _to_list_attr(list, tab):
    if not list:
        return "[]"
    result = "["
    for v in list:
        result += "\n%s    \"%s\"," % (tab, v)
    result += "\n%s]" % tab
    return result

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
    mkdir_args = ["mkdir", "-p", extract_dirname] if not is_windows_os(rctx) else ["cmd", "/c", "if not exist {extract_dirname} (mkdir {extract_dirname})".format(extract_dirname = extract_dirname.replace("/", "\\"))]
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
                lc_deps.append("{namespace}{bazel_name}__lc_pkg".format(
                    namespace = pnpm_utils.node_package_target_namespace,
                    bazel_name = pnpm_utils.bazel_name(dep_name, dep_version),
                ))
                deps.append("{namespace}{bazel_name}__pkg".format(
                    namespace = pnpm_utils.node_package_target_namespace,
                    bazel_name = pnpm_utils.bazel_name(dep_name, dep_version),
                ))
    else:
        for (dep_name, dep_versions) in rctx.attr.deps.items():
            for dep_version in dep_versions:
                lc_deps.append("{namespace}{bazel_name}__lc".format(
                    namespace = pnpm_utils.node_package_target_namespace,
                    bazel_name = pnpm_utils.bazel_name(dep_name, dep_version),
                ))
                deps.append("{namespace}{bazel_name}".format(
                    namespace = pnpm_utils.node_package_target_namespace,
                    bazel_name = pnpm_utils.bazel_name(dep_name, dep_version),
                ))

    node_package_bzl_file = "node_package.bzl"

    if rctx.attr.postinstall and rctx.attr.enable_lifecycle_hooks:
        _inject_custom_postinstall(rctx, extract_dirname, rctx.attr.postinstall)

    enable_lifecycle_hooks = rctx.attr.enable_lifecycle_hooks and _has_lifecycle_hooks(rctx, extract_dirname)

    bazel_name = pnpm_utils.bazel_name(rctx.attr.package, rctx.attr.version)

    if enable_lifecycle_hooks:
        node_package_src = ":{namespace}{bazel_name}_postinstall".format(
            namespace = pnpm_utils.node_package_target_namespace,
            bazel_name = bazel_name,
        )
    else:
        node_package_src = "@%s//:%s" % (rctx.name, extract_dirname)

    node_package_bzl = [_NODEJS_PACKAGE_TMPL.format(
        namespace = pnpm_utils.node_package_target_namespace,
        extract_dirname = extract_dirname,
        link_package_guard = rctx.attr.link_package_guard,
        package = rctx.attr.package,
        version = rctx.attr.version,
        rctx_name = rctx.name,
        node_package_bzl = "@%s//:%s" % (rctx.name, node_package_bzl_file),
        bazel_name = bazel_name,
        ref_deps = _to_list_attr(ref_deps, "        "),
        lc_deps = _to_list_attr(lc_deps, "        "),
        deps = _to_list_attr(deps, "        "),
        maybe_indirect = """
        indirect = True,""" if rctx.attr.indirect else "",
        node_package_src = node_package_src,
        maybe_node_package_src = """
        src = \"%s\",""" % node_package_src if not transitive_closure_pattern else "",
        maybe_load_run_js_binary = "load(\"@aspect_rules_js//js:run_js_binary.bzl\", \"run_js_binary\")" if enable_lifecycle_hooks else "",
        maybe_lifecycle_hooks = _RUN_LIFECYCLE_HOOKS_TMPL.format(
            namespace = pnpm_utils.node_package_target_namespace,
            extract_dirname = extract_dirname,
            rctx_name = rctx.name,
            bazel_name = bazel_name,
        ) if enable_lifecycle_hooks else "",
    )]

    # Add an namespace if this is a direct dependency
    if not rctx.attr.indirect:
        node_package_bzl.append(_ALIAS_TMPL.format(
            alias = pnpm_utils.bazel_name(rctx.attr.package),
            namespace = pnpm_utils.node_package_target_namespace,
            bazel_name = bazel_name,
        ))

    bzl_header = [
        "# @generated by npm_import.bzl",
        """load("@aspect_rules_js//js:node_package.bzl", _node_package = "node_package")""",
        "",
    ]
    rctx.file(node_package_bzl_file, "\n".join(bzl_header + node_package_bzl))

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
    "yq_repository": attr.string(
        doc = """The basename for the yq toolchain repository from @aspect_bazel_lib.""",
        default = "yq",
    ),
}

npm_import = struct(
    doc = _DOC,
    implementation = _impl,
    attrs = _ATTRS,
)

def _inject_custom_postinstall(rctx, package_path, custom_postinstall):
    pkg_json_path = package_path + _sep(rctx) + "package.json"
    rctx.execute([yq_bin(rctx, rctx.attr.yq_repository), "-P", "-o=json", "--inplace", ".scripts._rules_js_postinstall=\"%s\"" % custom_postinstall, pkg_json_path], quiet = False)

def _has_lifecycle_hooks(rctx, package_path):
    pkg_json_path = package_path + _sep(rctx) + "package.json"
    pkg_json = json.decode(rctx.read(pkg_json_path))
    return "scripts" in pkg_json and (
        "preinstall" in pkg_json["scripts"] or
        "install" in pkg_json["scripts"] or
        "postinstall" in pkg_json["scripts"] or
        "_rules_js_postinstall" in pkg_json["scripts"]
    )

def _sep(rctx):
    if rctx.os.name == "Windows":
        return "\\"
    return "/"
