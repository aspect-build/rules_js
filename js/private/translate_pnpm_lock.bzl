"Convert pnpm lock file into starlark Bazel fetches"

load("@aspect_bazel_lib//lib:repo_utils.bzl", "is_windows_host")
load("@aspect_bazel_lib_host//:defs.bzl", "host")
load("@bazel_skylib//lib:paths.bzl", "paths")
load("@bazel_skylib//lib:dicts.bzl", "dicts")
load(":pnpm_utils.bzl", "pnpm_utils")
load(":starlark_codegen_utils.bzl", "starlark_codegen_utils")

_DOC = """Repository rule to generate npm_import rules from pnpm lock file.

The pnpm lockfile format includes all the information needed to define npm_import rules,
including the integrity hash, as calculated by the package manager.

For more details see, https://github.com/pnpm/pnpm/blob/main/packages/lockfile-types/src/index.ts.

Instead of manually declaring the `npm_imports`, this helper generates an external repository
containing a helper starlark module `repositories.bzl`, which supplies a loadable macro
`npm_repositories`. This macro creates an `npm_import` for each package.

The generated repository also contains BUILD files declaring targets for the packages
listed as `dependencies` or `devDependencies` in `package.json`, so you can declare
dependencies on those packages without having to repeat version information.

Bazel will only fetch the packages which are required for the requested targets to be analyzed.
Thus it is performant to convert a very large pnpm-lock.yaml file without concern for
users needing to fetch many unnecessary packages.

**Setup**

In `WORKSPACE`, call the repository rule pointing to your pnpm-lock.yaml file:

```starlark
load("@aspect_rules_js//js:npm_import.bzl", "translate_pnpm_lock")

# Read the pnpm-lock.yaml file to automate creation of remaining npm_import rules
translate_pnpm_lock(
    # Creates a new repository named "@npm_deps"
    name = "npm_deps",
    pnpm_lock = "//:pnpm-lock.yaml",
)
```

Next, there are two choices, either load from the generated repo or check in the generated file.
The tradeoffs are similar to
[this rules_python thread](https://github.com/bazelbuild/rules_python/issues/608).

1. Immediately load from the generated `repositories.bzl` file in `WORKSPACE`.
This is similar to the 
[`pip_parse`](https://github.com/bazelbuild/rules_python/blob/main/docs/pip.md#pip_parse)
rule in rules_python for example.
It has the advantage of also creating aliases for simpler dependencies that don't require
spelling out the version of the packages.
However it causes Bazel to eagerly evaluate the `translate_pnpm_lock` rule for every build,
even if the user didn't ask for anything JavaScript-related.

```starlark
load("@npm_deps//:repositories.bzl", "npm_repositories")

npm_repositories()
```

In BUILD files, declare dependencies on the packages using the same external repository.

Following the same example, this might look like:

```starlark
js_test(
    name = "test_test",
    data = ["@npm_deps//@types/node"],
    entry_point = "test.js",
)
```

2. Check in the `repositories.bzl` file to version control, and load that instead.
This makes it easier to ship a ruleset that has its own npm dependencies, as users don't
have to install those dependencies. It also avoids eager-evaluation of `translate_pnpm_lock`
for builds that don't need it.
This is similar to the [`update-repos`](https://github.com/bazelbuild/bazel-gazelle#update-repos)
approach from bazel-gazelle.

In a BUILD file, use a rule like
[write_source_files](https://github.com/aspect-build/bazel-lib/blob/main/docs/write_source_files.md)
to copy the generated file to the repo and test that it stays updated:

```starlark
write_source_files(
    name = "update_repos",
    files = {
        "repositories.bzl": "@npm_deps//:repositories.bzl",
    },
)
```

Then in `WORKSPACE`, load from that checked-in copy or instruct your users to do so.
In this case, the aliases are not created, so you get only the `npm_import` behavior
and must depend on packages with their versioned label like `@npm__types_node-15.12.2`.
"""

