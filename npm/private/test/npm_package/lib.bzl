"""
Test rule to create a lib with a DefaultInfo and a DeclarationInfo
"""

load("@rules_nodejs//nodejs:providers.bzl", "DeclarationInfo", "declaration_info")

_attrs = {
    "srcs": attr.label_list(allow_files = True),
    "decl": attr.label_list(allow_files = True),
}

def _impl(ctx):
    return [
        DefaultInfo(files = depset(ctx.files.srcs)),
        declaration_info(declarations = depset(ctx.files.decl)),
    ]

lib = rule(
    implementation = _impl,
    attrs = _attrs,
    provides = [DefaultInfo, DeclarationInfo],
)
