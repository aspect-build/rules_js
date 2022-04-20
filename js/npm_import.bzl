"repository rules for importing packages from npm"

load("//js/private:translate_package_lock.bzl", lib = "translate_package_lock")
load("@bazel_tools//tools/build_defs/repo:utils.bzl", "patch")

def _npm_import_impl(repository_ctx):
    repository_ctx.download_and_extract(
        output = "extract_tmp",
        url = "https://registry.npmjs.org/{0}/-/{1}-{2}.tgz".format(
            repository_ctx.attr.package,
            # scoped packages contain a slash in the name, which doesn't appear in the later part of the URL
            repository_ctx.attr.package.split("/")[-1],
            repository_ctx.attr.version,
        ),
        integrity = repository_ctx.attr.integrity,
    )

    # Apply patches to the extracted package
    patch(repository_ctx, patch_args = repository_ctx.attr.patch_args)

    # npm packages are always published with one top-level directory inside the tarball, but the name is not predictable
    # so we have to run an external program to inspect the downloaded folder.
    if repository_ctx.os.name == "Windows":
        result = repository_ctx.execute(["dir", "/b", "extract_tmp"])
    else:
        result = repository_ctx.execute(["ls", "extract_tmp"])
    if result.return_code:
        fail("failed to inspect content of npm download: \nSTDOUT:\n%s\nSTDERR:\n%s" % (result.stdout, result.stderr))

    repository_ctx.file("BUILD.bazel", """
load("@aspect_bazel_lib//lib:copy_directory.bzl", "copy_directory")
load("@aspect_rules_js//js:js_package.bzl", "js_package")

# Turn a source directory into a TreeArtifact for RBE-compat
copy_directory(
    # The default target in this repository
    name = "_{name}",
    src = "extract_tmp/{nested_folder}",
    # The directory name must match the package in order for node to find it under
    # NODE_PATH=runfiles/[out]
    out = "{package_name}",
)

js_package(
    name = "{name}",
    src = "_{name}",
    package_name = "{package_name}",
    visibility = ["//visibility:public"],
    deps = {deps},
)

# The name of the repo can be affected by repository mapping and may not match
# our declared "npm_foo-1.2.3" naming. So give a stable label as well to use
# when declaring dependencies between packages.
alias(
    name = "pkg",
    actual = "{name}",
    visibility = ["//visibility:public"],
)
""".format(
        name = repository_ctx.name,
        nested_folder = result.stdout.rstrip("\n"),
        package_name = repository_ctx.attr.package,
        deps = [str(d.relative(":pkg")) for d in repository_ctx.attr.deps],
    ))

_npm_import = repository_rule(
    implementation = _npm_import_impl,
    attrs = {
        "deps": attr.label_list(),
        "integrity": attr.string(),
        "package": attr.string(mandatory = True),
        "version": attr.string(mandatory = True),
        "patches": attr.label_list(),
        "patch_args": attr.string_list(),
    },
)

def npm_import(integrity, package, version, deps = [], name = None, patches = [], patch_args = ["-p0"]):
    """Import a single npm package into Bazel.

    Normally you'd want to use `translate_package_lock` to import all your packages at once.
    It generates `npm_import` rules.
    You can create these manually if you want to have exact control.

    Bazel will only fetch the given package from an external registry if the package is
    required for the user-requested targets to be build/tested.
    The package will be exposed as a [`js_package`](./js_package) rule in a repository
    with a default name `@npm_[package name]-[version]`, as the default target in that repository.
    (Characters in the package name which are not legal in Bazel repository names are converted to underscore.)

    This is a repository rule, which should be called from your `WORKSPACE` file
    or some `.bzl` file loaded from it. For example, with this code in `WORKSPACE`:

    ```starlark
    npm_import(
        integrity = "sha512-zjQ69G564OCIWIOHSXyQEEDpdpGl+G348RAKY0XXy9Z5kU9Vzv1GMNnkar/ZJ8dzXB3COzD9Mo9NtRZ4xfgUww==",
        package = "@types/node",
        version = "15.12.2",
    )
    ```

    you can use the label `@npm__types_node-15.12.2` in your BUILD files to reference the package.

    > This is similar to Bazel rules in other ecosystems named "_import" like
    > `apple_bundle_import`, `scala_import`, `java_import`, and `py_import`
    > `go_repository` is also a model for this rule.

    The name of this repository should contain the version number, so that multiple versions of the same
    package don't collide.
    (Note that the npm ecosystem always supports multiple versions of a library depending on where
    it is required, unlike other languages like Go or Python.)

    To change the proxy URL we use to fetch, configure the Bazel downloader:
    1. Make a file containing a rewrite rule like

       rewrite (registry.nodejs.org)/(.*) artifactory.build.internal.net/artifactory/$1/$2

    1. To understand the rewrites, see [UrlRewriterConfig] in Bazel sources.

    1. Point bazel to the config with a line in .bazelrc like
        common --experimental_downloader_config=.bazel_downloader_config

    [UrlRewriterConfig]: https://github.com/bazelbuild/bazel/blob/4.2.1/src/main/java/com/google/devtools/build/lib/bazel/repository/downloader/UrlRewriterConfig.java#L66

    Args:
        name: the external repository generated to contain the package content.
            This argument may be omitted to get the default name documented above.
        deps: other npm packages this one depends on.
        integrity: Expected checksum of the file downloaded, in Subresource Integrity format.
            This must match the checksum of the file downloaded.

            This is the same as appears in the yarn.lock or package-lock.json file.

            It is a security risk to omit the checksum as remote files can change.
            At best omitting this field will make your build non-hermetic.
            It is optional to make development easier but should be set before shipping.
        package: npm package name, such as `acorn` or `@types/node`
        version: version of the npm package, such as `8.4.0`
        patches: patch files to apply onto the downloaded npm package.
            Paths in the patch file must start with `extract_tmp/package`
            where `package` is the top-level folder in the archive on npm.
        patch_args: arguments to pass to the patch tool. Defaults to -p0, but
            -p1 will usually be needed for patches generated by git.
    """

    _npm_import(
        name = name or lib.repository_name(package, version),
        deps = deps,
        integrity = integrity,
        package = package,
        patches = patches,
        patch_args = patch_args,
        version = version,
    )

translate_package_lock = repository_rule(
    doc = lib.doc,
    implementation = lib.implementation,
    attrs = lib.attrs,
)
