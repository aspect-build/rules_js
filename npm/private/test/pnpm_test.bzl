"""Test for pnpm extension version resolution."""

load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")
load("//npm/private:pnpm.bzl", "pnpm")
load("//npm/private:pnpm_extension.bzl", "DEFAULT_PNPM_REPO_NAME", "resolve_pnpm_repositories")
load("//npm/private:pnpm_repository.bzl", "LATEST_PNPM_VERSION")

def _fake_pnpm_tag(version = None, name = DEFAULT_PNPM_REPO_NAME, integrity = None, pnpm_version_from = None, include_npm = False):
    return struct(
        name = name,
        pnpm_version = version,
        pnpm_version_from = pnpm_version_from,
        pnpm_version_integrity = integrity,
        include_npm = include_npm,
    )

def _fake_mod(is_root, *pnpm_tags):
    return struct(
        is_root = is_root,
        tags = struct(pnpm = pnpm_tags),
    )

def _resolve_test(ctx, repositories = [], notes = [], modules = [], package_json_content = None):
    env = unittest.begin(ctx)

    expected = struct(
        repositories = repositories,
        notes = notes,
        facts = None,
    )

    result = resolve_pnpm_repositories(struct(modules = modules, read = lambda f: package_json_content))

    asserts.equals(env, expected, result)
    return unittest.end(env)

def _basic(ctx):
    # Essentially what happens without any user configuration.
    # - Root module doesn't have any pnpm tag.
    # - rules_js sets a default.
    return _resolve_test(
        ctx,
        repositories = {"pnpm": {"version": "8.6.7", "integrity": "8.6.7-integrity", "include_npm": False}},
        modules = [
            _fake_mod(True),
            _fake_mod(
                False,
                _fake_pnpm_tag(version = "8.6.7", integrity = "8.6.7-integrity"),
            ),
        ],
    )

def _from_package_json_simple(ctx):
    # Test reading pnpm version from package.json without integrity hash.
    # packageManager: "pnpm@1.2.3" -> version only, no integrity tuple
    return _resolve_test(
        ctx,
        repositories = {"pnpm": {"version": "1.2.3", "integrity": None, "include_npm": False}},
        modules = [
            _fake_mod(True, _fake_pnpm_tag(pnpm_version_from = "//:package.json")),
        ],
        package_json_content = json.encode({"packageManager": "pnpm@1.2.3"}),
    )

def _from_package_json_with_hash(ctx):
    # Test reading pnpm version from package.json with integrity hash.
    # packageManager: "pnpm@1.2.3+sha512.xxx" -> (version, integrity) tuple
    return _resolve_test(
        ctx,
        repositories = {"pnpm": {"version": "1.2.3", "integrity": "sha512-97462997561378b6f52ac5c614f3a3b923a652ad5ac987100286e4aa2d84a6a0642e9e45f3d01d30c46b12b20beb0f86aeb790bf9a82bc59db42b67fe69d1a25", "include_npm": False}},
        modules = [
            _fake_mod(True, _fake_pnpm_tag(pnpm_version_from = "//:package.json")),
        ],
        package_json_content = json.encode({"packageManager": "pnpm@1.2.3+sha512.97462997561378b6f52ac5c614f3a3b923a652ad5ac987100286e4aa2d84a6a0642e9e45f3d01d30c46b12b20beb0f86aeb790bf9a82bc59db42b67fe69d1a25"}),
    )

def _override(ctx):
    # What happens when the root overrides the pnpm version.
    return _resolve_test(
        ctx,
        repositories = {"pnpm": {"version": "9.1.0", "integrity": "sha512-Z/WHmRapKT5c8FnCOFPVcb6vT3U8cH9AyyK+1fsVeMaq07bEEHzLO6CzW+AD62IaFkcayDbIe+tT+dVLtGEnJA==", "include_npm": False}},
        notes = [],
        modules = [
            _fake_mod(
                True,
                _fake_pnpm_tag(version = "9.1.0"),
            ),
            _fake_mod(
                False,
                _fake_pnpm_tag(version = "8.6.7", integrity = "8.6.7-integrity"),
            ),
        ],
    )

def _latest(ctx):
    # Test the "latest" magic version,
    #
    # The test case is not entirely realistic: In reality, we'd have at least two tags:
    # - The one of the root module (present in the test)
    # - The one from rules_js (omitted in the test).
    #
    # We do this, to avoid `notes` that are dependent on `LATEST_PNPM_VERSION`.
    # Otherwise we'd have to either:
    # - Use regexes to check notes.
    # - Accept a brittle test.
    return _resolve_test(
        ctx,
        repositories = {"pnpm": {"version": LATEST_PNPM_VERSION, "integrity": "sha512-fX27yp6ZRHt8O/enMoavqva+mSUeuUmLrvp9QGiS9nuHmts6HX5of8TMwaOIxxdfuq5WeiarRNEGe1T8sNajFg==", "include_npm": False}},
        modules = [
            _fake_mod(True, _fake_pnpm_tag(version = "latest")),
        ],
    )

def _include_npm(ctx):
    return _resolve_test(
        ctx,
        repositories = {
            "pnpm": {"version": "9.1.0", "integrity": "sha512-Z/WHmRapKT5c8FnCOFPVcb6vT3U8cH9AyyK+1fsVeMaq07bEEHzLO6CzW+AD62IaFkcayDbIe+tT+dVLtGEnJA==", "include_npm": True},
            "wnpm": {"version": "9.2.0", "integrity": "sha512-mKgP0RwucJZ0d2IwQQZDKz3cZ9z1S1qMAck/aKLNXgXmghhJUioG+3YoTUGiZg1eM08u47vykYO/LnObHa+ncQ==", "include_npm": True},
        },
        modules = [
            _fake_mod(True, _fake_pnpm_tag(version = "9.1.0", include_npm = True)),
            _fake_mod(True, _fake_pnpm_tag(name = "wnpm", version = "9.2.0", include_npm = False)),
            _fake_mod(True, _fake_pnpm_tag(name = "wnpm", version = "9.2.0", include_npm = True)),
        ],
    )

