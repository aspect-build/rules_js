"npm_linked_packages rule"

load("@rules_nodejs//nodejs:providers.bzl", "DeclarationInfo", "declaration_info")
load(":npm_linked_package_info.bzl", "NpmLinkedPackageInfo")

_DOC = """Combines multiple linked npm targets into a single target.

New target provides DefaultInfo and DeclarationInfo.

For internal use only. Used for create `@npm//@scope` targets.
"""

_ATTRS = {
    "srcs": attr.label_list(
        doc = """The linked npm targets to forward.""",
        providers = [NpmLinkedPackageInfo],
        mandatory = True,
    ),
}

def _impl(ctx):
    result = [
        DefaultInfo(
            files = depset(transitive = [
                target[DefaultInfo].files
                for target in ctx.attr.srcs
            ]),
            runfiles = ctx.runfiles().merge_all([
                target[DefaultInfo].default_runfiles
                for target in ctx.attr.srcs
            ]),
        ),
        declaration_info(declarations = depset(), deps = ctx.attr.srcs),
    ]

    return result

npm_linked_packages = rule(
    doc = _DOC,
    implementation = _impl,
    attrs = _ATTRS,
    provides = [DefaultInfo, DeclarationInfo],
)
