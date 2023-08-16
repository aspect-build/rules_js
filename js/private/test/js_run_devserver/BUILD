load("@npm//:defs.bzl", "npm_link_all_packages")
load(":js_run_devserver_test.bzl", "js_run_devserver_test")

npm_link_all_packages(name = "node_modules")

# Checks node_modules symlinks that they refer to exec root (instead of runfiles)
# in order to make sure bundlers see exactly one node_modules tree. Checks:
#     - https://github.com/aspect-build/rules_js/pull/1043
#     - https://github.com/aspect-build/rules_js/issues/1204
js_run_devserver_test(
    name = "node_modules_symlink_to_execroot_test",
    args = ["node_modules_symlink_to_execroot.test.mjs"],
    chdir = "js/private/test/js_run_devserver",
    command = "./node_modules/.bin/jasmine",
    data = [
        "node_modules_symlink_to_execroot.test.mjs",

        # Some packages to link back to the exec root for the tests for
        # https://github.com/aspect-build/rules_js/issues/1204 (and need jasmine
        # anyway for the runner)
        ":node_modules/@types/node",
        ":node_modules/jasmine",
    ],
)
