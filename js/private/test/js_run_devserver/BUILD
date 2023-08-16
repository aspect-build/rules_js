load("@npm//:defs.bzl", "npm_link_all_packages")
load(":js_run_devserver_test.bzl", "js_run_devserver_test")

npm_link_all_packages(name = "node_modules")

js_run_devserver_test(
    name = "js_run_devserver_test",
    args = ["*.spec.mjs"],
    chdir = "js/private/test/js_run_devserver",
    command = "./node_modules/.bin/jasmine",
    data = glob(["*.spec.mjs"]) + [
        # Some packages to link back to the exec root for the tests for
        # https://github.com/aspect-build/rules_js/issues/1204 (and need jasmine
        # anyway for the runner)
        ":node_modules/@types/node",
        ":node_modules/jasmine",
    ],
)
