# Declare the local Bazel workspace.
# This is *not* included in the published distribution.
workspace(
    # If your ruleset is "official"
    # (i.e. is in the bazelbuild GitHub org)
    # then this should just be named "rules_js"
    # see https://docs.bazel.build/versions/main/skylark/deploying.html#workspace
    name = "build_aspect_rules_js",
)

# Install our "runtime" dependencies which users install as well
load("//js:repositories.bzl", "js_register_toolchains", "rules_js_dependencies")

rules_js_dependencies()

load(":internal_deps.bzl", "rules_js_internal_deps")

rules_js_internal_deps()

js_register_toolchains(
    name = "js1_14",
    js_version = "1.14.2",
)
