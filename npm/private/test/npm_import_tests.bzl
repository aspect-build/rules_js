"Unit tests for npm_import codegen"

load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")
load("//npm/private:npm_import.bzl", "npm_import_testonly")

def _to_deps_attr_groups_test_impl(ctx):
    env = unittest.begin(ctx)

    deps = {
        '":plain"': "plain",
        '":os"': "os",
        '":cpu"': "cpu",
        '":libc"': "libc",
        '":os_cpu"': "os_cpu",
        '":os_libc"': "os_libc",
        '":cpu_libc"': "cpu_libc",
        '":all_gnu"': "all_gnu",
        '":all_musl"': "all_musl",
    }
    deps_oss = {
        '":os"': ["linux"],
        '":os_cpu"': ["linux"],
        '":os_libc"': ["linux"],
        '":all_gnu"': ["linux"],
        '":all_musl"': ["linux"],
    }
    deps_cpus = {
        '":cpu"': ["x64"],
        '":os_cpu"': ["x64"],
        '":cpu_libc"': ["x64"],
        '":all_gnu"': ["x64"],
        '":all_musl"': ["x64"],
    }
    deps_libcs = {
        '":libc"': ["musl"],
        '":os_libc"': ["glibc"],
        '":cpu_libc"': ["glibc"],
        '":all_gnu"': ["glibc"],
        '":all_musl"': ["!glibc"],
    }

    asserts.equals(env, """{
            ":plain": "plain",
        } | select({
            "@aspect_rules_js//platforms/pnpm:musl": {
                ":libc": "libc",
            },
            "//conditions:default": {},
        }) | select({
            "@aspect_rules_js//platforms/pnpm:x64": {
                ":cpu": "cpu",
            },
            "//conditions:default": {},
        }) | select({
            "@aspect_rules_js//platforms/pnpm:x64_glibc": {
                ":cpu_libc": "cpu_libc",
            },
            "//conditions:default": {},
        }) | select({
            "@aspect_rules_js//platforms/pnpm:linux": {
                ":os": "os",
            },
            "//conditions:default": {},
        }) | select({
            "@aspect_rules_js//platforms/pnpm:linux_glibc": {
                ":os_libc": "os_libc",
            },
            "//conditions:default": {},
        }) | select({
            "@aspect_rules_js//platforms/pnpm:linux_x64": {
                ":os_cpu": "os_cpu",
            },
            "//conditions:default": {},
        }) | select({
            "@aspect_rules_js//platforms/pnpm:linux_x64_glibc": {
                ":all_gnu": "all_gnu",
            },
            "@aspect_rules_js//platforms/pnpm:linux_x64_musl": {
                ":all_musl": "all_musl",
            },
            "//conditions:default": {},
        })""", npm_import_testonly.to_deps_attr(deps, deps_oss, deps_cpus, deps_libcs))

    return unittest.end(env)

def _to_deps_attr_unsupported_test_impl(ctx):
    env = unittest.begin(ctx)

    # Deps constrained to unsupported values are dropped rather than widened to the remaining dimensions.
    deps = {'":openharmony"': "openharmony", '":linux"': "linux"}
    deps_oss = {'":openharmony"': ["openharmony"], '":linux"': ["linux"]}
    deps_cpus = {'":openharmony"': ["arm64"], '":linux"': ["x64"]}

    asserts.equals(env, """select({
            "@aspect_rules_js//platforms/pnpm:linux_x64": {
                ":linux": "linux",
            },
            "//conditions:default": {},
        })""", npm_import_testonly.to_deps_attr(deps, deps_oss, deps_cpus, {}))
    asserts.equals(env, "{}", npm_import_testonly.to_deps_attr({'":sunos"': "sunos"}, {'":sunos"': ["sunos"]}, {}, {'":sunos"': ["glibc"]}))

    return unittest.end(env)

to_deps_attr_groups_test = unittest.make(_to_deps_attr_groups_test_impl)
to_deps_attr_unsupported_test = unittest.make(_to_deps_attr_unsupported_test_impl)

def npm_import_tests(name):
    unittest.suite(
        name,
        to_deps_attr_groups_test,
        to_deps_attr_unsupported_test,
    )
