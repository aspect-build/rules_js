load("@aspect_rules_js//js:translate_pnpm_lock.bzl", "translate_pnpm_lock")

def repositories():
    translate_pnpm_lock(
        name = "rules_foo_npm",
        # yq -o=json -I=2 '.' pnpm-lock.yaml > pnpm-lock.json
        pnpm_lock = "@rules_foo//foo:pnpm-lock.json",
    )
