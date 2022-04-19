"Repository rules for importing packages from npm"

load("@aspect_bazel_lib//lib:repo_utils.bzl", "os_name", "patch")
load(":npm_utils.bzl", "npm_utils")

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
    name = "npm__types_node-15.2.2",
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
load("@npm__types_node-15.2.2//:node_package.bzl", node_package_types_node = "node_package")

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

def is_windows_os(rctx):
    os_name = rctx.os.name.lower()
    return os_name.find("windows") != -1

_NODEJS_PACKAGE_TMPL = \
    """{maybe_load_run_js_binary}
def node_package():
    if "{link_package_guard}" != "." and native.package_name() != "{link_package_guard}":
        fail("The node_package() macro loaded from {node_package_bzl} may only be called in the '{link_package_guard}' package. Move the call to the '{link_package_guard}' package BUILD file.")

    {maybe_lifecycle_hooks}

    _node_package(
        name = "{namespace}__{bazel_name}",
        src = "{nodejs_package_src}",
        package = "{package}",
        version = "{version}",
        deps = {deps},
        visibility = ["//visibility:public"],{maybe_indirect}
    )
"""

_RUN_LIFECYCLE_HOOKS_TMPL = """# Run lifecycle hooks on the package
    run_js_binary(
        name = "{namespace}__{bazel_name}_postinstall",
        srcs = ["@{rctx_name}//:{dir}"] + {deps},
        # run_js_binary runs in the output dir; must add "../../../" because paths are relative to the exec root
        args = [ "../../../$(execpath @{rctx_name}//:{dir})", "../../../$(@D)"],
        copy_srcs_to_bin = False,
        tool = "@aspect_rules_js//js/private/lifecycle:lifecycle-hooks",
        output_dir = True,
    )
"""

_NODEJS_PACKAGE_EXPERIMENTAL_REF_DEPS_TMPL = _NODEJS_PACKAGE_TMPL + \
                                             """   _node_package(
        name = "{namespace}__{bazel_name}__ref",
        package = "{package}",
        version = "{version}",{maybe_indirect}
    )
"""

_ALIAS_TMPL = \
    """    native.alias(
        name = "{namespace}__{alias}",
        actual = ":{namespace}__{bazel_name}",
        visibility = ["//visibility:public"],
    )

    native.alias(
        name = "{namespace}__{alias}__dir",
        actual = ":{namespace}__{bazel_name}__dir",
        visibility = ["//visibility:public"],
    )
"""

