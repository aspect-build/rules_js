"public API for TypeScript"

# buildifier: disable=bzl-visibility
load("@rules_nodejs//nodejs/private:ts_config.bzl", _ts_config = "ts_config")
load("//ts/private:ts_project.bzl", "ts_project_macro")

ts_config = _ts_config
ts_project = ts_project_macro
