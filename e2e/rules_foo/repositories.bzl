"Shows how a custom ruleset can export its npm dependencies"

load("@aspect_rules_js//npm:npm_import.bzl", "npm_translate_lock")
load(":npm_repositories.bzl", "npm_repositories")

def repositories():
    npm_translate_lock(
        name = "rules_foo_npm",
        pnpm_lock = "@rules_foo//foo:pnpm-lock.yaml",
    )

    # The following comes from inlining the result of the npm_translate_lock call.
    # We do this so that users don't have to load() from rules_foo_npm in their WORKSPACE,
    # which makes their setup longer and makes bzlmod harder.
    # See https://github.com/bazelbuild/rules_python/issues/608
    npm_repositories()
