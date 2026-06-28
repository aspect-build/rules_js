"""Rule for building npm packages in pnpm workspaces.

Wraps the upstream npm_package rule, adding a build-time transform that resolves
pnpm workspace protocols (catalog:, workspace:, etc.) in package.json, mirroring
what pnpm publish does before packing.

Load with:

```starlark
load("@aspect_rules_js//npm:defs.bzl", "pnpm_package")
```
"""

load(":npm_package.bzl", _npm_package = "npm_package")
load(":pnpm_package_json_transform.bzl", _pnpm_package_json_transform = "pnpm_package_json_transform")

def _runfiles_path(ctx, f):
    p = f.short_path
    if p.startswith("../"):
        return p[3:]
    return ctx.workspace_name + "/" + p

def _pnpm_publish_impl(ctx):
    launcher = ctx.actions.declare_file(ctx.label.name + ".sh")

    pnpm_bin = ctx.executable._pnpm
    pkg_dir = ctx.attr.pkg[DefaultInfo].files.to_list()[0]

    pnpm_path = _runfiles_path(ctx, pnpm_bin)
    pkg_path = _runfiles_path(ctx, pkg_dir)

    ctx.actions.write(
        output = launcher,
        content = """\
#!/usr/bin/env bash
set -euo pipefail

# Resolve the runfiles directory
if [[ -d "$0.runfiles" ]]; then
    RUNFILES="$0.runfiles"
elif [[ "${{RUNFILES_DIR:-}}" ]]; then
    RUNFILES="${{RUNFILES_DIR}}"
else
    echo >&2 "ERROR: Cannot find runfiles directory"
    exit 1
fi

exec "${{RUNFILES}}/{pnpm}" publish --no-git-checks "${{RUNFILES}}/{pkg}" {extra_args} "$@"
""".format(
            pnpm = pnpm_path,
            pkg = pkg_path,
            extra_args = " ".join(["'%s'" % a for a in ctx.attr.extra_args]),
        ),
        is_executable = True,
    )

    runfiles = ctx.runfiles(files = [launcher, pkg_dir])
    runfiles = runfiles.merge(ctx.attr._pnpm[DefaultInfo].default_runfiles)
    runfiles = runfiles.merge(ctx.attr.pkg[DefaultInfo].default_runfiles)

    return [DefaultInfo(
        executable = launcher,
        runfiles = runfiles,
    )]

_pnpm_publish = rule(
    implementation = _pnpm_publish_impl,
    executable = True,
    attrs = {
        "pkg": attr.label(
            mandatory = True,
            doc = "The npm_package target to publish",
        ),
        "extra_args": attr.string_list(
            doc = "Additional arguments passed to pnpm publish",
        ),
        "_pnpm": attr.label(
            executable = True,
            cfg = "target",
            default = "@pnpm//:pnpm",
        ),
    },
)

def pnpm_package(
        name,
        srcs,
        pnpm_catalogs,
        package_json = "package.json",
        node_modules = None,
        version = None,
        stamped = False,
        publishable = False,
        tag = "latest",
        **kwargs):
    """Creates an npm package with pnpm-compatible package.json transforms.

    Wraps the upstream rules_js npm_package rule, adding a build-time transform
    that resolves pnpm workspace protocols (catalog:, workspace:, etc.) in
    package.json, mirroring what pnpm publish does before packing.

    Use `pnpm_extract_catalogs` in your workspace root to generate the catalogs
    JSON file from pnpm-workspace.yaml:

    ```starlark
    load("@aspect_rules_js//npm:defs.bzl", "pnpm_extract_catalogs")

    pnpm_extract_catalogs(
        name = "pnpm_catalogs",
        visibility = ["//visibility:public"],
    )
    ```

    Then reference it in your pnpm_package targets:

    ```starlark
    load("@aspect_rules_js//npm:defs.bzl", "pnpm_package")

    pnpm_package(
        name = "my_package",
        srcs = [":my_lib"],
        pnpm_catalogs = "//:pnpm_catalogs",
    )
    ```

    Args:
        name: Target name
        srcs: Source files to include in the package (excluding package.json)
        pnpm_catalogs: Label of the pnpm_extract_catalogs target providing catalog definitions
        package_json: The package.json file to transform (default: "package.json")
        node_modules: The node_modules target for resolving workspace: protocols.
            Defaults to `:node_modules` in the calling package.
        version: Override the version in the output package.json
        stamped: When True, appends BUILD_TIMESTAMP-SHORT_GIT_COMMIT to the version
        publishable: When True, also creates a {name}.publish target
        tag: The dist-tag to use when publishing (default: "latest")
        **kwargs: Additional arguments passed to the upstream npm_package rule
    """
    if node_modules == None:
        node_modules = "//" + native.package_name() + ":node_modules"

    transform_name = name + "_package_json"

    transform_kwargs = {}
    if version:
        transform_kwargs["version"] = version
    if stamped:
        transform_kwargs["stamped"] = True

    _pnpm_package_json_transform(
        name = transform_name,
        package_json = package_json,
        pnpm_catalogs = pnpm_catalogs,
        node_modules = node_modules,
        tags = kwargs.get("tags", []) + ["manual"],
        **transform_kwargs
    )

    if publishable:
        _pnpm_publish(
            name = "{}.publish".format(name),
            pkg = name,
            extra_args = ["--tag", tag],
            tags = kwargs.get("tags", []) + ["manual"],
            testonly = kwargs.get("testonly", False),
            visibility = kwargs.get("visibility", None),
        )

    replace_prefixes = dict(kwargs.pop("replace_prefixes", {}))
    replace_prefixes[transform_name + "/"] = ""

    npm_package_kwargs = dict(kwargs)
    if version:
        npm_package_kwargs["version"] = version

    _npm_package(
        name = name,
        srcs = srcs + [":" + transform_name],
        replace_prefixes = replace_prefixes,
        **npm_package_kwargs
    )
