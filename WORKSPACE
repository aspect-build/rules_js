workspace(
    # see https://docs.bazel.build/versions/main/skylark/deploying.html#workspace
    name = "aspect_rules_js",
)

load("//js:dev_repositories.bzl", "rules_js_dev_dependencies")

rules_js_dev_dependencies()

load("//js:repositories.bzl", "rules_js_dependencies")

rules_js_dependencies()

load("@aspect_bazel_lib//lib:repositories.bzl", "aspect_bazel_lib_dependencies", "register_coreutils_toolchains", "register_jq_toolchains")

aspect_bazel_lib_dependencies(override_local_config_platform = True)

register_jq_toolchains()

register_coreutils_toolchains()

load("@rules_nodejs//nodejs:repositories.bzl", "nodejs_register_toolchains")

nodejs_register_toolchains(
    name = "nodejs",
    node_version = "16.14.2",
)

# Alternate toolchains for testing across versions
nodejs_register_toolchains(
    name = "node16",
    node_version = "16.13.1",
)

nodejs_register_toolchains(
    name = "node18",
    node_version = "18.13.0",
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

load("@aspect_rules_js//npm:repositories.bzl", "npm_import", "npm_translate_lock")

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
    data = [
        "//:examples/npm_deps/patches/meaning-of-life@1.0.0-pnpm.patch",
        "//:package.json",
        "//:pnpm-workspace.yaml",
        "//examples/js_binary:package.json",
        "//examples/macro:package.json",
        "//examples/npm_deps:package.json",
        "//examples/npm_package/libs/lib_a:package.json",
        "//examples/npm_package/packages/pkg_a:package.json",
        "//examples/npm_package/packages/pkg_b:package.json",
        "//examples/webpack_cli:package.json",
        "//js/private/coverage/bundle:package.json",
        "//js/private/image:package.json",
        "//js/private/test/image:package.json",
        "//js/private/worker/src:package.json",
        "//npm/private/test:package.json",
        "//npm/private/test:vendored/lodash-4.17.21.tgz",
        "//npm/private/test/npm_package:package.json",
        "//npm/private/test/vendored/is-odd:package.json",
        "//npm/private/test/vendored/semver-max:package.json",
    ],
    generate_bzl_library_targets = True,
    lifecycle_hooks = {
        # we fetch @kubernetes/client-node from source and it has a `prepare` lifecycle hook that needs to be run
        "@kubernetes/client-node": ["prepare"],
        # 'install' hook fails as it assumes the following path to `node-pre-gyp`: ./node_modules/.bin/node-pre-gyp
        # https://github.com/stultuss/protoc-gen-grpc-ts/blob/53d52a9d0e1fe3cbe930dec5581eca89b3dde807/package.json#L28
        "protoc-gen-grpc@2.0.3": [],
    },
    lifecycle_hooks_execution_requirements = {
        "*": [
            "no-sandbox",
        ],
        # If @kubernetes/client-node is not sandboxed, will fail with
        # ```
        # src/azure_auth.ts(97,43): error TS2575: No overload expects 2 arguments, but overloads do exist that expect either 1 or 4 arguments.
        # src/azure_auth.ts(98,34): error TS2575: No overload expects 2 arguments, but overloads do exist that expect either 1 or 4 arguments.
        # src/gcp_auth.ts(93,43): error TS2575: No overload expects 2 arguments, but overloads do exist that expect either 1 or 4 arguments.
        # src/gcp_auth.ts(94,34): error TS2575: No overload expects 2 arguments, but overloads do exist that expect either 1 or 4 arguments.
        # ```
        # since a `jsonpath-plus@7.2.0` that is newer then the transitive dep `jsonpath-plus@0.19.0` is found outside of the sandbox that
        # includes typings that don't match the 0.19.0 "any" usage.
        "@kubernetes/client-node": [],
        "@figma/nodegit": [
            "no-sandbox",
            # Workaround Engflow not honoring requires-network on build actions
            "no-remote-exec",
            "requires-network",
        ],
        "esbuild": [
            "no-sandbox",
            # Workaround Engflow not honoring requires-network on build actions
            "no-remote-exec",
            "requires-network",
        ],
        "segfault-handler": [
            "no-sandbox",
            # Workaround Engflow not honoring requires-network on build actions
            "no-remote-exec",
            "requires-network",
        ],
        "puppeteer": [
            "no-sandbox",
            # Workaround Engflow not honoring requires-network on build actions
            "no-remote-exec",
            "requires-network",
        ],
    },
    npmrc = "//:.npmrc",
    patch_args = {
        "*": ["-p1"],
        "@gregmagolan/test-a": ["-p4"],
    },
    patches = {
        "@gregmagolan/test-a": ["//examples/npm_deps:patches/test-a.patch"],
        "@gregmagolan/test-a@0.0.1": ["//examples/npm_deps:patches/test-a@0.0.1.patch"],
        "@gregmagolan/test-b": ["//examples/npm_deps:patches/test-b.patch"],
        "meaning-of-life@1.0.0": ["//examples/npm_deps:patches/meaning-of-life@1.0.0-after_pnpm.patch"],
    },
    pnpm_lock = "//:pnpm-lock.yaml",
    pnpm_version = "8.6.0",
    public_hoist_packages = {
        # Instructs the linker to hoist the ms@2.1.3 npm package to `node_modules/ms` in the `examples/npm_deps` package.
        # Similar to adding `public-hoist-pattern[]=ms` in .npmrc but with control over which version to hoist and where
        # to hoist it. This hoisted package can be referenced by the label `//examples/npm_deps:node_modules/ms` same as
        # other direct dependencies in the `examples/npm_deps/package.json`.
        "ms@2.1.3": ["examples/npm_deps"],
    },
    update_pnpm_lock = True,
    verify_node_modules_ignored = "//:.bazelignore",
    verify_patches = "//examples/npm_deps/patches:patches",
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

load("@buildifier_prebuilt//:deps.bzl", "buildifier_prebuilt_deps")

buildifier_prebuilt_deps()

load("@buildifier_prebuilt//:defs.bzl", "buildifier_prebuilt_register_toolchains")

buildifier_prebuilt_register_toolchains()