_ATTRS = {
    "pnpm_lock": attr.label(
        doc = """The pnpm-lock.yaml file.""",
        mandatory = True,
    ),
    "package": attr.string(
        default = ".",
        doc = """The package to "link" the generated npm dependencies to. By default, the package of the pnpm_lock
        target is used.""",
    ),
    "patches": attr.string_list_dict(
        doc = """A map of package names or package names with their version (e.g., "my-package" or "my-package@v1.2.3")
        to a label list of patches to apply to the downloaded npm package. Paths in the patch
        file must start with `extract_tmp/package` where `package` is the top-level folder in
        the archive on npm. If the version is left out of the package name, the patch will be
        applied to every version of the npm package.""",
    ),
    "patch_args": attr.string_list_dict(
        doc = """A map of package names or package names with their version (e.g., "my-package" or "my-package@v1.2.3")
        to a label list arguments to pass to the patch tool. Defaults to -p0, but -p1 will
        usually be needed for patches generated by git. If patch args exists for a package
        as well as a package version, then the version-specific args will be appended to the args for the package.""",
    ),
    "postinstall": attr.string_dict(
        doc = """A map of package names or package names with their version (e.g., "my-package" or "my-package@v1.2.3")
        to a string postinstall script to apply to the downloaded npm package after its existing postinstall script runs.
        If the version is left out of the package name, the script will run on every version of the npm package. If
        postinstall scripts exists for a package as well as for a specific version, the script for the versioned package
        will be appended with `&&` to the non-versioned package script.""",
    ),
    "prod": attr.bool(
        doc = """If true, only install dependencies""",
    ),
    "dev": attr.bool(
        doc = """If true, only install devDependencies""",
    ),
    "no_optional": attr.bool(
        doc = """If true, optionalDependencies are not installed""",
    ),
    "lifecycle_hooks_exclude": attr.string_list(
        doc = """A list of package names or package names with their version (e.g., "my-package" or "my-package@v1.2.3")
        to not run lifecycle hooks on""",
    ),
    "enable_lifecycle_hooks": attr.bool(
        doc = """If true, runs lifecycle hooks on installed packages as well as any custom postinstall scripts""",
        default = True,
    ),
    "node_repository": attr.string(
        doc = """The basename for the node toolchain repository from @build_bazel_rules_nodejs.""",
        default = "nodejs",
    ),
    "yq": attr.label(
        doc = """The label to the yq binary to use.""",
        default = "@yq_{0}//:yq{1}".format(host.platform, host.exe_if_windows),
    ),
    "yq_path": attr.label(
        doc = """The path to the yq binary to use. If set, this is used instead of the `yq` attribute""",
    ),
}

def _yq_path(rctx):
    return rctx.path(rctx.attr.yq_path) if rctx.attr.yq_path else rctx.path(rctx.attr.yq)

def _node_bin(rctx):
    # Parse the resolved host platform from yq host repo //:index.bzl
    content = rctx.read(rctx.path(Label("@%s_host//:index.bzl" % rctx.attr.node_repository)))
    search_str = "host_platform=\""
    start_index = content.index(search_str) + len(search_str)
    end_index = content.index("\"", start_index)
    host_platform = content[start_index:end_index]

    # Return the path to the node binary
    return rctx.path(Label("@%s_%s//:bin/node%s" % (rctx.attr.node_repository, host_platform, ".exe" if is_windows_host(rctx) else "")))

def _process_lockfile(rctx):
    json_lockfile_path = rctx.path("pnpm-lock.json")
    result = rctx.execute([_yq_path(rctx), "-o=json", ".", rctx.path(rctx.attr.pnpm_lock)])
    if result.return_code != 0:
        fail("failed to convert pnpm lockfile to json: %s" % result.stderr)
    rctx.file(json_lockfile_path, result.stdout)

    translated_json_path = rctx.path("translated.json")
    cmd = [
        _node_bin(rctx),
        rctx.path(Label("@aspect_rules_js//js/private:translate_pnpm_lock.js")),
        json_lockfile_path,
        translated_json_path,
    ]
    env = {}
    if rctx.attr.prod:
        env.append("TRANSLATE_PACKAGE_LOCK_PROD")
    if rctx.attr.dev:
        env.append("TRANSLATE_PACKAGE_LOCK_DEV")
    if rctx.attr.no_optional:
        env.append("TRANSLATE_PACKAGE_LOCK_NO_OPTIONAL")
    result = rctx.execute(cmd, environment = env, quiet = False)
    if result.return_code:
        fail("translate_pnpm_lock.js failed: %s" % result.stderr)
    return json.decode(rctx.read(translated_json_path))

