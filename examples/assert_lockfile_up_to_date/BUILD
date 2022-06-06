load("@aspect_rules_js//js:defs.bzl", "js_run_binary", "js_binary", "js_test")

load("@pnpm__links//:defs.bzl", npm_link_pnpm = "npm_link_package")
npm_link_pnpm(name = "node_modules/pnpm")

js_test(
    name = "assert_lockfile_up_to_date",
    entry_point = "assert_lockfile_frozen.js",
    data = [
        ":pnpm-lock.yaml",
        ":package.json",
        ":node_modules/pnpm",
    ],
    chdir = package_name(),
)

js_binary(
    name = "update_lockfile_js",
    data = [":node_modules/pnpm"],
    entry_point = ":update_lockfile.js",
)

js_run_binary(
    name = "generate_lockfile",
    srcs = [
        ":pnpm-lock.yaml",
        ":package.json",
    ],
    outs = [
        "output-pnpm-lock.yaml",
    ],
    chdir = package_name(),
    tags = [
        "manual",
    ],
    tool = ":update_lockfile_js",
)

sh_binary(
    name = "update_pnpm_lockfile",
    srcs = ["copy_to_workspace.sh"],
    args = [
        "$(location output-pnpm-lock.yaml)",
        "examples/assert_lockfile_up_to_date/pnpm-lock.yaml",
    ],
    data = [
        "output-pnpm-lock.yaml",
    ],
)

# test that our frozen lockfile detection works on an out-of-date
# lockfile. The testdata lockfile was generated with `pnpm install --prod`
# This ensures that future updates to pnpm don't break our detection logic.
js_test(
    name = "test_assert_lockfile_frozen",
    entry_point = "assert_lockfile_frozen.js",
    data = [
        ":testdata/pnpm-lock.yaml",
        ":testdata/package.json",
        ":node_modules/pnpm",
    ],
    chdir = package_name() + "/testdata",
    expected_exit_code = 1,
)

