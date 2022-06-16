load("@aspect_rules_js//js:defs.bzl", "js_binary", "js_run_binary", "js_test")
load("@pnpm__links//:defs.bzl", npm_link_pnpm = "npm_link_imported_package")

npm_link_pnpm(name = "node_modules")

js_test(
    name = "assert_lockfile_up_to_date",
    chdir = package_name(),
    data = [
        ":node_modules/pnpm",
        ":package.json",
        ":pnpm-lock.yaml",
    ],
    entry_point = "assert_lockfile_frozen.js",
    env = {
        # The script overrides the cache dir to point to the output tree but pnpm
        # will complain on Windows if it can't resolve a path to the default one.
        # The env var APPDATA just needs to exist but not be undefined.
        "APPDATA": "unused"

    }
)

js_binary(
    name = "update_lockfile_js",
    data = [":node_modules/pnpm"],
    entry_point = ":update_lockfile.js",
    env = {
        # The script overrides the cache dir to point to the output tree but pnpm
        # will complain on Windows if it can't resolve a path to the default one.
        # The env var APPDATA just needs to exist but not be undefined.
        "APPDATA": "unused"
    }
)

js_run_binary(
    name = "generate_lockfile",
    srcs = [
        ":package.json",
        ":pnpm-lock.yaml",
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
    chdir = package_name() + "/testdata",
    data = [
        ":node_modules/pnpm",
        ":testdata/package.json",
        ":testdata/pnpm-lock.yaml",
    ],
    entry_point = "assert_lockfile_frozen.js",
    expected_exit_code = 1,
)
