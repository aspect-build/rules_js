"""Npm dependencies for example code"""

load("@aspect_rules_js//js:npm_import.bzl", _translate_pnpm_lock = "translate_pnpm_lock")

def translate_pnpm_lock():
    """Translate the pnpm-lock.yaml file for example dependencies"""

    _translate_pnpm_lock(
        name = "example_npm_deps",
        patch_args = {
            "@gregmagolan/test-a": ["-p1"],
        },
        patches = {
            "@gregmagolan/test-a": ["//example:test-a.patch"],
            "@gregmagolan/test-a@0.0.1": ["//example:test-a@0.0.1.patch"],
        },
        pnpm_lock = "//example:pnpm-lock.yaml",
        postinstall = {
            "@aspect-test/c": "echo 'moo' > cow.txt",
            "@aspect-test/c@2.0.0": "echo 'mooo' >> cow.txt",
            "*": "echo 'moooo' > global_cow.txt",
        },
    )
