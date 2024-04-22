"Shows how a custom rule set can export its npm dependencies"

load("@aspect_rules_js//npm:repositories.bzl", _npm_translate_lock = "npm_translate_lock")

def foo_repositories():
    _npm_translate_lock(
        name = "foo",
        pnpm_lock = "@rules_foo//foo:pnpm-lock.yaml",
        # We'll be linking in the @foo repository and not the repository where the pnpm-lock file is located
        link_workspace = "foo",
        # Override the Bazel package where pnpm-lock.yaml is located and link to the specified package instead
        root_package = "",
        defs_bzl_filename = "npm_link_all_packages.bzl",
        repositories_bzl_filename = "npm_repositories.bzl",
        additional_file_contents = {
            "BUILD.bazel": [
                """load("//:npm_link_all_packages.bzl", "npm_link_all_packages")""",
                """npm_link_all_packages(name = "node_modules")""",
            ],
            # Test that we can add statements to the generated defs bzl file
            "npm_link_all_packages.bzl": [
                """load("@aspect_rules_js//js:defs.bzl", _js_run_binary = "js_run_binary")""",
                """def js_run_binary(**kwargs):
    _js_run_binary(**kwargs)""",
            ],
        },
    )
