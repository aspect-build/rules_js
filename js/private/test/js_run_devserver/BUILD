load("@npm//:defs.bzl", "npm_link_all_packages")
load("//js:defs.bzl", "js_binary")
load(":js_run_devserver_test.bzl", "js_run_devserver_test")

npm_link_all_packages(name = "node_modules")

# Test that bundlers see a single node_modules tree.
# https://github.com/aspect-build/rules_js/issues/1204
js_run_devserver_test(
    name = "single_node_modules_tree_test",
    tool = ":test_single_node_modules_tree_binary",
    chdir = "js/private/test/js_run_devserver",
    data = [
        "app.jsx",

        # 1st-party package
        ":node_modules/@my-org/test-component",

        ":node_modules/html-webpack-plugin",
        ":node_modules/http-server",
        ":node_modules/puppeteer",
        ":node_modules/react",
        ":node_modules/react-dom",
        ":node_modules/webpack",
    ],
)

js_binary(
    name = "test_single_node_modules_tree_binary",
    entry_point = "test_single_node_modules_tree.mjs",
)
