"Convert pnpm lock file into starlark Bazel fetches"

load("@bazel_skylib//lib:paths.bzl", "paths")
load("@bazel_skylib//lib:dicts.bzl", "dicts")
load(":pnpm_utils.bzl", "pnpm_utils")
load(":starlark_codegen_utils.bzl", "starlark_codegen_utils")
load(":repo_toolchains.bzl", "node_path", "yq_path")

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
    "custom_postinstalls": attr.string_dict(
        doc = """A map of package names or package names with their version (e.g., "my-package" or "my-package@v1.2.3")
        to a custom postinstall script to apply to the downloaded npm package after its lifecycle scripts runs.
        If the version is left out of the package name, the script will run on every version of the npm package. If
        a custom postinstall scripts exists for a package as well as for a specific version, the script for the versioned package
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
    "run_lifecycle_hooks": attr.bool(
        doc = """If true, runs preinstall, install and postinstall lifecycle hooks on npm packages if they exist""",
        default = True,
    ),
    "node": attr.label(
        doc = """The label to the node binary to use.
        If executing on a windows host, the .exe extension will be appended if there is no .exe, .bat, or .cmd extension on the label.""",
        default = "@nodejs_host//:bin/node",
    ),
    "yq": attr.label(
        doc = """The label to the yq binary to use.
        If executing on a windows host, the .exe extension will be appended if there is no .exe, .bat, or .cmd extension on the label.""",
        default = "@yq//:yq",
    ),
}

def _process_lockfile(rctx):
    json_lockfile_path = rctx.path("pnpm-lock.json")
    result = rctx.execute([yq_path(rctx), "-o=json", ".", rctx.path(rctx.attr.pnpm_lock)])
    if result.return_code != 0:
        fail("failed to convert pnpm lockfile to json: %s" % result.stderr)
    rctx.file(json_lockfile_path, result.stdout)

    translated_json_path = rctx.path("translated.json")
    cmd = [
        node_path(rctx),
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
        version = "{pnpm_version}",{maybe_deps}{maybe_transitive_closure}{maybe_indirect}{maybe_patches}{maybe_patch_args}{maybe_run_lifecycle_hooks}{maybe_custom_postinstall}
    )
"""

_ALIAS_TMPL = \
    """load("//:package.bzl", _package = "package", _package_dir = "package_dir")

alias(
    name = "{basename}",
    actual = _package("{name}"),
    visibility = ["//visibility:public"],
)

alias(
    name = "dir",
    actual = _package_dir("{name}"),
    visibility = ["//visibility:public"],
)"""

_PACKAGE_TMPL = \
    """load("@aspect_rules_js//js/private:pnpm_utils.bzl", _pnpm_utils = "pnpm_utils")

def package(name):
    return Label("@{workspace}//{link_package}:{namespace}{{bazel_name}}".format(
        bazel_name = _pnpm_utils.bazel_name(name),
    ))

def package_dir(name):
    return Label("@{workspace}//{link_package}:{namespace}{{bazel_name}}__dir".format(
        bazel_name = _pnpm_utils.bazel_name(name),
    ))
"""

_BIN_TMPL = \
    """load("@{repo_name}_sources//:package_json.bzl", _bin = "bin")
bin = _bin
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

    generated_by_lines = [
        "\"@generated by @aspect_rules_js//js/private:translate_pnpm_lock.bzl from pnpm lock file @{pnpm_lock_wksp}{pnpm_lock}\"".format(
            pnpm_lock_wksp = str(rctx.attr.pnpm_lock.workspace_name),
            pnpm_lock = str(rctx.attr.pnpm_lock),
        ),
        "",  # empty line after bzl docstring since buildifier expects this if this file is vendored in
    ]

    repositories_bzl = generated_by_lines + [
        """load("@aspect_rules_js//js:npm_import.bzl", "npm_import")""",
        "",
        "def npm_repositories():",
        "    \"Generated npm_import repository rules corresponding to npm packages in @{pnpm_lock_wksp}{pnpm_lock}\"".format(
            pnpm_lock_wksp = str(rctx.attr.pnpm_lock.workspace_name),
            pnpm_lock = str(rctx.attr.pnpm_lock),
        ),
    ]

    link_js_package_bzl_file = "link_js_packages.bzl"
    link_js_package_bzl_header = list(generated_by_lines)  # deep copy
    link_js_package_bzl_body = [
        """
# buildifier: disable=unnamed-macro
def link_js_packages():
    "Generated list of link_js_package target generators corresponding to npm packages in @{pnpm_lock_wksp}{pnpm_lock}"
    if "{link_package_guard}" != "." and native.package_name() != "{link_package_guard}":
        fail("The link_js_packages() macro loaded from {link_js_package_bzl_file} may only be called in the '{link_package_guard}' package. Move the call to the '{link_package_guard}' package BUILD file.")
""".format(
            link_package_guard = link_package,
            link_js_package_bzl_file = "@{}//:{}".format(rctx.name, link_js_package_bzl_file),
            pnpm_lock_wksp = str(rctx.attr.pnpm_lock.workspace_name),
            pnpm_lock = str(rctx.attr.pnpm_lock),
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

        custom_postinstall = rctx.attr.custom_postinstalls.get(name)
        if not custom_postinstall:
            custom_postinstall = rctx.attr.custom_postinstalls.get(friendly_name)
        elif rctx.attr.custom_postinstalls.get(friendly_name):
            custom_postinstall = "%s && %s" % (custom_postinstall, rctx.attr.custom_postinstalls.get(friendly_name))

        repo_name = "%s__%s" % (rctx.name, pnpm_utils.bazel_name(name, pnpm_version))

        indirect = False if package in direct_dependencies else True

        run_lifecycle_hooks = requires_build and rctx.attr.run_lifecycle_hooks and name not in rctx.attr.lifecycle_hooks_exclude and friendly_name not in rctx.attr.lifecycle_hooks_exclude

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
        maybe_custom_postinstall = ("""
        custom_postinstall = \"%s\",""" % custom_postinstall) if custom_postinstall else ""
        maybe_run_lifecycle_hooks = ("""
        run_lifecycle_hooks = True,""") if run_lifecycle_hooks else ""

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
            maybe_run_lifecycle_hooks = maybe_run_lifecycle_hooks,
            maybe_custom_postinstall = maybe_custom_postinstall,
        ))

        link_js_package_bzl_header.append(
            """load("@{repo_name}//:link_js_package.bzl", link_{i} = "link_js_package")""".format(
                i = i,
                repo_name = repo_name,
            ),
        )
        link_js_package_bzl_body.append("    link_{i}()".format(i = i))

        if not indirect:
            # For direct dependencies create alias targets @repo_name//name, @repo_name//@scope/name,
            # @repo_name//name:dir and @repo_name//@scope/name:dir
            rctx.file("%s/BUILD.bazel" % name, "\n".join(generated_by_lines + [
                _ALIAS_TMPL.format(
                    basename = paths.basename(name),
                    name = name,
                ),
            ]))

            if has_bin:
                # Generate a package_json.bzl file if there are bin entries
                rctx.file("%s/package_json.bzl" % name, "\n".join([
                    _BIN_TMPL.format(
                        repo_name = repo_name,
                        name = name,
                    ),
                ]))

    package_bzl = generated_by_lines + [
        _PACKAGE_TMPL.format(
            workspace = rctx.attr.pnpm_lock.workspace_name,
            link_package = link_package,
            namespace = pnpm_utils.js_package_target_namespace,
        ),
    ]

    rctx.file("repositories.bzl", "\n".join(repositories_bzl))
    rctx.file(link_js_package_bzl_file, "\n".join(link_js_package_bzl_header + link_js_package_bzl_body))
    rctx.file("package.bzl", "\n".join(package_bzl))
    rctx.file("BUILD.bazel", "exports_files([\"repositories.bzl\", \"link_js_packages.bzl\", \"package.bzl\"])")

translate_pnpm_lock = struct(
    doc = _DOC,
    implementation = _impl,
    attrs = _ATTRS,
)

translate_pnpm_lock_testonly = struct(
    testonly_process_lockfile = _process_lockfile,
)
