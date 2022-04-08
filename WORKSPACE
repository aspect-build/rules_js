# Declare the local Bazel workspace.
# This is *not* included in the published distribution.
workspace(
    # see https://docs.bazel.build/versions/main/skylark/deploying.html#workspace
    name = "aspect_rules_js",
)

load(":internal_deps.bzl", "rules_js_internal_deps")

rules_js_internal_deps()

# Install our "runtime" dependencies which users install as well
load("//js:repositories.bzl", "rules_js_dependencies")

rules_js_dependencies()

load("@bazel_skylib//lib:unittest.bzl", "register_unittest_toolchains")

register_unittest_toolchains()

############################################
# Gazelle, for generating bzl_library targets
load("@io_bazel_rules_go//go:deps.bzl", "go_register_toolchains", "go_rules_dependencies")
load("@bazel_gazelle//:deps.bzl", "gazelle_dependencies")

go_rules_dependencies()

go_register_toolchains(version = "1.17.2")

gazelle_dependencies()

############################################
# Fetch node and some npm packages, for testing our example
load("@rules_nodejs//nodejs:repositories.bzl", "nodejs_register_toolchains")

nodejs_register_toolchains(
    name = "node16",
    node_version = "16.9.0",
)

load("@aspect_rules_js//js:npm_import.bzl", "npm_import")

# Manually import a package using explicit coordinates.
# Just a demonstration of the syntax de-sugaring.
npm_import(
    name = "example_npm_deps__acorn-8.4.0",
    integrity = "sha512-ULr0LDaEqQrMFGyQ3bhJkLsbtrQ8QibAseGZeaSUiT/6zb9IvIkomWHJIvgvwad+hinRAgsI51JcWk2yvwyL+w==",
    package_name = "acorn",
    package_version = "8.4.0",
    namespace = "example_npm_deps",
    link_package_guard = "example",
)

load("@aspect_rules_js//js:translate_pnpm_lock.bzl", "translate_pnpm_lock")

# Read the pnpm-lock.json file to automate creation of remaining npm_import rules
translate_pnpm_lock(
    name = "example_npm_deps",
    # yq -o=json -I=2 '.' pnpm-lock.yaml > pnpm-lock.json
    pnpm_lock = "//example:pnpm-lock.json",
    patch_args = {
        "@gregmagolan/test-a": ["-p1"],
    },
    patches = {
        "@gregmagolan/test-a": ["//example:test-a.patch"],
        "@gregmagolan/test-a@0.0.1": ["//example:test-a@0.0.1.patch"],
    },
)

# This is the result of translate_pnpm_lock
load("@example_npm_deps//:repositories.bzl", "npm_repositories")

# Declare remaining npm_import rules
npm_repositories()
