"""Private rule for extracting pnpm catalog definitions."""

def _pnpm_extract_catalogs_impl(ctx):
    output = ctx.actions.declare_file("catalogs.json")

    args = ctx.actions.args()
    args.add("--workspace-manifest", ctx.file.workspace_manifest)
    args.add("--output", output)

    ctx.actions.run(
        executable = ctx.executable._extract_tool,
        arguments = [args],
        inputs = [ctx.file.workspace_manifest],
        outputs = [output],
        env = {"BAZEL_BINDIR": ctx.bin_dir.path},
    )

    return [DefaultInfo(files = depset([output]))]

pnpm_extract_catalogs = rule(
    implementation = _pnpm_extract_catalogs_impl,
    attrs = {
        "workspace_manifest": attr.label(
            allow_single_file = True,
            default = "//:pnpm-workspace.yaml",
            doc = "The pnpm-workspace.yaml file to extract catalogs from",
        ),
        "_extract_tool": attr.label(
            executable = True,
            cfg = "exec",
            default = "@aspect_rules_js//npm/private:pnpm_extract_catalogs_bin",
        ),
    },
    doc = "Extracts catalog/catalogs sections from pnpm-workspace.yaml into a JSON file",
)
