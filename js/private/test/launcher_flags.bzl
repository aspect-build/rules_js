"""target_compatible_with values for tests that only one js_binary launcher can run.

A target gets one launcher per configuration, so a test of launcher-specific behavior has
to be skipped under the other one; CI covers both by running the whole suite twice. See
docs/hermetic_launcher.md.
"""

BASH_LAUNCHER_ONLY = select({
    Label("//js:_hermetic_launcher_true"): ["@platforms//:incompatible"],
    "//conditions:default": [],
})

HERMETIC_LAUNCHER_ONLY = select({
    Label("//js:_hermetic_launcher_true"): [],
    "//conditions:default": ["@platforms//:incompatible"],
})
