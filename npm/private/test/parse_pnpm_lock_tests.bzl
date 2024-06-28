"Unit tests for pnpm lock file parsing logic"

load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")
load("//npm/private:pnpm.bzl", "pnpm", "pnpm_test")

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

    parsed_json = pnpm.parse_pnpm_lock_json("""\
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

    parsed_json = pnpm.parse_pnpm_lock_json("""\
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

# buildifier: disable=function-docstring
def _test_strip_peer_dep_or_patched_version(ctx):
    env = unittest.begin(ctx)
    asserts.equals(
        env,
        "21.1.0",
        pnpm_test.strip_v5_peer_dep_or_patched_version("21.1.0_rollup@2.70.2_x@1.1.1"),
    )
    asserts.equals(env, "1.0.0", pnpm_test.strip_v5_peer_dep_or_patched_version("1.0.0_o3deharooos255qt5xdujc3cuq"))
    asserts.equals(env, "21.1.0", pnpm_test.strip_v5_peer_dep_or_patched_version("21.1.0"))
    return unittest.end(env)

# buildifier: disable=function-docstring
def _test_version_supported(ctx):
    env = unittest.begin(ctx)

    # Unsupported versions + msgs
    msg = pnpm.assert_lockfile_version(5.3, testonly = True)
    asserts.equals(env, "npm_translate_lock requires lock_version at least 5.4, but found 5.3. Please upgrade to pnpm v7 or greater.", msg)
    msg = pnpm.assert_lockfile_version(1.2, testonly = True)
    asserts.equals(env, "npm_translate_lock requires lock_version at least 5.4, but found 1.2. Please upgrade to pnpm v7 or greater.", msg)
    msg = pnpm.assert_lockfile_version(99.99, testonly = True)
    asserts.equals(env, "npm_translate_lock currently supports a maximum lock_version of 9.0, but found 99.99. Please file an issue on rules_js", msg)

    # supported versions
    pnpm.assert_lockfile_version(5.4)
    pnpm.assert_lockfile_version(6.0)
    pnpm.assert_lockfile_version(6.1)
    pnpm.assert_lockfile_version(9.0)

    return unittest.end(env)

a_test = unittest.make(_parse_empty_lock_test_impl, attrs = {})
b_test = unittest.make(_parse_lockfile_v5_test_impl, attrs = {})
c_test = unittest.make(_parse_lockfile_v6_test_impl, attrs = {})
d_test = unittest.make(_parse_lockfile_v9_test_impl, attrs = {})
e_test = unittest.make(_test_version_supported, attrs = {})
f_test = unittest.make(_test_strip_peer_dep_or_patched_version, attrs = {})

TESTS = [
    a_test,
    b_test,
    c_test,
    d_test,
    e_test,
    f_test,
]

def parse_pnpm_lock_tests(name):
    for index, test_rule in enumerate(TESTS):
        test_rule(name = "{}_test_{}".format(name, index))
