"""Private rule for transforming package.json to resolve pnpm workspace protocols."""

def _pnpm_package_json_transform_impl(ctx):
    output = ctx.actions.declare_file("package.json")

    version = ctx.attr.version
    if version and ctx.attr.stamped:
        version = "{}-{}-{}".format(
            version,
            ctx.var["BUILD_TIMESTAMP"],
            ctx.var["SHORT_GIT_COMMIT"],
        )

    args = ctx.actions.args()
    args.add("--catalogs-json", ctx.file.pnpm_catalogs)
    args.add("--package-json", ctx.file.package_json)
    args.add("--output", output)
    if version:
        args.add("--version", version)

    inputs = [ctx.file.pnpm_catalogs, ctx.file.package_json]

    ctx.actions.run(
        executable = ctx.executable._transform_tool,
        arguments = [args],
        inputs = inputs,
        outputs = [output],
        env = {"BAZEL_BINDIR": ctx.bin_dir.path},
    )

    return [DefaultInfo(files = depset([output]))]

pnpm_package_json_transform = rule(
    implementation = _pnpm_package_json_transform_impl,
    attrs = {
        "package_json": attr.label(
            allow_single_file = True,
            mandatory = True,
            doc = "The package.json file to transform",
        ),
        "pnpm_catalogs": attr.label(
            allow_single_file = True,
            mandatory = True,
            doc = "The extracted catalogs JSON file from pnpm_extract_catalogs",
        ),
        "stamped": attr.bool(
            default = False,
            doc = "When True, appends BUILD_TIMESTAMP-SHORT_GIT_COMMIT to the version",
        ),
        "version": attr.string(
            doc = "Override the version in the output package.json",
        ),
        "_transform_tool": attr.label(
            executable = True,
            cfg = "exec",
            default = "@aspect_rules_js//npm/private/pnpm_publish_tools/min:pnpm_package_json_transform_bin",
        ),
    },
    doc = "Transforms package.json to resolve pnpm workspace protocols (catalog:, workspace:, etc.)",
)
