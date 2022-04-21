"Shows how a custom ruleset can export its npm dependencies"

load("@aspect_rules_js//js:npm_import.bzl", "translate_pnpm_lock")
load(":npm_repositories.bzl", "npm_repositories")

def repositories():
    translate_pnpm_lock(
        name = "rules_foo_npm",
        # yq -o=json -I=2 '.' pnpm-lock.yaml > pnpm-lock.json
        pnpm_lock = "@rules_foo//foo:pnpm-lock.json",
    )

    # The following comes from inlining the result of the translate_pnpm_lock call.
    # We do this so that users don't have to load() from rules_foo_npm in their WORKSPACE,
    # which makes their setup longer and makes bzlmod harder.
    # See https://github.com/bazelbuild/rules_python/issues/608
    npm_repositories()