_NPM_IMPORT_TMPL = \
    """    npm_import(
        name = "{name}",
        integrity = "{integrity}",
        link_package_guard = "{link_package_guard}",
        package = "{package}",
        version = "{pnpm_version}",{maybe_deps}{maybe_transitive_closure}{maybe_indirect}{maybe_patches}{maybe_patch_args}{maybe_postinstall}{maybe_enable_lifecycle_hooks}
    )
"""

_ALIAS_TMPL = \
    """load("//:package.bzl", "package", "package_dir")

alias(
    name = "{basename}",
    actual = package("{name}"),
    visibility = ["//visibility:public"],
)

alias(
    name = "dir",
    actual = package_dir("{name}"),
    visibility = ["//visibility:public"],
)"""

_PACKAGE_TMPL = \
    """
load("@aspect_rules_js//js/private:pnpm_utils.bzl", "pnpm_utils")

def package(name):
    return Label("@{workspace}//{link_package}:{{namespace}}{{bazel_name}}".format(
        namespace = pnpm_utils.node_package_target_namespace,
        bazel_name = pnpm_utils.bazel_name(name),
    ))

def package_dir(name):
    return Label("@{workspace}//{link_package}:{{namespace}}{{bazel_name}}__dir".format(
        namespace = pnpm_utils.node_package_target_namespace,
        bazel_name = pnpm_utils.bazel_name(name),
    ))
"""

