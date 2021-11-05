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

############################################
# Gazelle, for generating bzl_library targets
load("@io_bazel_rules_go//go:deps.bzl", "go_register_toolchains", "go_rules_dependencies")
load("@bazel_gazelle//:deps.bzl", "gazelle_dependencies")

go_rules_dependencies()

go_register_toolchains(version = "1.17.2")

gazelle_dependencies()

############################################
# Fetch node and some npm packages, for local testing
load("@rules_nodejs//nodejs:repositories.bzl", "nodejs_register_toolchains")

nodejs_register_toolchains(
    name = "node16",
    node_version = "16.9.0",
)

load("@aspect_rules_js//js:npm_import.bzl", "npm_import", "translate_package_lock")

# TODO: we should have a translate_package_lock rule like
# https://github.com/alexeagle/rules_nodejs/blob/stable/internal/npm_tarballs/translate_package_lock.bzl
# that automatically creates npm_import rules for everything the project already depends on.
# That would provide syntax sugar for the typical case where the dependencies were specified in package.json
# and a package manager already fetched integrity hashes from the registry.
npm_import(
    integrity = "sha512-ULr0LDaEqQrMFGyQ3bhJkLsbtrQ8QibAseGZeaSUiT/6zb9IvIkomWHJIvgvwad+hinRAgsI51JcWk2yvwyL+w==",
    package = "acorn",
    version = "8.4.0",
    deps = [],
)

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
    package_lock = "//test:package-lock.json",
)

# This is the result of translate_package_lock
load("@npm_deps//:repositories.bzl", "npm_repositories")

# Declare remaining npm_import rules
npm_repositories()
