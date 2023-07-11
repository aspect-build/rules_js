load("@app2_npm//:defs.bzl", "npm_link_all_packages")
load("@bazel_skylib//rules:build_test.bzl", "build_test")

npm_link_all_packages()

build_test(
    name = "test",
    targets = [":node_modules"],
)
