"""Helper rule to gather files from JsInfo providers of targets and provide them as default outputs"""

load("//js/private:js_helpers.bzl", _gather_files_from_js_info = "gather_files_from_js_info")

_DOC = """Gathers files from the JsInfo providers from targets in srcs and provides them as default outputs.

This helper rule is used by the `js_run_binary` macro.
"""

def _js_info_files_impl(ctx):
    return DefaultInfo(files = _gather_files_from_js_info(
        targets = ctx.attr.srcs,
        include_sources = ctx.attr.include_sources,
        include_transitive_sources = ctx.attr.include_transitive_sources,
        include_declarations = ctx.attr.include_declarations,
        include_transitive_declarations = ctx.attr.include_transitive_declarations,
        include_npm_sources = ctx.attr.include_npm_sources,
    ))

js_info_files = rule(
    doc = _DOC,
    implementation = _js_info_files_impl,
    attrs = {
        "srcs": attr.label_list(
            doc = """List of targets to gather files from.""",
            allow_files = True,
        ),
        "include_sources": attr.bool(
            doc = """When True, `sources` from `JsInfo` providers in `srcs` targets are included in the default outputs of the target.""",
            default = True,
        ),
        "include_transitive_sources": attr.bool(
            doc = """When True, `transitive_sources` from `JsInfo` providers in `srcs` targets are included in the default outputs of the target.""",
            default = True,
        ),
        "include_declarations": attr.bool(
            doc = """When True, `declarations` from `JsInfo` providers in srcs targets are included in the default outputs of the target.

            Defaults to False since declarations are generally not needed at runtime and introducing them could slow down developer round trip
            time due to having to generate typings on source file changes.""",
            default = False,
        ),
        "include_transitive_declarations": attr.bool(
            doc = """When True, `transitive_declarations` from `JsInfo` providers in srcs targets are included in the default outputs of the target.

            Defaults to False since declarations are generally not needed at runtime and introducing them could slow down developer round trip
            time due to having to generate typings on source file changes.""",
            default = False,
        ),
        "include_npm_sources": attr.bool(
            doc = """When True, files in `npm_sources` from `JsInfo` providers in srcs targets are included in the default outputs of the target.

            `transitive_files` from `NpmPackageStoreInfo` providers in data targets are also included in the default outputs of the target.
            """,
            default = True,
        ),
    },
    provides = [DefaultInfo],
)
