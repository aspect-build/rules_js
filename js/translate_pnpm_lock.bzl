"repository rules for importing packages from npm"

load("//js/private:translate_pnpm_lock.bzl", lib = "translate_pnpm_lock")

translate_pnpm_lock = repository_rule(
    doc = lib.doc,
    implementation = lib.implementation,
    attrs = lib.attrs,
)
