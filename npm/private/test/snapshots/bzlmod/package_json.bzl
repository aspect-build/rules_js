"@generated by @aspect_rules_js//npm/private:npm_import.bzl for npm package rollup@2.70.2"

load("@aspect_bazel_lib//lib:directory_path.bzl", _directory_path = "directory_path")
load("@aspect_rules_js//js:defs.bzl", _js_binary = "js_binary", _js_run_binary = "js_run_binary", _js_test = "js_test")
load("@aspect_rules_js//npm/private:npm_import.bzl", "bin_binary_internal", "bin_internal", "bin_test_internal")

def _rollup_internal(name, link_root_name, **kwargs):
    _link_workspace = "@"
    _root_package = ""
    _package_store_root = ".aspect_rules_js"
    _package_store_name = "rollup@2.70.2"
    _bin_path = "dist/bin/rollup"
    _bin_mnemonic = "Rollup"

    bin_internal(
        name,
        link_workspace = _link_workspace,
        root_package = _root_package,
        package_store_root = _package_store_root,
        link_root_name = link_root_name,
        package_store_name = _package_store_name,
        bin_path = _bin_path,
        bin_mnemonic = _bin_mnemonic,
        **kwargs,
    )

def _rollup_test_internal(name, link_root_name, **kwargs):
    _link_workspace = "@"
    _root_package = ""
    _package_store_root = ".aspect_rules_js"
    _package_store_name = "rollup@2.70.2"
    _bin_path = "dist/bin/rollup"

    bin_test_internal(
        name,
        link_workspace = _link_workspace,
        root_package = _root_package,
        package_store_root = _package_store_root,
        link_root_name = link_root_name,
        package_store_name = _package_store_name,
        bin_path = _bin_path,
        **kwargs,
    )


def _rollup_binary_internal(name, link_root_name, **kwargs):
    _link_workspace = "@"
    _root_package = ""
    _package_store_root = ".aspect_rules_js"
    _package_store_name = "rollup@2.70.2"
    _bin_path = "dist/bin/rollup"

    bin_binary_internal(
        name,
        link_workspace = _link_workspace,
        root_package = _root_package,
        package_store_root = _package_store_root,
        link_root_name = link_root_name,
        package_store_name = _package_store_name,
        bin_path = _bin_path,
        **kwargs,
    )

def rollup(name, **kwargs):
    _rollup_internal(name, "node_modules", **kwargs)

def rollup_test(name, **kwargs):
    _rollup_test_internal(name, "node_modules", **kwargs)

def rollup_binary(name, **kwargs):
    _rollup_binary_internal(name, "node_modules", **kwargs)

def bin_factory(link_root_name):
    # bind link_root_name using lambdas
    return struct(
        rollup = lambda name, **kwargs: _rollup_internal(name, link_root_name = link_root_name, **kwargs),
        rollup_test = lambda name, **kwargs: _rollup_test_internal(name, link_root_name = link_root_name, **kwargs),
        rollup_binary = lambda name, **kwargs: _rollup_binary_internal(name, link_root_name = link_root_name, **kwargs),
        rollup_path = "dist/bin/rollup",
    )

bin = bin_factory("node_modules")
