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

load("//gazelle:deps.bzl", "gazelle_deps")

gazelle_deps()

load("@bazel_skylib//lib:unittest.bzl", "register_unittest_toolchains")

register_unittest_toolchains()

############################################
# Gazelle, for generating bzl_library targets
load("@io_bazel_rules_go//go:deps.bzl", "go_register_toolchains", "go_rules_dependencies")
load("@bazel_gazelle//:deps.bzl", "gazelle_dependencies")

go_rules_dependencies()

go_register_toolchains(version = "1.17.2")

# gazelle:repository_macro gazelle/deps.bzl%gazelle_deps
gazelle_dependencies()

############################################
# Fetch node and some npm packages, for testing our example
load("@rules_nodejs//nodejs:repositories.bzl", "nodejs_register_toolchains")

nodejs_register_toolchains(
    name = "node16",
    node_version = "16.9.0",
)

load("@aspect_rules_js//js:npm_import.bzl", "npm_import", "translate_package_lock")

# Manually import a package using explicit coordinates.
# Just a demonstration of the syntax de-sugaring.
npm_import(
    integrity = "sha512-ULr0LDaEqQrMFGyQ3bhJkLsbtrQ8QibAseGZeaSUiT/6zb9IvIkomWHJIvgvwad+hinRAgsI51JcWk2yvwyL+w==",
    package = "acorn",
    version = "8.4.0",
    deps = [],
)

# Read the package-lock.json file to automate creation of remaining npm_import rules
translate_package_lock(
    name = "npm_deps",
    package_lock = "//example:package-lock.json",
)

# This is the result of translate_package_lock
load("@npm_deps//:repositories.bzl", "npm_repositories")

# Declare remaining npm_import rules
npm_repositories()
