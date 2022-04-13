"wrapper macro for npm_import repository rule"

load("//js/private:npm_import.bzl", lib = "npm_import")

npm_import = repository_rule(
    doc = lib.doc,
    implementation = lib.implementation,
    attrs = lib.attrs,
)