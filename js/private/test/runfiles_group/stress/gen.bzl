"""Generate a predecessor/second-predecessor js_library chain for heap tests."""

load("@bazel_skylib//rules:write_file.bzl", "write_file")
load("//js:defs.bzl", "js_library")
load("//npm:defs.bzl", "npm_link_package", "npm_package")

def js_library_chain(name, count):
    """Create `{name}_lib0` .. `{name}_lib{count-1}` with unique payloads.

    Every node data-depends on a unique runtime file, one shared source asset
    that is copied to bin, plus one shared npm link so grouping relays borrowed
    coarse npm depsets while still grouping a growing admitted runtime inventory.
    """
    write_file(
        name = "%s_pkg_src" % name,
        out = "%s_pkg.js" % name,
        content = ["module.exports = 1;"],
    )
    js_library(
        name = "%s_pkg_lib" % name,
        srcs = [":%s_pkg_src" % name],
    )
    npm_package(
        name = "%s_pkg" % name,
        srcs = [":%s_pkg_lib" % name],
        package = "@test/%s" % name,
        version = "1.0.0",
    )
    npm_link_package(
        name = "%s_link" % name,
        src = ":%s_pkg" % name,
        tags = ["manual"],
    )
    for i in range(count):
        write_file(
            name = "%s_src%d" % (name, i),
            out = "%s_%d.js" % (name, i),
            content = ["exports.n = %d;" % i],
        )
        write_file(
            name = "%s_rt%d" % (name, i),
            out = "%s_rt%d.txt" % (name, i),
            content = ["rt %d" % i],
        )
        deps = []
        if i >= 1:
            deps.append(":%s_lib%d" % (name, i - 1))
        if i >= 2:
            deps.append(":%s_lib%d" % (name, i - 2))
        js_library(
            name = "%s_lib%d" % (name, i),
            srcs = [":%s_src%d" % (name, i)],
            data = [
                ":%s_rt%d" % (name, i),
                ":%s_link" % name,
                "copy_asset.txt",
            ],
            deps = deps,
            visibility = ["//visibility:public"],
        )
