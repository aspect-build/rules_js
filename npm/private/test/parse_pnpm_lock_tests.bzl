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

expected_imports_injected = {
    ".": {
        "dependencies": {},
        "dev_dependencies": {},
        "optional_dependencies": {},
    },
    "packages/a": {
        "dependencies": {
            "b": "file:packages/b_typescript_5.6.2",
        },
        "dev_dependencies": {},
        "optional_dependencies": {},
    },
    "packages/b": {
        "dependencies": {
            "typescript": "5.6.2",
        },
        "dev_dependencies": {},
        "optional_dependencies": {},
    },
}
expected_packages_injected = {
    "file:packages/b_typescript_5.6.2": {
        "id": "file:packages/b",
        "name": "b",
        "dependencies": {
            "typescript": "5.6.2",
        },
        "optional_dependencies": {},
        "dev": False,
        "has_bin": False,
        "optional": False,
        "requires_build": False,
        "version": "file:packages/b_typescript_5.6.2",
        "friendly_version": "file:packages/b_typescript_5.6.2",
        "resolution": {
            "directory": "packages/b",
            "type": "directory",
        },
    },
    "typescript@5.6.2": {
        "id": None,
        "name": "typescript",
        "dependencies": {},
        "optional_dependencies": {},
        "dev": False,
        "has_bin": True,
        "optional": False,
        "requires_build": False,
        "version": "5.6.2",
        "friendly_version": "5.6.2",
        "resolution": {
            "integrity": "sha512-NW8ByodCSNCwZeghjN3o+JX5OFH0Ojg6sadjEKY4huZ52TqbJTJnDo5+Tw98lSy63NZvi4n+ez5m2u5d4PkZyw==",
        },
    },
}

# Example: https://github.com/pnpm/pnpm/blob/0672517f694da62dff7c33b9e723fbfb036eaefa/pnpm-lock.yaml
def _parse_lockfile_v5_test_impl(ctx):
    env = unittest.begin(ctx)

    parsed_json = pnpm.parse_pnpm_lock_json(json.encode({
        "lockfileVersion": 5.4,
        "specifiers": {
            "@aspect-test/a": "5.0.0",
        },
        "dependencies": {
            "@aspect-test/a": "5.0.0",
        },
        "packages": {
            "/@aspect-test/a/5.0.0": {
                "resolution": {
                    "integrity": "sha512-t/lwpVXG/jmxTotGEsmjwuihC2Lvz/Iqt63o78SI3O5XallxtFp5j2WM2M6HwkFiii9I42KdlAF8B3plZMz0Fw==",
                },
                "hasBin": True,
                "dependencies": {
                    # TODO Test data defect, all listed dependencies must have a definition
                    "@aspect-test/b": "5.0.0",
                    "@aspect-test/c": "1.0.0",
                    # Package has 1 peer dependency (`@aspect-test/c`), in v5 packages with more than 1 use a hash instead
                    "@aspect-test/d": "2.0.0_@aspect-test+c@1.0.0",
                },
                "dev": False,
            },
        },
    }))

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

    parsed_json = pnpm.parse_pnpm_lock_json(json.encode({
        "lockfileVersion": "6.0",
        "dependencies": {
            "@aspect-test/a": {
                "specifier": "5.0.0",
                "version": "5.0.0",
            },
        },
        "packages": {
            "/@aspect-test/a@5.0.0": {
                "resolution": {
                    "integrity": "sha512-t/lwpVXG/jmxTotGEsmjwuihC2Lvz/Iqt63o78SI3O5XallxtFp5j2WM2M6HwkFiii9I42KdlAF8B3plZMz0Fw==",
                },
                "hasBin": True,
                "dependencies": {
                    # TODO Test data defect, all listed dependencies must have a definition
                    "@aspect-test/b": "5.0.0",
                    "@aspect-test/c": "1.0.0",
                    # Package has 1 peer dependency (`@aspect-test/c`), packages with several peer dependencies may be given a hash (to satisfy Windows path length limits)
                    # `npm_translate_lock` will likewise replace the peer dependency component with a hash if too long.
                    "@aspect-test/d": "2.0.0(@aspect-test/c@1.0.0)",
                },
                "dev": False,
            },
        },
    }))

    expected = (
        expected_importers,
        expected_packages,
        {},
        6.0,
        None,
    )

    asserts.equals(env, expected, parsed_json)

    return unittest.end(env)

