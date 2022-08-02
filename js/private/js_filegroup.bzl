"""Helper rule to gather files from JsInfo providers of targets and provide them as default outputs"""

load("//js/private:js_binary_helpers.bzl", _gather_files_from_js_providers = "gather_files_from_js_providers")

_DOC = """Gathers files from the JsInfo providers from targets in srcs and provides them as default outputs.

This helper rule is used by the 'js_run_binary' macro.
"""

def _impl(ctx):
    files = _gather_files_from_js_providers(
        targets = ctx.attr.srcs,
        include_transitive_sources = ctx.attr.include_transitive_sources,
        include_declarations = ctx.attr.include_declarations,
        include_npm_linked_packages = ctx.attr.include_npm_linked_packages,
    )
    return DefaultInfo(files = depset(files))

js_filegroup = rule(
    doc = _DOC,
    implementation = _impl,
    attrs = {
        "srcs": attr.label_list(
            doc = """List of targets to gather files from.""",
            allow_files = True,
        ),
        "include_transitive_sources": attr.bool(
            doc = """When True, 'transitive_sources' from 'JsInfo' providers in 'srcs' targets are included in the default outputs of the target.""",
            default = True,
        ),
        "include_declarations": attr.bool(
            doc = """When True, 'declarations' and 'transitive_declarations' from 'JsInfo' providers in srcs targets are included in the default outputs of the target.

            Defaults to false since declarations are generally not needed at runtime and introducing them could slow down developer round trip
            time due to having to generate typings on source file changes.""",
            default = False,
        ),
        "include_npm_linked_packages": attr.bool(
            doc = """When True, files in 'npm_linked_packages' and 'transitive_npm_linked_packages' from 'JsInfo' providers in srcs targets are included in the default outputs of the target.

            'transitive_files' from 'NpmPackageStoreInfo' providers in data targets are also included in the default outputs of the target.
            """,
            default = True,
        ),
    },
    provides = [DefaultInfo],
)
