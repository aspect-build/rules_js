"Shows how a custom ruleset can export its npm dependencies"

load("@aspect_rules_js//npm:npm_import.bzl", "npm_translate_lock")
load(":npm_repositories.bzl", "npm_repositories")

def repositories():
    npm_translate_lock(
        name = "rules_foo_npm",
        # Since this rule set is meant to be consumed as an external repository, the lock file must be a fully
        # qualified label that includes the workspace name.
        pnpm_lock = "@rules_foo//foo:pnpm-lock.yaml",
        # Since this rule set is meant to be consumed as an external repository, link_workspace must be set when using
        # Bazel 5.3.0 or later and must match the workspace name of the lock file.
        link_workspace = "rules_foo",
    )

    # The following comes from inlining the result of the npm_translate_lock call.
    # We do this so that users don't have to load() from rules_foo_npm in their WORKSPACE,
    # which makes their setup longer and makes bzlmod harder.
    # See https://github.com/bazelbuild/rules_python/issues/608
    npm_repositories()
