"@generated by @aspect_rules_js//npm/private:npm_import.bzl for npm package rollup@2.70.2"

load("@aspect_bazel_lib//lib:directory_path.bzl", _directory_path = "directory_path")
load("@aspect_rules_js//js:defs.bzl", _js_binary = "js_binary", _js_run_binary = "js_run_binary", _js_test = "js_test")

def _rollup_internal(name, link_root_name, **kwargs):
    store_target_name = ".aspect_rules_js/{}/rollup@2.70.2".format(link_root_name)
    _directory_path(
        name = "%s__entry_point" % name,
        directory = "@//:{}/dir".format(store_target_name),
        path = "dist/bin/rollup",
        tags = ["manual"],
    )
    _js_binary(
        name = "%s__js_binary" % name,
        entry_point = ":%s__entry_point" % name,
        data = ["@//:{}".format(store_target_name)],
        include_npm = kwargs.pop("include_npm", False),
        tags = ["manual"],
    )
    _js_run_binary(
        name = name,
        tool = ":%s__js_binary" % name,
        mnemonic = kwargs.pop("mnemonic", "Rollup"),
        **kwargs
    )

def _rollup_test_internal(name, link_root_name, **kwargs):
    store_target_name = ".aspect_rules_js/{}/rollup@2.70.2".format(link_root_name)
    _directory_path(
        name = "%s__entry_point" % name,
        directory = "@//:{}/dir".format(store_target_name),
        path = "dist/bin/rollup",
        tags = ["manual"],
    )
    _js_test(
        name = name,
        entry_point = ":%s__entry_point" % name,
        data = kwargs.pop("data", []) + ["@//:{}".format(store_target_name)],
        **kwargs
    )

def _rollup_binary_internal(name, link_root_name, **kwargs):
    store_target_name = ".aspect_rules_js/{}/rollup@2.70.2".format(link_root_name)
    _directory_path(
        name = "%s__entry_point" % name,
        directory = "@//:{}/dir".format(store_target_name),
        path = "dist/bin/rollup",
        tags = ["manual"],
    )
    _js_binary(
        name = name,
        entry_point = ":%s__entry_point" % name,
        data = kwargs.pop("data", []) + ["@//:{}".format(store_target_name)],
        **kwargs
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
