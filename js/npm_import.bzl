"wrapper macro for npm_import repository rule"

load("//js/private:npm_import.bzl", import_lib = "npm_import")
load("//js/private:translate_pnpm_lock.bzl", lib = "translate_pnpm_lock")

translate_pnpm_lock = repository_rule(
    doc = lib.doc,
    implementation = lib.implementation,
    attrs = lib.attrs,
)

npm_import = repository_rule(
    doc = import_lib.doc,
    implementation = import_lib.implementation,
    attrs = import_lib.attrs,
)
