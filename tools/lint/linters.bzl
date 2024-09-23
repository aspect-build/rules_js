"Create linter aspects, see https://github.com/aspect-build/rules_lint/blob/main/docs/linting.md#installation"

load("@aspect_rules_lint//lint:eslint.bzl", "lint_eslint_aspect")

eslint = lint_eslint_aspect(
    binary = "@@//tools/lint:eslint",
    configs = ["@@//:eslintrc"],
)