def _impl(rctx):
    if rctx.attr.prod and rctx.attr.dev:
        fail("prod and dev attributes cannot both be set to true")

    lockfile = _process_lockfile(rctx)

    link_package = rctx.attr.package
    if link_package == ".":
        link_package = rctx.attr.pnpm_lock.package

    direct_dependencies = lockfile.get("dependencies")
    packages = lockfile.get("packages")

    repositories_bzl = [
        """load("@aspect_rules_js//js:npm_import.bzl", "npm_import")""",
        "",
        "# buildifier: disable=function-docstring",
        "def npm_repositories():",
    ]

    node_modules_bzl_file = "node_modules.bzl"
    node_modules_header_bzl = []
    node_modules_bzl = [
        """# buildifier: disable=function-docstring
def node_modules():
    if "{link_package_guard}" != "." and native.package_name() != "{link_package_guard}":
        fail("The node_modules() macro loaded from {node_modules_bzl} may only be called in the '{link_package_guard}' package. Move the call to the '{link_package_guard}' package BUILD file.")
""".format(
            link_package_guard = link_package,
            node_modules_bzl = "@%s//:%s" % (rctx.name, node_modules_bzl_file),
        ),
    ]

    for (i, v) in enumerate(packages.items()):
        (package, package_info) = v
        name = package_info.get("name")
        pnpm_version = package_info.get("pnpmVersion")
        deps = package_info.get("dependencies")
        optional_deps = package_info.get("optionalDependencies")
        dev = package_info.get("dev")
        optional = package_info.get("optional")
        has_bin = package_info.get("hasBin")
        requires_build = package_info.get("requiresBuild")
        integrity = package_info.get("integrity")
        transitive_closure = package_info.get("transitiveClosure")

        if rctx.attr.prod and dev:
            # when prod attribute is set, skip devDependencies
            continue
        if rctx.attr.dev and not dev:
            # when dev attribute is set, skip (non-dev) dependencies
            continue
        if rctx.attr.no_optional and optional:
            # when no_optional attribute is set, skip optionalDependencies
            continue

        if not rctx.attr.no_optional:
            deps = dicts.add(optional_deps, deps)

        friendly_name = pnpm_utils.friendly_name(name, pnpm_utils.strip_peer_dep_version(pnpm_version))

        patches = rctx.attr.patches.get(name, [])[:]
        patches.extend(rctx.attr.patches.get(friendly_name, []))

        patch_args = rctx.attr.patch_args.get(name, [])[:]
        patch_args.extend(rctx.attr.patch_args.get(friendly_name, []))

        postinstall = rctx.attr.postinstall.get(name)
        if not postinstall:
            postinstall = rctx.attr.postinstall.get(friendly_name)
        elif rctx.attr.postinstall.get(friendly_name):
            postinstall = "%s && %s" % (postinstall, rctx.attr.postinstall.get(friendly_name))

        repo_name = "%s__%s" % (rctx.name, pnpm_utils.bazel_name(name, pnpm_version))

        indirect = False if package in direct_dependencies else True

        lifecycle_hooks_exclude = not rctx.attr.enable_lifecycle_hooks or name in rctx.attr.lifecycle_hooks_exclude or friendly_name in rctx.attr.lifecycle_hooks_exclude

        maybe_indirect = """
        indirect = True,""" if indirect else ""
        maybe_deps = ("""
        deps = %s,""" % starlark_codegen_utils.to_dict_attr(deps, 2)) if len(deps) > 0 else ""
        maybe_transitive_closure = ("""
        transitive_closure = %s,""" % starlark_codegen_utils.to_dict_list_attr(transitive_closure, 2)) if len(transitive_closure) > 0 else ""
        maybe_patches = ("""
        patches = %s,""" % patches) if len(patches) > 0 else ""
        maybe_patch_args = ("""
        patch_args = %s,""" % patch_args) if len(patches) > 0 and len(patch_args) > 0 else ""
        maybe_postinstall = ("""
        postinstall = \"%s\",""" % postinstall) if postinstall else ""
        maybe_enable_lifecycle_hooks = """
        enable_lifecycle_hooks = False,""" if lifecycle_hooks_exclude else ""

        repositories_bzl.append(_NPM_IMPORT_TMPL.format(
            name = repo_name,
            link_package_guard = link_package,
            package = name,
            pnpm_version = pnpm_version,
            integrity = integrity,
            maybe_indirect = maybe_indirect,
            maybe_deps = maybe_deps,
            maybe_transitive_closure = maybe_transitive_closure,
            maybe_patches = maybe_patches,
            maybe_patch_args = maybe_patch_args,
            maybe_postinstall = maybe_postinstall,
            maybe_enable_lifecycle_hooks = maybe_enable_lifecycle_hooks,
        ))

        node_modules_header_bzl.append(
            """load("@{repo_name}//:node_package.bzl", node_package_{i} = "node_package")""".format(
                i = i,
                repo_name = repo_name,
            ),
        )
        node_modules_bzl.append("    node_package_{i}()".format(i = i))

        if not indirect:
            # For direct dependencies create alias targets @repo_name//name, @repo_name//@scope/name,
            # @repo_name//name:dir and @repo_name//@scope/name:dir
            rctx.file("%s/BUILD.bazel" % name, _ALIAS_TMPL.format(
                basename = paths.basename(name),
                name = name,
            ))

    package_bzl = [_PACKAGE_TMPL.format(
        workspace = rctx.attr.pnpm_lock.workspace_name,
        link_package = link_package,
    )]

    generated_by_line = ["\"@generated by translate_pnpm_lock.bzl from {pnpm_lock}\"".format(pnpm_lock = str(rctx.attr.pnpm_lock))]
    empty_line = [""]

    rctx.file("repositories.bzl", "\n".join(generated_by_line + empty_line + repositories_bzl))
    rctx.file(node_modules_bzl_file, "\n".join(generated_by_line + empty_line + node_modules_header_bzl + empty_line + node_modules_bzl + empty_line))
    rctx.file("package.bzl", "\n".join(generated_by_line + package_bzl))
    rctx.file("BUILD.bazel", "exports_files([\"repositories.bzl\", \"node_modules.bzl\", \"package.bzl\"])")

translate_pnpm_lock = struct(
    doc = _DOC,
    implementation = _impl,
    attrs = _ATTRS,
)

translate_pnpm_lock_testonly = struct(
    testonly_process_lockfile = _process_lockfile,
)
