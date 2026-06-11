"""Test for pnpm extension version resolution."""

load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")
load("//npm/private:pnpm.bzl", "pnpm")
load("//npm/private:pnpm_extension.bzl", "DEFAULT_PNPM_REPO_NAME", "resolve_pnpm_repositories")
load("//npm/private:pnpm_repository.bzl", "DEFAULT_PNPM_VERSION", "LATEST_PNPM_VERSION")
load("//npm/private:versions.bzl", "PNPM_VERSIONS")

# NB: version defaults to the empty sentinel, mirroring the real tag attribute, so a
# bare _fake_pnpm_tag() is equivalent to the default registration from rules_js itself.
def _fake_pnpm_tag(version = "", name = DEFAULT_PNPM_REPO_NAME, integrity = None, pnpm_version_from = None, include_npm = False, patches = [], patch_args = ["-p1"]):
    return struct(
        name = name,
        pnpm_version = version,
        pnpm_version_from = pnpm_version_from,
        pnpm_version_integrity = integrity,
        include_npm = include_npm,
        patches = patches,
        patch_args = patch_args,
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
        repositories = {"pnpm": {"version": "8.6.7", "integrity": "8.6.7-integrity", "include_npm": False, "patches": [], "patch_args": ["-p1"]}},
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
        repositories = {"pnpm": {"version": "1.2.3", "integrity": None, "include_npm": False, "patches": [], "patch_args": ["-p1"]}},
        modules = [
            _fake_mod(True, _fake_pnpm_tag(pnpm_version_from = "//:package.json")),
        ],
        package_json_content = json.encode({"packageManager": "pnpm@1.2.3"}),
    )

def _from_package_json_with_hash(ctx):
    # Test reading pnpm version from package.json with integrity hash in the hexadecimal format
    # that is standard for corepack. The integrity needs to be in SRI format (base64).
    # packageManager: "pnpm@1.2.3+sha512.<base64>" -> (version, integrity) tuple
    return _resolve_test(
        ctx,
        repositories = {"pnpm": {"version": "1.2.3", "integrity": "sha512-l0Ypl1YTeLb1KsXGFPOjuSOmUq1ayYcQAobkqi2EpqBkLp5F89AdMMRrErIL6w+GrreQv5qCvFnbQrZ/5p0aJQ==", "include_npm": False, "patches": [], "patch_args": ["-p1"]}},
        modules = [
            _fake_mod(True, _fake_pnpm_tag(pnpm_version_from = "//:package.json")),
        ],
        package_json_content = json.encode({"packageManager": "pnpm@1.2.3+sha512.97462997561378b6f52ac5c614f3a3b923a652ad5ac987100286e4aa2d84a6a0642e9e45f3d01d30c46b12b20beb0f86aeb790bf9a82bc59db42b67fe69d1a25"}),
    )

def _override(ctx):
    # What happens when the root overrides the pnpm version.
    return _resolve_test(
        ctx,
        repositories = {"pnpm": {"version": "9.1.0", "integrity": "sha512-Z/WHmRapKT5c8FnCOFPVcb6vT3U8cH9AyyK+1fsVeMaq07bEEHzLO6CzW+AD62IaFkcayDbIe+tT+dVLtGEnJA==", "include_npm": False, "patches": [], "patch_args": ["-p1"]}},
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
        repositories = {"pnpm": {"version": LATEST_PNPM_VERSION, "integrity": PNPM_VERSIONS[LATEST_PNPM_VERSION], "include_npm": False, "patches": [], "patch_args": ["-p1"]}},
        modules = [
            _fake_mod(True, _fake_pnpm_tag(version = "latest")),
        ],
    )

def _include_npm(ctx):
    return _resolve_test(
        ctx,
        repositories = {
            "pnpm": {"version": "9.1.0", "integrity": "sha512-Z/WHmRapKT5c8FnCOFPVcb6vT3U8cH9AyyK+1fsVeMaq07bEEHzLO6CzW+AD62IaFkcayDbIe+tT+dVLtGEnJA==", "include_npm": True, "patches": [], "patch_args": ["-p1"]},
            "wnpm": {"version": "9.2.0", "integrity": "sha512-mKgP0RwucJZ0d2IwQQZDKz3cZ9z1S1qMAck/aKLNXgXmghhJUioG+3YoTUGiZg1eM08u47vykYO/LnObHa+ncQ==", "include_npm": True, "patches": [], "patch_args": ["-p1"]},
        },
        modules = [
            _fake_mod(True, _fake_pnpm_tag(version = "9.1.0", include_npm = True)),
            _fake_mod(True, _fake_pnpm_tag(name = "wnpm", version = "9.2.0", include_npm = False)),
            _fake_mod(True, _fake_pnpm_tag(name = "wnpm", version = "9.2.0", include_npm = True)),
        ],
    )

