# Declare the local Bazel workspace.
# This is *not* included in the published distribution.
workspace(
    # see https://docs.bazel.build/versions/main/skylark/deploying.html#workspace
    name = "aspect_rules_js",
)

load(":internal_deps.bzl", "js_internal_deps")

js_internal_deps()

# Install our "runtime" dependencies which users install as well
load("//js:repositories.bzl", "js_dependencies")

js_dependencies()

load("//js:configure.bzl", "js_configure")

js_configure()

load("@aspect_rules_js//js:npm_import.bzl", "npm_import", "translate_pnpm_lock")

translate_pnpm_lock(
    name = "aspect_rules_js_lifecycle_npm_deps",
    # Avoid a circular dependency on the lifecycle hooks package,
    # which is used when enable_lifecycle_hooks = True
    enable_lifecycle_hooks = False,
    pnpm_lock = "@aspect_rules_js//js/private/lifecycle:pnpm-lock.json",
)

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
# Fetch some npm packages for testing our example

# Manually import a package using explicit coordinates.
# Just a demonstration of the syntax de-sugaring.
npm_import(
    name = "example_npm_deps__acorn-8.4.0",
    integrity = "sha512-ULr0LDaEqQrMFGyQ3bhJkLsbtrQ8QibAseGZeaSUiT/6zb9IvIkomWHJIvgvwad+hinRAgsI51JcWk2yvwyL+w==",
    link_package_guard = "example",
    package = "acorn",
    version = "8.4.0",
)

# Read the pnpm-lock.json file to automate creation of remaining npm_import rules
translate_pnpm_lock(
    name = "example_npm_deps",
    patch_args = {
        "@gregmagolan/test-a": ["-p1"],
    },
    patches = {
        "@gregmagolan/test-a": ["//example:test-a.patch"],
        "@gregmagolan/test-a@0.0.1": ["//example:test-a@0.0.1.patch"],
    },
    # yq -o=json -I=2 '.' pnpm-lock.yaml > pnpm-lock.json
    pnpm_lock = "//example:pnpm-lock.json",
    postinstall = {
        "@aspect-test/c": "echo 'moo' > cow.txt",
        "@aspect-test/c@2.0.0": "echo 'mooo' >> cow.txt",
    },
)

# This is the result of translate_pnpm_lock
load("@example_npm_deps//:repositories.bzl", example_npm_repositories = "npm_repositories")

# Declare remaining npm_import rules
example_npm_repositories()
