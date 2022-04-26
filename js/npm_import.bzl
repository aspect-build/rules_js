"wrapper macro for npm_import repository rule"

load("//js/private:npm_import.bzl", import_lib = "npm_import")
load("//js/private:translate_pnpm_lock.bzl", lib = "translate_pnpm_lock")

_translate_pnpm_lock = repository_rule(
    doc = lib.doc,
    implementation = lib.implementation,
    attrs = lib.attrs,
)

npm_import = repository_rule(
    doc = import_lib.doc,
    implementation = import_lib.implementation,
    attrs = import_lib.attrs,
)

def translate_pnpm_lock(name, node_repository = "nodejs", **kwargs):
    if not native.existing_rule(node_repository + "_host"):
        fail("""\

translate_package_lock cannot find node repository named '%s'
- Are you missing a call to 'nodejs_register_toolchains'?
- Check the value of the node_repository attribute on translate_package_lock.""" % node_repository)
    _translate_pnpm_lock(
        name = name,
        node_repository = node_repository,
        **kwargs
    )