def _parse_lockfile_v6_local_injected_test_impl(ctx):
    env = unittest.begin(ctx)

    parsed_json = pnpm.parse_pnpm_lock_json(json.encode({
        "lockfileVersion": "6.0",
        "settings": {
            "autoInstallPeers": True,
            "excludeLinksFromLockfile": False,
        },
        "importers": {
            ".": {},
            "packages/a": {
                "dependencies": {
                    "b": {
                        "specifier": "workspace:*",
                        "version": "file:packages/b(typescript@5.6.2)",
                    },
                },
                "dependenciesMeta": {
                    "b": {
                        "injected": True,
                    },
                },
            },
            "packages/b": {
                "dependencies": {
                    "typescript": {
                        "specifier": "^5.6.2",
                        "version": "5.6.2",
                    },
                },
            },
        },
        "packages": {
            "/typescript@5.6.2": {
                "resolution": {
                    "integrity": "sha512-NW8ByodCSNCwZeghjN3o+JX5OFH0Ojg6sadjEKY4huZ52TqbJTJnDo5+Tw98lSy63NZvi4n+ez5m2u5d4PkZyw==",
                },
                "engines": {
                    "node": ">=14.17",
                },
                "hasBin": True,
                "dev": False,
            },
            "file:packages/b(typescript@5.6.2)": {
                "resolution": {
                    "directory": "packages/b",
                    "type": "directory",
                },
                "id": "file:packages/b",
                "name": "b",
                "peerDependencies": {
                    "typescript": "^5.6.2",
                },
                "dependencies": {
                    "typescript": "5.6.2",
                },
                "dev": False,
            },
        },
    }))

    expected = (
        expected_imports_injected,
        expected_packages_injected,
        {},
        6.0,
        None,
    )

    asserts.equals(env, expected, parsed_json)

    return unittest.end(env)

def _parse_lockfile_v9_test_impl(ctx):
    env = unittest.begin(ctx)

    parsed_json = pnpm.parse_pnpm_lock_json(json.encode({
        "lockfileVersion": "9.0",
        "settings": {
            "autoInstallPeers": True,
            "excludeLinksFromLockfile": False,
        },
        "importers": {
            ".": {
                "dependencies": {
                    "@aspect-test/a": {
                        "specifier": "5.0.0",
                        "version": "5.0.0",
                    },
                },
            },
        },
        "packages": {
            "@aspect-test/a@5.0.0": {
                "resolution": {
                    "integrity": "sha512-t/lwpVXG/jmxTotGEsmjwuihC2Lvz/Iqt63o78SI3O5XallxtFp5j2WM2M6HwkFiii9I42KdlAF8B3plZMz0Fw==",
                },
                "hasBin": True,
            },
        },
        "snapshots": {
            "@aspect-test/a@5.0.0": {
                "dependencies": {
                    # TODO Test data defect, all listed dependencies must have a definition
                    "@aspect-test/b": "5.0.0",
                    "@aspect-test/c": "1.0.0",
                    # Package has 1 peer dependency (`@aspect-test/c`), packages with several peer dependencies may be given a hash (to satisfy Windows path length limits)
                    # `npm_translate_lock` will likewise replace the peer dependency component with a hash if too long.
                    "@aspect-test/d": "2.0.0(@aspect-test/c@1.0.0)",
                },
            },
        },
    }))

    # NOTE: unknown properties in >=v9
    v9_expected_packages = dict(expected_packages)
    for pkg_name in v9_expected_packages.keys():
        v9_expected_packages[pkg_name] = dict(v9_expected_packages[pkg_name])
        v9_expected_packages[pkg_name]["dev"] = None
        v9_expected_packages[pkg_name]["requires_build"] = None

    expected = (
        expected_importers,
        v9_expected_packages,
        {},
        9.0,
        None,
    )

    asserts.equals(env, expected, parsed_json)

    return unittest.end(env)

