workspace(
    # see https://docs.bazel.build/versions/main/skylark/deploying.html#workspace
    name = "aspect_rules_js",
)

load("//js:dev_repositories.bzl", "rules_js_dev_dependencies")

rules_js_dev_dependencies()

load("//js:repositories.bzl", "rules_js_dependencies")

rules_js_dependencies()

load("@aspect_bazel_lib//lib:repositories.bzl", "aspect_bazel_lib_dependencies", "register_jq_toolchains")

aspect_bazel_lib_dependencies(override_local_config_platform = True)

register_jq_toolchains()

load("@rules_nodejs//nodejs:repositories.bzl", "nodejs_register_toolchains")

nodejs_register_toolchains(
    name = "nodejs",
    node_version = "16.9.0",
)

# Alternate toolchains for testing across versions
nodejs_register_toolchains(
    name = "node14",
    node_version = "14.17.1",
)

nodejs_register_toolchains(
    name = "node16",
    node_version = "16.13.1",
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

go_register_toolchains(version = "1.19.3")

gazelle_dependencies()

############################################
# Example npm dependencies

load("@aspect_rules_js//npm:npm_import.bzl", "npm_import", "npm_translate_lock")

npm_translate_lock(
    name = "npm",
    bins = {
        # derived from "bin" attribute in node_modules/typescript/package.json
        "typescript": {
            "tsc": "./bin/tsc",
            "tsserver": "./bin/tsserver",
        },
    },
    custom_postinstalls = {
        "@aspect-test/c": "echo moo > cow.txt",
        "@aspect-test/c@2.0.2": "echo mooo >> cow.txt",
    },
    generate_bzl_library_targets = True,
    lifecycle_hooks_execution_requirements = {
        "@figma/nodegit": [
            # Workaround Engflow not honoring requires-network on build actions
            "no-remote-exec",
            "requires-network",
        ],
        "esbuild": [
            # Workaround Engflow not honoring requires-network on build actions
            "no-remote-exec",
            "requires-network",
        ],
    },
    patch_args = {
        "@gregmagolan/test-a": ["-p1"],
    },
    patches = {
        "@gregmagolan/test-a": ["//examples/npm_deps:patches/test-a.patch"],
        "@gregmagolan/test-a@0.0.1": ["//examples/npm_deps:patches/test-a@0.0.1.patch"],
    },
    pnpm_lock = "//:pnpm-lock.yaml",
    pnpm_version = "6.32.19",
    public_hoist_packages = {
        # Instructs the linker to hoist the ms@2.1.3 npm package to `node_modules/ms` in the `examples/npm_deps` package.
        # Similar to adding `public-hoist-pattern[]=ms` in .npmrc but with control over which version to hoist and where
        # to hoist it. This hoisted package can be referenced by the label `//examples/npm_deps:node_modules/ms` same as
        # other direct dependencies in the `examples/npm_deps/package.json`.
        "ms@2.1.3": ["examples/npm_deps"],
    },
    verify_node_modules_ignored = "//:.bazelignore",
)

load("@npm//:repositories.bzl", "npm_repositories")

# Declares npm_import rules from the pnpm-lock.yaml file
npm_repositories()

# As an example, manually import a package using explicit coordinates.
# Just a demonstration of the syntax de-sugaring.
npm_import(
    name = "acorn__8.4.0",
    bins = {"acorn": "./bin/acorn"},
    integrity = "sha512-ULr0LDaEqQrMFGyQ3bhJkLsbtrQ8QibAseGZeaSUiT/6zb9IvIkomWHJIvgvwad+hinRAgsI51JcWk2yvwyL+w==",
    package = "acorn",
    # Root package where to link the virtual store
    root_package = "",
    version = "8.4.0",
)