def _impl(rctx):
    tarball = "package.tgz"
    rctx.download(
        output = tarball,
        url = "https://registry.npmjs.org/{0}/-/{1}-{2}.tgz".format(
            rctx.attr.package,
            # scoped packages contain a slash in the name, which doesn't appear in the later part of the URL
            rctx.attr.package.split("/")[-1],
            npm_utils.strip_peer_dep_version(rctx.attr.version),
        ),
        integrity = rctx.attr.integrity,
    )

    dirname = "package"
    mkdir_args = ["mkdir", "-p", dirname] if not is_windows_os(rctx) else ["cmd", "/c", "if not exist {dir} (mkdir {dir})".format(dir = dirname.replace("/", "\\"))]
    result = rctx.execute(mkdir_args)
    if result.return_code:
        msg = "mkdir %s failed: \nSTDOUT:\n%s\nSTDERR:\n%s" % (dirname, result.stdout, result.stderr)
        fail(msg)

    # npm packages are always published with one top-level directory inside the tarball, tho the name is not predictable
    # so we use tar here which takes a --strip-components N argument instead of rctx.download_and_extract
    untar_args = ["tar", "-xf", tarball, "--strip-components", str(1), "-C", dirname]
    result = rctx.execute(untar_args)
    if result.return_code:
        msg = "tar %s failed: \nSTDOUT:\n%s\nSTDERR:\n%s" % (dirname, result.stdout, result.stderr)
        fail(msg)

    rctx.file("BUILD.bazel", "exports_files([\"{dir}\"])".format(dir = dirname))

    deps = []
    for dep in rctx.attr.deps:
        parsed_dep = npm_utils.parse_dependency_string(dep)
        dep_target = "{namespace}__{bazel_name}__ref" if rctx.attr.experimental_reference_deps else "{namespace}__{bazel_name}"
        deps.append(dep_target.format(
            namespace = npm_utils.node_package_target_namespace,
            bazel_name = npm_utils.bazel_name(parsed_dep.name, parsed_dep.version),
        ))

    node_package_bzl_file = "node_package.bzl"

    if rctx.attr.postinstall and rctx.attr.enable_lifecycle_hooks:
        _inject_custom_postinstall(rctx, dirname, rctx.attr.postinstall)

    enable_lifecycle_hooks = rctx.attr.enable_lifecycle_hooks and _has_lifecycle_hooks(rctx, dirname)

    bazel_name = npm_utils.bazel_name(rctx.attr.package, rctx.attr.version)
    node_package_tmpl = _NODEJS_PACKAGE_EXPERIMENTAL_REF_DEPS_TMPL if rctx.attr.experimental_reference_deps else _NODEJS_PACKAGE_TMPL
    node_package_bzl = [node_package_tmpl.format(
        namespace = npm_utils.node_package_target_namespace,
        dir = dirname,
        link_package_guard = rctx.attr.link_package_guard,
        package = rctx.attr.package,
        version = rctx.attr.version,
        rctx_name = rctx.name,
        node_package_bzl = "@%s//:%s" % (rctx.name, node_package_bzl_file),
        bazel_name = bazel_name,
        deps = "%s" % deps,
        maybe_indirect = """
        indirect = True,""" if rctx.attr.indirect else "",
        nodejs_package_src = ":%s__%s_postinstall" % (npm_utils.node_package_target_namespace, bazel_name) if enable_lifecycle_hooks else "@%s//:%s" % (rctx.name, dirname),
        maybe_load_run_js_binary = "load(\"@aspect_rules_js//js:run_js_binary.bzl\", \"run_js_binary\")" if enable_lifecycle_hooks else "",
        maybe_lifecycle_hooks = _RUN_LIFECYCLE_HOOKS_TMPL.format(
            namespace = npm_utils.node_package_target_namespace,
            dir = dirname,
            rctx_name = rctx.name,
            bazel_name = bazel_name,
            deps = "%s" % deps,
        ) if enable_lifecycle_hooks else "",
    )]

    # Add an namespace if this is a direct dependency
    if not rctx.attr.indirect:
        node_package_bzl.append(_ALIAS_TMPL.format(
            alias = npm_utils.alias_target_name(rctx.attr.package),
            namespace = npm_utils.node_package_target_namespace,
            bazel_name = bazel_name,
        ))

    bzl_header = [
        "# @generated by npm_import.bzl",
        """load("@aspect_rules_js//js:node_package.bzl", _node_package = "node_package")""",
        "",
    ]
    rctx.file(node_package_bzl_file, "\n".join(bzl_header + node_package_bzl))

    # Apply patches to the extracted package
    patch(rctx, patch_args = rctx.attr.patch_args, patch_directory = dirname)

_ATTRS = {
    "deps": attr.string_list(
        doc = """Other npm packages this one depends on""",
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
    "experimental_reference_deps": attr.bool(
        doc = """Experimental reference deps allow dep to support circular deps between npm packages.
        This feature depends on dangling symlinks, however, which is still experimental in bazel,
        has issues with "host" and "exec" configurations, and does not yet work with remote exection.""",
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
    rctx.execute([_yq_bin(rctx), "-P", "-o=json", "--inplace", ".scripts._rules_js_postinstall=\"%s\"" % custom_postinstall, pkg_json_path], quiet = False)

def _yq_bin(rctx):
    # Parse the resolved host platform from the yq_host repo
    content = rctx.read(rctx.path(Label("@%s_host//:index.bzl" % rctx.attr.yq_repository)))
    search_str = "host_platform=\""
    start_index = content.index(search_str) + len(search_str)
    end_index = content.index("\"", start_index)
    host_platform = content[start_index:end_index]

    # Return the path to the yq binary
    return rctx.path(Label("@%s_%s//:yq%s" % (rctx.attr.yq_repository, host_platform, ".exe" if os_name(rctx) == "windows" else "")))

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