def _custom_name(ctx):
    return _resolve_test(
        ctx,
        repositories = {
            "my-pnpm": {"version": "9.1.0", "integrity": "sha512-Z/WHmRapKT5c8FnCOFPVcb6vT3U8cH9AyyK+1fsVeMaq07bEEHzLO6CzW+AD62IaFkcayDbIe+tT+dVLtGEnJA==", "include_npm": False},
            "pnpm": {"version": "8.6.7", "integrity": "8.6.7-integrity", "include_npm": False},
        },
        modules = [
            _fake_mod(
                True,
                _fake_pnpm_tag(name = "my-pnpm", version = "9.1.0"),
            ),
            _fake_mod(
                False,
                _fake_pnpm_tag(version = "8.6.7", integrity = "8.6.7-integrity"),
            ),
        ],
    )

def _integrity_conflict(ctx):
    # What happens if two modules define the same version with conflicting integrity parameters.
    # Currently we print nothing to indicate this, we trust whichever integrity wins.
    return _resolve_test(
        ctx,
        repositories = {
            "pnpm": {"version": "8.6.7", "integrity": "dep-integrity", "include_npm": False},
        },
        # Modules are *BFS* from root:
        # https://bazel.build/rules/lib/builtins/module_ctx#modules
        modules = [
            _fake_mod(
                True,
                _fake_pnpm_tag(version = "8.6.7", integrity = "root-integrity"),
            ),
            _fake_mod(
                False,
                _fake_pnpm_tag(version = "8.6.7", integrity = "dep-integrity"),
            ),
        ],
    )

def _cpu_constraints(ctx):
    env = unittest.begin(ctx)
    asserts.equals(env, ["@aspect_rules_js//platforms/pnpm:arm64"], pnpm.to_bazel_cpu_constraints(["arm64"]))
    asserts.equals(env, ["@aspect_rules_js//platforms/pnpm:arm64", "@aspect_rules_js//platforms/pnpm:riscv64"], pnpm.to_bazel_cpu_constraints(["arm64", "riscv64"]))
    asserts.equals(
        env,
        ["@aspect_rules_js//platforms/pnpm:ppc", "@aspect_rules_js//platforms/pnpm:ppc64", "@aspect_rules_js//platforms/pnpm:s390x", "@aspect_rules_js//platforms/pnpm:ia32", "@aspect_rules_js//platforms/pnpm:mips", "@aspect_rules_js//platforms/pnpm:wasm32"],
        pnpm.to_bazel_cpu_constraints(["!arm", "!arm64", "!riscv64", "!x64"]),
    )
    return unittest.end(env)

def _os_constraints(ctx):
    env = unittest.begin(ctx)
    asserts.equals(env, ["@aspect_rules_js//platforms/pnpm:darwin"], pnpm.to_bazel_os_constraints(["darwin"]))
    asserts.equals(env, ["@aspect_rules_js//platforms/pnpm:win32", "@aspect_rules_js//platforms/pnpm:linux"], pnpm.to_bazel_os_constraints(["win32", "linux"]))
    asserts.equals(env, ["@aspect_rules_js//platforms/pnpm:darwin"], pnpm.to_bazel_os_constraints(["darwin", "sunos"]))
    asserts.equals(env, ["@aspect_rules_js//platforms/pnpm:win32", "@aspect_rules_js//platforms/pnpm:android", "@aspect_rules_js//platforms/pnpm:netbsd"], pnpm.to_bazel_os_constraints(["!linux", "!darwin", "!freebsd", "!openbsd", "!aix"]))
    return unittest.end(env)

def _os_cpu_constraints(ctx):
    env = unittest.begin(ctx)
    asserts.equals(env, ["@aspect_rules_js//platforms/pnpm:darwin_arm64"], pnpm.to_bazel_os_cpu_constraints(["darwin"], ["arm64"]))
    asserts.equals(
        env,
        ["@aspect_rules_js//platforms/pnpm:win32_x64", "@aspect_rules_js//platforms/pnpm:linux_x64"],
        pnpm.to_bazel_os_cpu_constraints(["win32", "linux"], ["x64"]),
    )
    return unittest.end(env)

basic_test = unittest.make(_basic)
override_test = unittest.make(_override)
latest_test = unittest.make(_latest)
custom_name_test = unittest.make(_custom_name)
include_npm_test = unittest.make(_include_npm)
integrity_conflict_test = unittest.make(_integrity_conflict)
from_package_json_simple_test = unittest.make(_from_package_json_simple)
from_package_json_with_hash_test = unittest.make(_from_package_json_with_hash)
cpu_constraints_test = unittest.make(_cpu_constraints)
os_constraints_test = unittest.make(_os_constraints)
os_cpu_constraints_test = unittest.make(_os_cpu_constraints)

def pnpm_tests(name):
    unittest.suite(
        name,
        basic_test,
        override_test,
        latest_test,
        custom_name_test,
        include_npm_test,
        integrity_conflict_test,
        from_package_json_simple_test,
        from_package_json_with_hash_test,
        cpu_constraints_test,
        os_constraints_test,
        os_cpu_constraints_test,
    )
