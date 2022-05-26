"linked_js_packages rule"

load("@rules_nodejs//nodejs:providers.bzl", "DeclarationInfo", "declaration_info")
load(":link_js_package.bzl", _link_js_package_direct_lib = "link_js_package_direct_lib")

_DOC = """Combines multiple link_js_package_direct targets into a single target.

New target provides DefaultInfo and DeclarationInfo but does not forward the
_LinkJsPackageInfo of srcs.

For internal use only. Used for create `@npm//@scope` targets.
"""

_ATTRS = {
    "srcs": attr.label_list(
        doc = """The link_js_package targets to forward.""",
        providers = _link_js_package_direct_lib.provides,
        mandatory = True,
    ),
}

def _impl(ctx):
    files_depsets = []
    runfiles = ctx.runfiles()

    for src in ctx.attr.srcs:
        files_depsets.append(src[DefaultInfo].files)
        runfiles = runfiles.merge(src[DefaultInfo].data_runfiles)

    result = [
        DefaultInfo(
            files = depset(transitive = files_depsets),
            runfiles = runfiles,
        ),
        declaration_info(declarations = depset(), deps = ctx.attr.srcs),
    ]

    return result

linked_js_packages = rule(
    doc = _DOC,
    implementation = _impl,
    attrs = _ATTRS,
    provides = [DefaultInfo, DeclarationInfo],
)