def _include_npm_other_version_wins(ctx):
    # include_npm is a per-repo setting, not per-version: a version-less tag asking to
    # bundle npm must be honored even when another module's explicit version is the one
    # selected. Otherwise the npm request would be silently dropped.
    return _resolve_test(
        ctx,
        repositories = {"pnpm": {"version": "9.1.0", "integrity": "sha512-Z/WHmRapKT5c8FnCOFPVcb6vT3U8cH9AyyK+1fsVeMaq07bEEHzLO6CzW+AD62IaFkcayDbIe+tT+dVLtGEnJA==", "include_npm": True, "patches": [], "patch_args": ["-p1"]}},
        modules = [
            # Root brings the repo into scope and wants npm, but expresses no version.
            _fake_mod(True, _fake_pnpm_tag(include_npm = True)),
            # A dependency pins the version that ends up selected.
            _fake_mod(False, _fake_pnpm_tag(version = "9.1.0")),
        ],
    )

def _custom_name(ctx):
    return _resolve_test(
        ctx,
        repositories = {
            "my-pnpm": {"version": "9.1.0", "integrity": "sha512-Z/WHmRapKT5c8FnCOFPVcb6vT3U8cH9AyyK+1fsVeMaq07bEEHzLO6CzW+AD62IaFkcayDbIe+tT+dVLtGEnJA==", "include_npm": False, "patches": [], "patch_args": ["-p1"]},
            "pnpm": {"version": "8.6.7", "integrity": "8.6.7-integrity", "include_npm": False, "patches": [], "patch_args": ["-p1"]},
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

def _dep_version_with_default_registration(ctx):
    # A non-root module explicitly requests a pnpm version while another non-root
    # module (rules_js itself, which always registers `pnpm.pnpm(name = "pnpm")`)
    # carries the default version.
    #
    # The rules_js registration comes first in BFS order ("aspect_rules_js" sorts
    # before nearly all module names) and must not mask the explicit request,
    # even when the explicit request is for a lower version than the default.
    # See https://github.com/aspect-build/rules_js/pull/2349#discussion_r3362093839
    return _resolve_test(
        ctx,
        repositories = {"pnpm": {"version": "9.1.0", "integrity": "sha512-Z/WHmRapKT5c8FnCOFPVcb6vT3U8cH9AyyK+1fsVeMaq07bEEHzLO6CzW+AD62IaFkcayDbIe+tT+dVLtGEnJA==", "include_npm": False, "patches": [], "patch_args": ["-p1"]}},
        modules = [
            _fake_mod(True),
            # rules_js itself: a bare pnpm.pnpm(name = "pnpm") tag carrying the default version
            _fake_mod(False, _fake_pnpm_tag()),
            _fake_mod(False, _fake_pnpm_tag(version = "9.1.0")),
        ],
    )

def _dep_versions_mvs(ctx):
    # Multiple non-root modules explicitly request different pnpm versions:
    # the highest wins, with a note. The default registration from rules_js
    # does not participate in the selection.
    return _resolve_test(
        ctx,
        repositories = {"pnpm": {"version": "9.2.0", "integrity": "sha512-mKgP0RwucJZ0d2IwQQZDKz3cZ9z1S1qMAck/aKLNXgXmghhJUioG+3YoTUGiZg1eM08u47vykYO/LnObHa+ncQ==", "include_npm": False, "patches": [], "patch_args": ["-p1"]}},
        notes = ["""NOTE: repo 'pnpm' has multiple versions ["9.1.0", "9.2.0"]; selected 9.2.0"""],
        modules = [
            _fake_mod(True),
            _fake_mod(False, _fake_pnpm_tag()),
            _fake_mod(False, _fake_pnpm_tag(version = "9.1.0")),
            _fake_mod(False, _fake_pnpm_tag(version = "9.2.0")),
        ],
    )

def _root_default_dep_version(ctx):
    # The root module registers a bare tag (no version preference, e.g. just to
    # bring the repo into scope). A dep's explicit version wins over the default
    # version carried by the root's bare tag.
    return _resolve_test(
        ctx,
        repositories = {"pnpm": {"version": "9.1.0", "integrity": "sha512-Z/WHmRapKT5c8FnCOFPVcb6vT3U8cH9AyyK+1fsVeMaq07bEEHzLO6CzW+AD62IaFkcayDbIe+tT+dVLtGEnJA==", "include_npm": False, "patches": [], "patch_args": ["-p1"]}},
        modules = [
            _fake_mod(True, _fake_pnpm_tag()),
            _fake_mod(False, _fake_pnpm_tag(version = "9.1.0")),
        ],
    )

def _root_explicit_default_beats_dep(ctx):
    # Explicitly requesting the default version is distinct from not requesting a
    # version at all: it is a real request from the root module and therefore wins
    # over a (higher) version requested by a non-root module.
    # See https://github.com/aspect-build/rules_js/pull/2883#discussion_r3367024654
    return _resolve_test(
        ctx,
        repositories = {"pnpm": {"version": DEFAULT_PNPM_VERSION, "integrity": PNPM_VERSIONS[DEFAULT_PNPM_VERSION], "include_npm": False, "patches": [], "patch_args": ["-p1"]}},
        modules = [
            _fake_mod(True, _fake_pnpm_tag(version = DEFAULT_PNPM_VERSION)),
            _fake_mod(False, _fake_pnpm_tag(version = "11.0.9")),
        ],
    )

def _root_lower_than_default(ctx):
    # The realistic override case: the root module pins the default "pnpm" repo to
    # a version *lower* than DEFAULT_PNPM_VERSION, while rules_js itself carries the
    # default registration. The root's explicit (lower) pin must win; a naive
    # "Minimal Version Selection across all registrations" would wrongly keep the
    # higher default and silently ignore the user's pin.
    return _resolve_test(
        ctx,
        repositories = {"pnpm": {"version": "9.1.0", "integrity": "sha512-Z/WHmRapKT5c8FnCOFPVcb6vT3U8cH9AyyK+1fsVeMaq07bEEHzLO6CzW+AD62IaFkcayDbIe+tT+dVLtGEnJA==", "include_npm": False, "patches": [], "patch_args": ["-p1"]}},
        modules = [
            _fake_mod(True, _fake_pnpm_tag(version = "9.1.0")),
            # rules_js itself: a bare pnpm.pnpm(name = "pnpm") tag carrying DEFAULT_PNPM_VERSION
            _fake_mod(False, _fake_pnpm_tag()),
        ],
    )

def _integrity_conflict(ctx):
    # What happens if two modules define the same version with conflicting integrity parameters.
    # Currently we print nothing to indicate this, we trust whichever integrity wins.
    return _resolve_test(
        ctx,
        repositories = {
            "pnpm": {"version": "8.6.7", "integrity": "dep-integrity", "include_npm": False, "patches": [], "patch_args": ["-p1"]},
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

def _patch_args_empty(ctx):
    # An explicit patch_args = [] must not be silently dropped in favour of ["-p1"].
    return _resolve_test(
        ctx,
        repositories = {"pnpm": {"version": "9.1.0", "integrity": "sha512-Z/WHmRapKT5c8FnCOFPVcb6vT3U8cH9AyyK+1fsVeMaq07bEEHzLO6CzW+AD62IaFkcayDbIe+tT+dVLtGEnJA==", "include_npm": False, "patches": ["//some:patch.patch"], "patch_args": []}},
        modules = [
            _fake_mod(
                True,
                _fake_pnpm_tag(version = "9.1.0", patches = ["//some:patch.patch"], patch_args = []),
            ),
        ],
    )

def _default_version(ctx):
    # Lockfile format is tied to the pnpm major. Pinning the default to v10
    # keeps the lockfile format at v9; bumping the major changes the format
    # and is a breaking change for users. Guard against accidental bumps.
    env = unittest.begin(ctx)
    asserts.equals(env, "10", DEFAULT_PNPM_VERSION.split(".")[0])
    return unittest.end(env)

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

    # "alpine" is not a Node.js process.platform value but is used by some packages (e.g. @vscode/vsce-sign-alpine-*).
    # It should be recognized as a known (but unsupported) OS value and filtered out, not cause a hard failure.
    # See https://github.com/aspect-build/rules_js/issues/2745
    asserts.equals(env, [], pnpm.to_bazel_os_constraints(["alpine"]))
    asserts.equals(env, ["@aspect_rules_js//platforms/pnpm:linux"], pnpm.to_bazel_os_constraints(["alpine", "linux"]))
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
dep_version_with_default_registration_test = unittest.make(_dep_version_with_default_registration)
dep_versions_mvs_test = unittest.make(_dep_versions_mvs)
root_default_dep_version_test = unittest.make(_root_default_dep_version)
root_explicit_default_beats_dep_test = unittest.make(_root_explicit_default_beats_dep)
root_lower_than_default_test = unittest.make(_root_lower_than_default)
latest_test = unittest.make(_latest)
custom_name_test = unittest.make(_custom_name)
include_npm_test = unittest.make(_include_npm)
include_npm_other_version_wins_test = unittest.make(_include_npm_other_version_wins)
integrity_conflict_test = unittest.make(_integrity_conflict)
from_package_json_simple_test = unittest.make(_from_package_json_simple)
from_package_json_with_hash_test = unittest.make(_from_package_json_with_hash)
patch_args_empty_test = unittest.make(_patch_args_empty)
default_version_test = unittest.make(_default_version)
cpu_constraints_test = unittest.make(_cpu_constraints)
os_constraints_test = unittest.make(_os_constraints)
os_cpu_constraints_test = unittest.make(_os_cpu_constraints)

def pnpm_tests(name):
    unittest.suite(
        name,
        basic_test,
        override_test,
        dep_version_with_default_registration_test,
        dep_versions_mvs_test,
        root_default_dep_version_test,
        root_explicit_default_beats_dep_test,
        root_lower_than_default_test,
        latest_test,
        custom_name_test,
        include_npm_test,
        include_npm_other_version_wins_test,
        integrity_conflict_test,
        from_package_json_simple_test,
        from_package_json_with_hash_test,
        patch_args_empty_test,
        default_version_test,
        cpu_constraints_test,
        os_constraints_test,
        os_cpu_constraints_test,
    )
