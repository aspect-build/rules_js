"@generated by @aspect_rules_js//npm/private:npm_import.bzl for npm package rollup@2.70.2"

# buildifier: disable=bzl-visibility
load("@aspect_rules_js//npm/private:npm_package_store_internal.bzl", _npm_package_store = "npm_package_store_internal")

# buildifier: disable=bzl-visibility
load("@aspect_rules_js//npm/private:npm_import.bzl",
    _npm_imported_package_store = "npm_imported_package_store",
    _npm_link_imported_package = "npm_link_imported_package",
    _npm_link_imported_package_store = "npm_link_imported_package_store")


# Generated npm_package_store targets for npm package rollup@2.70.2
# buildifier: disable=function-docstring
def npm_imported_package_store(name):
    _npm_imported_package_store(
        name = name,
        package = "rollup",
        version = "2.70.2",
        root_package = "",
        deps = {
            ":.aspect_rules_js/{link_root_name}/fsevents@2.3.2/pkg": "fsevents",
            ":.aspect_rules_js/{link_root_name}/rollup@2.70.2/pkg": "rollup",
        },
        ref_deps = {
            ":.aspect_rules_js/{link_root_name}/fsevents@2.3.2/ref": "fsevents",
        },
        lc_deps = {
            ":.aspect_rules_js/{link_root_name}/fsevents@2.3.2/pkg": "fsevents",
            ":.aspect_rules_js/{link_root_name}/rollup@2.70.2/pkg_pre_lc_lite": "rollup",
        },
        dev = True,
        has_lifecycle_build_target = False,
        transitive_closure_pattern = True,
        npm_package_target = "@@_main~npm~npm__rollup__2.70.2//:pkg",
        package_store_name = "rollup@2.70.2",
        lifecycle_hooks_env = {},
        lifecycle_hooks_execution_requirements = {},
        use_default_shell_env = False,
        exclude_package_contents = [],
    )

# Generated npm_package_store and npm_link_package_store targets for npm package rollup@2.70.2
# buildifier: disable=function-docstring
def npm_link_imported_package_store(name):
    return _npm_link_imported_package_store(
        name,
        package = "rollup",
        version = "2.70.2",
        root_package = "",
        link_packages = {
            "examples/npm_deps": ["rollup"],
        },
        link_visibility = ["//visibility:public"],
        bins = {},
        link = None,
        package_store_name = "rollup@2.70.2",
        public_visibility = True,
    )

# Generated npm_package_store and npm_link_package_store targets for npm package rollup@2.70.2
# buildifier: disable=function-docstring
def npm_link_imported_package(
        name = "node_modules",
        link = None,
        fail_if_no_link = True):
    return _npm_link_imported_package(
        name,
        package = "rollup",
        version = "2.70.2",
        root_package = "",
        link = link,
        link_packages = {
            "examples/npm_deps": ["rollup"],
        },
        public_visibility = True,
        npm_link_imported_package_store_macro = npm_link_imported_package_store,
        npm_imported_package_store_macro = npm_imported_package_store,
        fail_if_no_link = fail_if_no_link,
    )