def _parse_lockfile_v9_injected_local_test_impl(ctx):
    env = unittest.begin(ctx)

    parsed_json = pnpm.parse_pnpm_lock_json(json.encode({
        "lockfileVersion": "9.0",
        "settings": {
            "autoInstallPeers": True,
            "excludeLinksFromLockfile": False,
        },
        "importers": {
            ".": {},
            "packages/a": {
                "dependencies": {
                    "b": {
                        "specifier": "workspace:*",
                        "version": "file:packages/b(typescript@5.6.2)",
                    },
                },
                "dependenciesMeta": {
                    "b": {
                        "injected": True,
                    },
                },
            },
            "packages/b": {
                "dependencies": {
                    "typescript": {
                        "specifier": "^5.6.2",
                        "version": "5.6.2",
                    },
                },
            },
        },
        "packages": {
            "b@file:packages/b": {
                "resolution": {
                    "directory": "packages/b",
                    "type": "directory",
                },
                "name": "b",
                "peerDependencies": {
                    "typescript": "^5.6.2",
                },
            },
            "typescript@5.6.2": {
                "resolution": {
                    "integrity": "sha512-NW8ByodCSNCwZeghjN3o+JX5OFH0Ojg6sadjEKY4huZ52TqbJTJnDo5+Tw98lSy63NZvi4n+ez5m2u5d4PkZyw==",
                },
                "engines": {
                    "node": ">=14.17",
                },
                "hasBin": True,
            },
        },
        "snapshots": {
            "b@file:packages/b(typescript@5.6.2)": {
                "id": "b@file:packages/b",
                "dependencies": {
                    "typescript": "5.6.2",
                },
            },
            "typescript@5.6.2": {},
        },
    }))

    # NOTE: unknown properties in >=v9
    v9_expected_packages = dict(expected_packages_injected)
    for pkg_name in v9_expected_packages.keys():
        v9_expected_packages[pkg_name] = dict(v9_expected_packages[pkg_name])
        v9_expected_packages[pkg_name]["dev"] = None
        v9_expected_packages[pkg_name]["requires_build"] = None
        if pkg_name == "file:packages/b_typescript_5.6.2":
            # This is incorrect in v6, but correct in v9
            # v6 is used as reference so we override for v9 here
            v9_expected_packages[pkg_name]["friendly_version"] = "file:packages/b"

    expected = (
        expected_imports_injected,
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

def _test_convert_pnpm_v6_v9_version_peer_dep(ctx):
    env = unittest.begin(ctx)
    asserts.equals(
        env,
        "1.2.3",
        pnpm_test.convert_pnpm_v6_v9_version_peer_dep("1.2.3"),
    )
    asserts.equals(
        env,
        "1.2.3_at_scope_peer_2.0.2",
        pnpm_test.convert_pnpm_v6_v9_version_peer_dep("1.2.3(@scope/peer@2.0.2)"),
    )
    asserts.equals(
        env,
        "1.2.3_2001974805",
        pnpm_test.convert_pnpm_v6_v9_version_peer_dep("1.2.3(@scope/peer@2.0.2)(@scope/peer@4.5.6)"),
    )
    asserts.equals(
        env,
        "4.5.6_o3deharooos255qt5xdujc3cuq",
        pnpm_test.convert_pnpm_v6_v9_version_peer_dep("4.5.6(patch_hash=o3deharooos255qt5xdujc3cuq)"),
    )
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
g_test = unittest.make(_test_convert_pnpm_v6_v9_version_peer_dep, attrs = {})
h_test = unittest.make(_parse_lockfile_v6_local_injected_test_impl, attrs = {})
j_test = unittest.make(_parse_lockfile_v9_injected_local_test_impl, attrs = {})

TESTS = [
    a_test,
    b_test,
    c_test,
    d_test,
    e_test,
    f_test,
    g_test,
    h_test,
    j_test,
]

# buildifier: disable=function-docstring
def parse_pnpm_lock_tests(name):
    tests = []
    for index, test_rule in enumerate(TESTS):
        test_name = "{}_test_{}".format(name, index)
        test_rule(name = test_name)
        tests.append(":" + test_name)
    native.test_suite(
        name = name,
        tests = tests,
    )
