"""Rule for building npm packages in pnpm workspaces.

Wraps the upstream npm_package rule, adding a build-time transform that resolves
pnpm workspace protocols (catalog:, workspace:, etc.) in package.json, mirroring
what pnpm publish does before packing.

Load with:

```starlark
load("@aspect_rules_js//npm:defs.bzl", "pnpm_package")
```
"""

load("//js:defs.bzl", "js_binary")
load(":npm_package.bzl", _npm_package = "npm_package")
load(":pnpm_package_json_transform.bzl", _pnpm_package_json_transform = "pnpm_package_json_transform")

def pnpm_package(
        name,
        srcs,
        pnpm_catalogs,
        package_json = "package.json",
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
        package = "@my-scope/my-package",
    )
    ```

    Args:
        name: Target name
        srcs: Source files to include in the package (excluding package.json)
        pnpm_catalogs: Label of the pnpm_extract_catalogs target providing catalog definitions
        package_json: The package.json file to transform (default: "package.json")
        version: Override the version in the output package.json
        stamped: When True, appends BUILD_TIMESTAMP-SHORT_GIT_COMMIT to the version
        publishable: When True, also creates a {name}.publish target
        tag: The dist-tag to use when publishing (default: "latest")
        **kwargs: Additional arguments passed to the upstream npm_package rule
    """
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
        tags = kwargs.get("tags", []) + ["manual"],
        **transform_kwargs
    )

    if publishable:
        js_binary(
            name = "{}.publish".format(name),
            entry_point = Label("@aspect_rules_js//npm/private/pnpm_publish_tools/min:pnpm_publish_mjs"),
            fixed_args = [
                "./$(rootpath :{})".format(name),
                "--tag",
                tag,
            ],
            data = [name],
            include_npm = True,
            tags = kwargs.get("tags", []) + ["manual"],
            testonly = kwargs.get("testonly", False),
            visibility = kwargs.get("visibility", None),
        )

    replace_prefixes = dict(kwargs.pop("replace_prefixes", {}))
    replace_prefixes[transform_name + "/"] = ""

    _npm_package(
        name = name,
        srcs = srcs + [":" + transform_name],
        replace_prefixes = replace_prefixes,
        **kwargs
    )
