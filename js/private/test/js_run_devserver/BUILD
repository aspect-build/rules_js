load("@npm//:defs.bzl", "npm_link_all_packages")
load(":js_run_devserver_test.bzl", "js_run_devserver_test")

npm_link_all_packages(name = "node_modules")

# Test that bundlers see a single node_modules tree.
# https://github.com/aspect-build/rules_js/issues/1204
js_run_devserver_test(
    name = "js_run_devserver_test",
    chdir = "js/private/test/js_run_devserver",
    command = "./node_modules/.bin/jasmine",
    args = ["*.spec.mjs"],
    data = glob(["*.spec.mjs"]) + [
        # Some packages to link back to the exec root for the tests (and need jasmine anyway)
        ":node_modules/@types/node",
        ":node_modules/jasmine",
    ],
)

