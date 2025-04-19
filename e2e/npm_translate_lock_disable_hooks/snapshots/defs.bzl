"""@generated by npm_translate_lock(name = "npm", pnpm_lock = "@@//:pnpm-lock.yaml")"""

load("@@aspect_rules_js~~npm~npm__at_aspect-test_c__2.0.0__links//:defs.bzl", link_0 = "npm_link_imported_package_store", store_0 = "npm_imported_package_store")

# buildifier: disable=bzl-visibility
load("@aspect_rules_js//js:defs.bzl", _js_library = "js_library")

_LINK_PACKAGES = [""]

# buildifier: disable=function-docstring
def npm_link_all_packages(name = "node_modules", imported_links = []):
    bazel_package = native.package_name()
    root_package = ""
    is_root = bazel_package == root_package
    link = bazel_package in _LINK_PACKAGES
    if not is_root and not link:
        msg = "The npm_link_all_packages() macro loaded from @aspect_rules_js~~npm~npm//:defs.bzl and called in bazel package '%s' may only be called in bazel packages that correspond to the pnpm root package or pnpm workspace projects. Projects are discovered from the pnpm-lock.yaml and may be missing if the lockfile is out of date. Root package: '', pnpm workspace projects: %s" % (bazel_package, "'" + "', '".join(_LINK_PACKAGES) + "'")
        fail(msg)
    link_targets = []
    scope_targets = {}

    for link_fn in imported_links:
        new_link_targets, new_scope_targets = link_fn(name)
        link_targets.extend(new_link_targets)
        for _scope, _targets in new_scope_targets.items():
            if _scope not in scope_targets:
                scope_targets[_scope] = []
            scope_targets[_scope].extend(_targets)

    if is_root:
        store_0(name)
    if link:
        if bazel_package == "":
            link_0("{}/@aspect-test/c".format(name), link_root_name = name, link_alias = "@aspect-test/c")
            link_targets.append(":{}/@aspect-test/c".format(name))
            if "@aspect-test" not in scope_targets:
                scope_targets["@aspect-test"] = [link_targets[-1]]
            else:
                scope_targets["@aspect-test"].append(link_targets[-1])

    for scope, scoped_targets in scope_targets.items():
        _js_library(
            name = "{}/{}".format(name, scope),
            srcs = scoped_targets,
            tags = ["manual"],
            visibility = ["//visibility:public"],
        )

    _js_library(
        name = name,
        srcs = link_targets,
        tags = ["manual"],
        visibility = ["//visibility:public"],
    )

# buildifier: disable=function-docstring
def npm_link_targets(name = "node_modules", package = None):
    bazel_package = package if package != None else native.package_name()
    link = bazel_package in _LINK_PACKAGES

    link_targets = []

    if link:
        if bazel_package == "":
            link_targets.append(":{}/@aspect-test/c".format(name))
    return link_targets
