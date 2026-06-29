"""Macro for extracting pnpm catalog definitions from pnpm-workspace.yaml.

Uses yq to select the catalog/catalogs sections and emit a JSON file
mapping catalog names to {package: version} dicts. The unnamed catalog:
section is keyed as "default".
"""

load("@yq.bzl//yq:yq.bzl", "yq")

def pnpm_extract_catalogs(
        name,
        workspace_manifest = "//:pnpm-workspace.yaml",
        **kwargs):
    """Extracts catalog/catalogs sections from pnpm-workspace.yaml into a JSON file.

    Args:
        name: Target name. Output will be catalogs.json.
        workspace_manifest: The pnpm-workspace.yaml file to extract catalogs from.
            Defaults to //:pnpm-workspace.yaml.
        **kwargs: Additional arguments passed to the underlying yq rule.
    """
    yq(
        name = name,
        srcs = [workspace_manifest],
        expression = '{"default": .catalog} * (.catalogs // {}) | with_entries(select(.value != null))',
        args = ["-o=json"],
        outs = ["catalogs.json"],
        **kwargs
    )
