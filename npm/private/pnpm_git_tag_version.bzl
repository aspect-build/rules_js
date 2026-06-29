"""Rule for extracting package versions from git tags.

Example usage:

```starlark
load("@aspect_rules_js//npm:defs.bzl", "pnpm_package")
load("@aspect_rules_js//npm/private:pnpm_git_tag_version.bzl", "pnpm_git_tag_version")

pnpm_git_tag_version(
    name = "version",
    prefix = "@internal/my-package",
    fallback = "0.0.0-development",
)

pnpm_package(
    name = "pkg",
    srcs = [":lib"],
    version = ":version",
)
```

Given git tags like `@internal/my-package@1.2.3`, this extracts `1.2.3` as the version.
The latest matching tag (by semver sort) is used.
"""

def _pnpm_git_tag_version_impl(ctx):
    output = ctx.actions.declare_file(ctx.label.name + ".version")

    ctx.actions.run_shell(
        outputs = [output],
        command = """\
prefix="$1"
fallback="$2"
output="$3"
version=$(git tag -l "${prefix}@*" --sort=-v:refname | head -1 | sed 's/.*@//')
if [ -z "$version" ]; then
    version="${fallback}"
fi
printf '%s' "$version" > "${output}"
""",
        arguments = [ctx.attr.prefix, ctx.attr.fallback, output.path],
        execution_requirements = {
            "local": "1",
            "no-sandbox": "1",
        },
    )

    return [DefaultInfo(files = depset([output]))]

pnpm_git_tag_version = rule(
    implementation = _pnpm_git_tag_version_impl,
    attrs = {
        "prefix": attr.string(
            mandatory = True,
            doc = "Git tag prefix to match, e.g. '@internal/my-package'. Tags should be in the format '<prefix>@<version>'.",
        ),
        "fallback": attr.string(
            default = "0.0.0-development",
            doc = "Version to use when no matching git tag is found",
        ),
    },
    doc = "Extracts a package version from git tags matching the given prefix.",
)
