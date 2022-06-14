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

load("@aspect_rules_js//npm:npm_import.bzl", "npm_import", "npm_translate_lock")

npm_translate_lock(
    name = "npm",
    custom_postinstalls = {
        "@aspect-test/c": "echo 'moo' > cow.txt",
        "@aspect-test/c@2.0.0": "echo 'mooo' >> cow.txt",
    },
    patch_args = {
        "@gregmagolan/test-a": ["-p1"],
    },
    patches = {
        "@gregmagolan/test-a": ["//examples/npm_deps:patches/test-a.patch"],
        "@gregmagolan/test-a@0.0.1": ["//examples/npm_deps:patches/test-a@0.0.1.patch"],
    },
    pnpm_lock = "//:pnpm-lock.yaml",
    verify_node_modules_ignored = "//:.bazelignore",
    warn_on_unqualified_tarball_url = False,
)

load("@npm//:repositories.bzl", "npm_repositories")

# Declares npm_import rules from the pnpm-lock.yaml file
npm_repositories()

# As an example, manually import a package using explicit coordinates.
# Just a demonstration of the syntax de-sugaring.
npm_import(
    name = "acorn__8.4.0",
    integrity = "sha512-ULr0LDaEqQrMFGyQ3bhJkLsbtrQ8QibAseGZeaSUiT/6zb9IvIkomWHJIvgvwad+hinRAgsI51JcWk2yvwyL+w==",
    package = "acorn",
    # Root package where to link the virtual store
    root_package = "",
    version = "8.4.0",
)

npm_import(
    name = "pnpm",
    integrity = "sha512-IY+62k/caP5GsMQm5YcOJ03XDkze68aBiiXrlwqMUAYFhSstLETlenIC73AukJyUd7o4Y18HcV2gfQYCKb0PEA==",
    package = "pnpm",
    root_package = "",
    version = "6.32.19",
)
