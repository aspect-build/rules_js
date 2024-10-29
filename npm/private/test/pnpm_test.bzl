"""Test for pnpm extension version resolution."""

load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")
load("//npm/private:pnpm_extension.bzl", "DEFAULT_PNPM_REPO_NAME", "resolve_pnpm_repositories")
load("//npm/private:pnpm_repository.bzl", "LATEST_PNPM_VERSION")

def _fake_pnpm_tag(version, name = DEFAULT_PNPM_REPO_NAME, integrity = None):
    return struct(
        name = name,
        pnpm_version = version,
        pnpm_version_integrity = integrity,
    )

def _fake_mod(is_root, *pnpm_tags):
    return struct(
        is_root = is_root,
        tags = struct(pnpm = pnpm_tags),
    )

def _resolve_test(ctx, repositories = [], notes = [], modules = []):
    env = unittest.begin(ctx)

    expected = struct(
        repositories = repositories,
        notes = notes,
    )

    result = resolve_pnpm_repositories(modules)

    asserts.equals(env, expected, result)
    return unittest.end(env)

def _basic(ctx):
    # Essentially what happens without any user configuration.
    # - Root module doesn't have any pnpm tag.
    # - rules_js sets a default.
    return _resolve_test(
        ctx,
        repositories = {"pnpm": ("8.6.7", "8.6.7-integrity")},
        modules = [
            _fake_mod(True),
            _fake_mod(
                False,
                _fake_pnpm_tag(version = "8.6.7", integrity = "8.6.7-integrity"),
            ),
        ],
    )

def _override(ctx):
    # What happens when the root overrides the pnpm version.
    return _resolve_test(
        ctx,
        repositories = {"pnpm": "9.1.0"},
        notes = [
            """NOTE: repo 'pnpm' has multiple versions ["9.1.0", "8.6.7"]; selected 9.1.0""",
        ],
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
        repositories = {"pnpm": LATEST_PNPM_VERSION},
        modules = [
            _fake_mod(True, _fake_pnpm_tag(version = "latest")),
        ],
    )

def _custom_name(ctx):
    return _resolve_test(
        ctx,
        repositories = {
            "my-pnpm": "9.1.0",
            "pnpm": ("8.6.7", "8.6.7-integrity"),
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
    # @gzm0, 2024-10-04: The behavior here is probably not intended and merely an implementation artifact.
    # I've added a test anyways to capture the existing behavior.

    return _resolve_test(
        ctx,
        repositories = {
            "pnpm": ("8.6.7", "dep-integrity"),
        },
        notes = [
            """NOTE: repo 'pnpm' has multiple versions ["8.6.7", "8.6.7"]; selected 8.6.7""",
        ],
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

basic_test = unittest.make(_basic)
override_test = unittest.make(_override)
latest_test = unittest.make(_latest)
custom_name_test = unittest.make(_custom_name)
integrity_conflict_test = unittest.make(_integrity_conflict)

def pnpm_tests(name):
    unittest.suite(
        name,
        basic_test,
        override_test,
        latest_test,
        custom_name_test,
        integrity_conflict_test,
    )
