workspace(
    # see https://docs.bazel.build/versions/main/skylark/deploying.html#workspace
    name = "aspect_rules_js",
)

load("//js:dev_repositories.bzl", "rules_js_dev_dependencies")

rules_js_dev_dependencies()

load("//js:repositories.bzl", "rules_js_dependencies")

rules_js_dependencies()

load("@rules_nodejs//nodejs:repositories.bzl", "nodejs_register_toolchains")

nodejs_register_toolchains(
    name = "nodejs",
    node_version = "16.9.0",
)

load("@bazel_skylib//lib:unittest.bzl", "register_unittest_toolchains")

register_unittest_toolchains()

load("@aspect_bazel_lib//lib:host_repo.bzl", "host_repo")

host_repo(name = "aspect_bazel_lib_host")

############################################
# Gazelle, for generating bzl_library targets

load("@io_bazel_rules_go//go:deps.bzl", "go_register_toolchains", "go_rules_dependencies")
load("@bazel_gazelle//:deps.bzl", "gazelle_dependencies")

go_rules_dependencies()

go_register_toolchains(version = "1.17.2")

gazelle_dependencies()

############################################
# Example npm dependencies

load("//example:translate_pnpm_lock.bzl", example_translate_pnpm_lock = "translate_pnpm_lock")

example_translate_pnpm_lock()

load("//example:npm_imports.bzl", example_npm_imports = "npm_imports")

example_npm_imports()
