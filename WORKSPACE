# Declare the local Bazel workspace.
# This is *not* included in the published distribution.
workspace(
    # If your ruleset is "official"
    # (i.e. is in the bazelbuild GitHub org)
    # then this should just be named "rules_mylang"
    # see https://docs.bazel.build/versions/main/skylark/deploying.html#workspace
    name = "com_myorg_rules_mylang",
)

# Install our "runtime" dependencies which users install as well
load("//mylang:repositories.bzl", "mylang_register_toolchains", "rules_mylang_dependencies")

rules_mylang_dependencies()

load(":internal_deps.bzl", "rules_mylang_internal_deps")

rules_mylang_internal_deps()

mylang_register_toolchains(
    name = "mylang1_14",
    mylang_version = "1.14.2",
)
