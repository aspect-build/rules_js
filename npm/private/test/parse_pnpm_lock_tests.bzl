"Unit tests for pnpm lock file parsing logic"

load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")
load("//npm/private:utils.bzl", "utils")

def _parse_empty_lock_test_impl(ctx):
    env = unittest.begin(ctx)

    parsed_json_a = utils.parse_pnpm_lock_json("")
    parsed_json_b = utils.parse_pnpm_lock_json("{}")
    expected = ({}, {}, {}, None)

    asserts.equals(env, expected, parsed_json_a)
    asserts.equals(env, expected, parsed_json_b)

    return unittest.end(env)

expected_importers = {
    ".": {
        "dependencies": {
            "@aspect-test/a": "5.0.0",
        },
        "dev_dependencies": {},
        "optional_dependencies": {},
    },
}
expected_packages = {
    "@aspect-test/a@5.0.0": {
        "id": None,
        "name": "@aspect-test/a",
        "dependencies": {
            "@aspect-test/b": "5.0.0",
            "@aspect-test/c": "1.0.0",
            "@aspect-test/d": "2.0.0_at_aspect-test_c_1.0.0",
        },
        "optional_dependencies": {},
        "peer_dependencies": {},
        "dev": False,
        "has_bin": True,
        "optional": False,
        "requires_build": False,
        "version": "5.0.0",
        "friendly_version": "5.0.0",
        "resolution": {
            "integrity": "sha512-t/lwpVXG/jmxTotGEsmjwuihC2Lvz/Iqt63o78SI3O5XallxtFp5j2WM2M6HwkFiii9I42KdlAF8B3plZMz0Fw==",
        },
    },
}

def _parse_lockfile_v5_test_impl(ctx):
    env = unittest.begin(ctx)

    parsed_json = utils.parse_pnpm_lock_json("""\
{
  "lockfileVersion": 5.4,
  "specifiers": {
    "@aspect-test/a": "5.0.0"
  },
  "dependencies": {
    "@aspect-test/a": "5.0.0"
  },
  "packages": {
    "/@aspect-test/a/5.0.0": {
      "resolution": {
        "integrity": "sha512-t/lwpVXG/jmxTotGEsmjwuihC2Lvz/Iqt63o78SI3O5XallxtFp5j2WM2M6HwkFiii9I42KdlAF8B3plZMz0Fw=="
      },
      "hasBin": true,
      "dependencies": {
        "@aspect-test/b": "5.0.0",
        "@aspect-test/c": "1.0.0",
        "@aspect-test/d": "2.0.0_@aspect-test+c@1.0.0"
      },
      "dev": false
    }
  }
}
""")

    expected = (
        expected_importers,
        expected_packages,
        {},
        5.4,
        None,
    )

    asserts.equals(env, expected, parsed_json)

    return unittest.end(env)

def _parse_lockfile_v6_test_impl(ctx):
    env = unittest.begin(ctx)

    parsed_json = utils.parse_pnpm_lock_json("""\
{
  "lockfileVersion": "6.0",
  "dependencies": {
    "@aspect-test/a": {
      "specifier": "5.0.0",
      "version": "5.0.0"
    }
  },
  "packages": {
    "/@aspect-test/a@5.0.0": {
      "resolution": {
        "integrity": "sha512-t/lwpVXG/jmxTotGEsmjwuihC2Lvz/Iqt63o78SI3O5XallxtFp5j2WM2M6HwkFiii9I42KdlAF8B3plZMz0Fw=="
      },
      "hasBin": true,
      "dependencies": {
        "@aspect-test/b": "5.0.0",
        "@aspect-test/c": "1.0.0",
        "@aspect-test/d": "2.0.0(@aspect-test/c@1.0.0)"
      },
      "dev": false
    }
  }
}
""")

    expected = (
        expected_importers,
        expected_packages,
        {},
        6.0,
        None,
    )

    asserts.equals(env, expected, parsed_json)

    return unittest.end(env)

def _parse_lockfile_v9_test_impl(ctx):
    env = unittest.begin(ctx)

    parsed_json = utils.parse_pnpm_lock_json("""\
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
    }
  },
  "snapshots": {
    "@aspect-test/a@5.0.0": {
      "dependencies": {
        "@aspect-test/b": "5.0.0",
        "@aspect-test/c": "1.0.0",
        "@aspect-test/d": "2.0.0(@aspect-test/c@1.0.0)"
      }
    }
  }
}
""")

    # NOTE: unknown properties in >=v9
    v9_expected_packages = dict(expected_packages)
    v9_expected_packages["@aspect-test/a@5.0.0"] = dict(v9_expected_packages["@aspect-test/a@5.0.0"])
    v9_expected_packages["@aspect-test/a@5.0.0"]["dev"] = None
    v9_expected_packages["@aspect-test/a@5.0.0"]["requires_build"] = None

    expected = (
        expected_importers,
        v9_expected_packages,
        {},
        9.0,
        None,
    )

    asserts.equals(env, expected, parsed_json)

    return unittest.end(env)

a_test = unittest.make(_parse_empty_lock_test_impl, attrs = {})
b_test = unittest.make(_parse_lockfile_v5_test_impl, attrs = {})
c_test = unittest.make(_parse_lockfile_v6_test_impl, attrs = {})
d_test = unittest.make(_parse_lockfile_v9_test_impl, attrs = {})

TESTS = [
    a_test,
    b_test,
    c_test,
    d_test,
]

def parse_pnpm_lock_tests(name):
    for index, test_rule in enumerate(TESTS):
        test_rule(name = "{}_test_{}".format(name, index))
