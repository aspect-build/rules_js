load("@npm//:defs.bzl", "npm_link_all_packages")
load("@aspect_rules_js//js:defs.bzl", "js_library")
load("@aspect_rules_js//npm:defs.bzl", "npm_package")
load("@bazel_skylib//rules:write_file.bzl", "write_file")

npm_link_all_packages(name = "node_modules")

npm_package(
    name = "test-component",
    visibility = ["//visibility:public"],
    package = "@my-org/test-component",
    srcs = [":library"],
    out = "package",
    include_runfiles = False,
)

js_library(
    name = "library",
    srcs = [
        "package.json",
        "index.jsx",
    ],
    deps = [
        ":node_modules/react",
    ]
)
