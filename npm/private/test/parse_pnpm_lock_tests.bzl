"Unit tests for pnpm lock file parsing logic"

load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")
load("//npm/private:pnpm.bzl", "pnpm")

def _parse_empty_lock_test_impl(ctx):
    env = unittest.begin(ctx)

    parsed_json_a = pnpm.parse_pnpm_lock_json("")
    parsed_json_b = pnpm.parse_pnpm_lock_json("{}")
    expected = ({}, {}, {}, None)

    asserts.equals(env, expected, parsed_json_a)
    asserts.equals(env, expected, parsed_json_b)

    return unittest.end(env)

expected_importers = {
    ".": {
        "name": None,
        "dependencies": {
            "@aspect-test/a": "5.0.0",
            "lodash": "file:lodash-4.17.21.tgz",
        },
        "dev_dependencies": {},
        "optional_dependencies": {},
    },
}
expected_packages = {
    "@aspect-test/a@5.0.0": {
        "name": "@aspect-test/a",
        "dependencies": {},
        "optional_dependencies": {},
        "has_bin": True,
        "optional": False,
        "version": "5.0.0",
        "friendly_version": "5.0.0",
        "resolution": {
            "integrity": "sha512-t/lwpVXG/jmxTotGEsmjwuihC2Lvz/Iqt63o78SI3O5XallxtFp5j2WM2M6HwkFiii9I42KdlAF8B3plZMz0Fw==",
        },
    },
    "file:lodash-4.17.21.tgz": {
        "name": "lodash",
        "dependencies": {},
        "optional_dependencies": {},
        "has_bin": False,
        "optional": False,
        "version": "file:lodash-4.17.21.tgz",
        "friendly_version": "4.17.21",
        "resolution": {
            "integrity": "sha512-v2kDEe57lecTulaDIuNTPy3Ry4gLGJ6Z1O3vE1krgXZNrsQ+LFTGHVxVjcXPs17LhbZVGedAJv8XZ1tvj5FvSg==",
            "tarball": "file:lodash-4.17.21.tgz",
        },
    },
}

def _parse_lockfile_v9_test_impl(ctx):
    env = unittest.begin(ctx)

    parsed_json = pnpm.parse_pnpm_lock_json("""\
{
  "lockfileVersion": "9.0",
  "settings": {
    "autoInstallPeers": true,
    "excludeLinksFromLockfile": false
  },
  "importers": {
    ".": {
      "dependencies": {
        "@aspect-test/a": {
          "specifier": "5.0.0",
          "version": "5.0.0"
        },
        "lodash": {
          "specifier": "file:lodash-4.17.21.tgz",
          "version": "file:lodash-4.17.21.tgz"
        }
      }
    }
  },
  "packages": {
    "@aspect-test/a@5.0.0": {
      "resolution": {
        "integrity": "sha512-t/lwpVXG/jmxTotGEsmjwuihC2Lvz/Iqt63o78SI3O5XallxtFp5j2WM2M6HwkFiii9I42KdlAF8B3plZMz0Fw=="
      },
      "hasBin": true
    },
    "lodash@file:lodash-4.17.21.tgz": {
      "resolution": {
        "integrity": "sha512-v2kDEe57lecTulaDIuNTPy3Ry4gLGJ6Z1O3vE1krgXZNrsQ+LFTGHVxVjcXPs17LhbZVGedAJv8XZ1tvj5FvSg==",
        "tarball": "file:lodash-4.17.21.tgz"
      },
      "version": "4.17.21"
    }
  },
  "snapshots": {
    "@aspect-test/a@5.0.0": {
      "dependencies": {}
    },
    "lodash@file:lodash-4.17.21.tgz": { }
  }
}
""")

    # NOTE: unknown properties in >=v9, convert to <v9 defaults for test assertions
    v9_expected_packages = dict(expected_packages)
    v9_expected_packages["@aspect-test/a@5.0.0"] = dict(v9_expected_packages["@aspect-test/a@5.0.0"])
    v9_expected_packages["lodash@file:lodash-4.17.21.tgz"] = dict(v9_expected_packages["file:lodash-4.17.21.tgz"])
    v9_expected_packages.pop("file:lodash-4.17.21.tgz")  # renamed with lodash@ in v9

    expected = (
        expected_importers,
        v9_expected_packages,
        {},
        None,
    )

    asserts.equals(env, expected, parsed_json)

    return unittest.end(env)

# buildifier: disable=function-docstring
def _test_version_supported(ctx):
    env = unittest.begin(ctx)

    # Unsupported versions + msgs
    msg = pnpm.assert_lockfile_version(5.3, testonly = True)
    asserts.equals(env, "npm_translate_lock requires lock_version at least 9.0, but found 5.3. Please upgrade to pnpm v9 or greater.", msg)
    msg = pnpm.assert_lockfile_version(1.2, testonly = True)
    asserts.equals(env, "npm_translate_lock requires lock_version at least 9.0, but found 1.2. Please upgrade to pnpm v9 or greater.", msg)
    msg = pnpm.assert_lockfile_version(5.4, testonly = True)
    asserts.equals(env, "npm_translate_lock requires lock_version at least 9.0, but found 5.4. Please upgrade to pnpm v9 or greater.", msg)
    msg = pnpm.assert_lockfile_version(6.0, testonly = True)
    asserts.equals(env, "npm_translate_lock requires lock_version at least 9.0, but found 6.0. Please upgrade to pnpm v9 or greater.", msg)
    msg = pnpm.assert_lockfile_version(6.1, testonly = True)
    asserts.equals(env, "npm_translate_lock requires lock_version at least 9.0, but found 6.1. Please upgrade to pnpm v9 or greater.", msg)
    msg = pnpm.assert_lockfile_version(99.99, testonly = True)
    asserts.equals(env, "npm_translate_lock currently supports a maximum lock_version of 9.0, but found 99.99. Please file an issue on rules_js", msg)

    # supported versions
    pnpm.assert_lockfile_version(9.0)

    return unittest.end(env)

a_test = unittest.make(_parse_empty_lock_test_impl, attrs = {})
d_test = unittest.make(_parse_lockfile_v9_test_impl, attrs = {})
e_test = unittest.make(_test_version_supported, attrs = {})

TESTS = [
    a_test,
    d_test,
    e_test,
]

def parse_pnpm_lock_tests(name):
    for index, test_rule in enumerate(TESTS):
        test_rule(name = "{}_test_{}".format(name, index))
