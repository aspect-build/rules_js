"ts_project implementation"

# buildifier: disable=bzl-visibility
load("@rules_nodejs//nodejs/private:ts_project.bzl", _ts_project_lib = "ts_project")

# buildifier: disable=bzl-visibility
load("@rules_nodejs//nodejs/private:ts_validate_options.bzl", validate_lib = "lib")

validate_options = rule(
    implementation = validate_lib.implementation,
    attrs = validate_lib.attrs,
)

ts_project = rule(
    implementation = _ts_project_lib.implementation,
    attrs = _ts_project_lib.attrs,
)
