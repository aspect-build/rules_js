load("@aspect_rules_js//js:defs.bzl", "run_js_binary", "js_binary", "js_test")

load("@pnpm__links//:defs.bzl", link_pnpm = "link_npm_package")
link_pnpm(name = "link_pnpm")

js_binary(
    name = "update_lockfile_js",
    data = [":link_pnpm"],
    entry_point = ":update_lockfile.js",
)

js_test(
    name = "assert_lockfile_up_to_date",
    entry_point = "assert_lockfile_frozen.js",
    data = [
        ":pnpm-lock.yaml",
        ":package.json",
        ":link_pnpm",
    ],
    chdir = package_name(),
)

# test that our frozen lockfile detection works on an out-of-date
# lockfile. The testdata lockfile was generated with `pnpm install --prod`
js_test(
    name = "test_assert_lockfile_frozen",
    entry_point = "assert_lockfile_frozen.js",
    data = [
        ":testdata/pnpm-lock.yaml",
        ":testdata/package.json",
        ":link_pnpm",
    ],
    chdir = package_name() + "/testdata",
    expected_exit_code = 1,
)


run_js_binary(
    name = "build_lockfile_js",
    srcs = [
        # I'm not sure if pnpm actually needs the lockfile here.
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
