"""Npm imports for example code"""

load("@aspect_rules_js//js:npm_import.bzl", "npm_import")
load("@example_npm_deps//:repositories.bzl", "npm_repositories")

def npm_imports():
    """Fetch some npm packages for testing our example"""

    # Manually import a package using explicit coordinates.
    # Just a demonstration of the syntax de-sugaring.
    npm_import(
        name = "example_npm_deps__acorn__8.4.0",
        integrity = "sha512-ULr0LDaEqQrMFGyQ3bhJkLsbtrQ8QibAseGZeaSUiT/6zb9IvIkomWHJIvgvwad+hinRAgsI51JcWk2yvwyL+w==",
        root_path = "example",
        package = "acorn",
        version = "8.4.0",
    )

    # Declare remaining npm_import rules
    npm_repositories()
