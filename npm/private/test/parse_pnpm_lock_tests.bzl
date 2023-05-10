"Unit tests for pnpm lock file parsing logic"

load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")
load("//npm/private:utils.bzl", "utils")

def _parse_empty_lock_test_impl(ctx):
    env = unittest.begin(ctx)

    parsed = utils.parse_pnpm_lock("")
    expected = ({}, {}, {})

    asserts.equals(env, expected, parsed)

def _parse_lockfile_v5_test_impl(ctx):
    env = unittest.begin(ctx)

    parsed = utils.parse_pnpm_lock("""\
lockfileVersion: 5.4

specifiers:
    '@aspect-test/a': 5.0.0

dependencies:
    '@aspect-test/a': 5.0.0

packages:

    /@aspect-test/a/5.0.0:
        resolution: {integrity: sha512-t/lwpVXG/jmxTotGEsmjwuihC2Lvz/Iqt63o78SI3O5XallxtFp5j2WM2M6HwkFiii9I42KdlAF8B3plZMz0Fw==}
        hasBin: true
        dependencies:
            '@aspect-test/b': 5.0.0
            '@aspect-test/c': 1.0.0
            '@aspect-test/d': 2.0.0_@aspect-test+c@1.0.0
        dev: false
""")

    expected = (
        {
            ".": {
                "specifiers": {
                    "@aspect-test/a": "5.0.0",
                },
                "dependencies": {
                    "@aspect-test/a": "5.0.0",
                },
                "optionalDependencies": {},
                "devDependencies": {},
            },
        },
        {
            "/@aspect-test/a/5.0.0": {
                "resolution": {
                    "integrity": "sha512-t/lwpVXG/jmxTotGEsmjwuihC2Lvz/Iqt63o78SI3O5XallxtFp5j2WM2M6HwkFiii9I42KdlAF8B3plZMz0Fw==",
                },
                "hasBin": True,
                "dependencies": {
                    "@aspect-test/b": "5.0.0",
                    "@aspect-test/c": "1.0.0",
                    "@aspect-test/d": "2.0.0_@aspect-test+c@1.0.0",
                },
                "dev": False,
            },
        },
        {},
    )

    asserts.equals(env, expected, parsed)

    return unittest.end(env)

def _parse_lockfile_v6_test_impl(ctx):
    env = unittest.begin(ctx)

    parsed = utils.parse_pnpm_lock("""\
lockfileVersion: '6.0'

dependencies:
  '@aspect-test/a':
    specifier: 5.0.0
    version: 5.0.0

packages:

  /@aspect-test/a@5.0.0:
    resolution: {integrity: sha512-t/lwpVXG/jmxTotGEsmjwuihC2Lvz/Iqt63o78SI3O5XallxtFp5j2WM2M6HwkFiii9I42KdlAF8B3plZMz0Fw==}
    hasBin: true
    dependencies:
      '@aspect-test/b': 5.0.0
      '@aspect-test/c': 1.0.0
      '@aspect-test/d': 2.0.0(@aspect-test/c@1.0.0)
    dev: false
""")

    expected = (
        {
            ".": {
                "specifiers": {},
                "dependencies": {
                    "@aspect-test/a": "5.0.0",
                },
                "optionalDependencies": {},
                "devDependencies": {},
            },
        },
        {
            "/@aspect-test/a/5.0.0": {
                "resolution": {
                    "integrity": "sha512-t/lwpVXG/jmxTotGEsmjwuihC2Lvz/Iqt63o78SI3O5XallxtFp5j2WM2M6HwkFiii9I42KdlAF8B3plZMz0Fw==",
                },
                "hasBin": True,
                "dependencies": {
                    "@aspect-test/b": "5.0.0",
                    "@aspect-test/c": "1.0.0",
                    "@aspect-test/d": "2.0.0_at_aspect-test_c_1.0.0",
                },
                "dev": False,
                "optionalDependencies": {},
            },
        },
        {},
    )

    asserts.equals(env, expected, parsed)

    return unittest.end(env)

parse_lockfile_v5_test = unittest.make(
    _parse_lockfile_v5_test_impl,
    attrs = {},
)

parse_empty_lock_test = unittest.make(
    _parse_empty_lock_test_impl,
    attrs = {},
)

parse_lockfile_v6_test = unittest.make(
    _parse_lockfile_v6_test_impl,
    attrs = {},
)

def parse_pnpm_lock_tests(name):
    unittest.suite(name, parse_lockfile_v5_test, parse_lockfile_v6_test)
