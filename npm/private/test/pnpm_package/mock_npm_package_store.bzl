"""Test-only rules that provide a mock NpmPackageStoreInfo via JsInfo.

Split into two rules so the NpmPackageStoreInfo (which contains a mutable dict
field) is frozen by Bazel before being placed into a depset in the JsInfo.
"""

load("//js:providers.bzl", "JsInfo", "js_info")
load("//npm/private:npm_package_store_info.bzl", "NpmPackageStoreInfo")

def _mock_npm_package_store_info_impl(ctx):
    return [NpmPackageStoreInfo(
        key = ctx.attr.package,
        root_package = "",
        package = ctx.attr.package,
        version = ctx.attr.version,
        ref_deps = {},
        package_store_directory = None,
        files = depset(),
        transitive_files = depset(),
    )]

_mock_npm_package_store_info = rule(
    implementation = _mock_npm_package_store_info_impl,
    attrs = {
        "package": attr.string(mandatory = True),
        "version": attr.string(mandatory = True),
    },
)

def _mock_npm_package_store_link_impl(ctx):
    info = ctx.attr.store[NpmPackageStoreInfo]
    return [
        info,
        js_info(
            target = ctx.label,
            npm_package_store_infos = depset([info]),
        ),
    ]

_mock_npm_package_store_link = rule(
    implementation = _mock_npm_package_store_link_impl,
    attrs = {
        "store": attr.label(mandatory = True, providers = [NpmPackageStoreInfo]),
    },
)

def mock_npm_package_store(name, package, version, **kwargs):
    _mock_npm_package_store_info(
        name = name + "_store",
        package = package,
        version = version,
        **kwargs
    )
    _mock_npm_package_store_link(
        name = name,
        store = ":" + name + "_store",
        **kwargs
    )
