"""Module extension for consuming Yarn PnP zero-install projects.

Experimental. Usage in MODULE.bazel:

    pnp = use_extension("@aspect_rules_js//npm/private/pnp:pnp_extension.bzl", "pnp")
    pnp.install(
        name = "pnp",
        cache = "//:pnp_cache",
        pnp_cjs = "//:.pnp.cjs",
        pnp_data = "//:.pnp.data.json",
        pnp_integrity = "//:.pnp.integrity.json",
        yarn_lock = "//:yarn.lock",
        yarnrc = "//:.yarnrc.yml",
    )
    use_repo(pnp, "pnp")

rules_js never runs Yarn and never creates a node_modules tree. The developer
runs Yarn, checks in its outputs and cache/runtime inputs, and records their
sha512 hashes in .pnp.integrity.json. The importer consumes the path choices in
the generated PnP data; it recognizes rather than invents Yarn's layout.
"""

load(":pnp_repository.bzl", "pnp_repository")

_install = tag_class(
    attrs = {
        "cache": attr.label(
            doc = "A filegroup containing the checked-in Yarn offline cache archives.",
            mandatory = True,
        ),
        "name": attr.string(
            doc = "Name of the generated repository.",
            default = "pnp",
        ),
        "pnp_cjs": attr.label(
            doc = "The checked-in .pnp.cjs resolver.",
            mandatory = True,
        ),
        "pnp_data": attr.label(
            doc = "The checked-in .pnp.data.json file.",
            mandatory = True,
        ),
        "pnp_integrity": attr.label(
            doc = "The checked-in .pnp.integrity.json file.",
            mandatory = True,
        ),
        "runtime_files": attr.label_list(
            doc = "Filegroups for checked-in unplugged or other non-cache runtime content.",
        ),
        "yarn_lock": attr.label(
            doc = "The checked-in Yarn Berry yarn.lock file.",
            mandatory = True,
        ),
        "yarnrc": attr.label(
            doc = "The checked-in .yarnrc.yml used to generate the PnP artifacts.",
            mandatory = True,
        ),
    },
    doc = "Declares one Yarn PnP zero-install project to consume.",
)

def _pnp_impl(mctx):
    for mod in mctx.modules:
        for install in mod.tags.install:
            pnp_repository(
                name = install.name,
                cache = install.cache,
                pnp_cjs = install.pnp_cjs,
                pnp_data = install.pnp_data,
                pnp_integrity = install.pnp_integrity,
                runtime_files = install.runtime_files,
                yarn_lock = install.yarn_lock,
                yarnrc = install.yarnrc,
            )

pnp = module_extension(
    implementation = _pnp_impl,
    tag_classes = {
        "install": _install,
    },
    doc = "Consumes checked-in Yarn PnP zero-install projects without running Yarn.",
)
