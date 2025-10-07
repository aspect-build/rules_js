"""Helper functions for checking npm package visibility rules."""

def validate_npm_package_visibility(accessing_package, package_locations, visibility_config):
    """Validate that accessing_package can access all packages available at its location.

    Args:
        accessing_package: The bazel package trying to access npm packages
        package_locations: Dictionary mapping package names to lists of locations where they're available
        visibility_config: Dictionary mapping package names/patterns to visibility rules
    """
    # Get packages that would be created in this location
    packages_to_validate = []

    for package_name, locations in package_locations.items():
        if accessing_package in locations:
            packages_to_validate.append(package_name)

    # Validate each package
    for package_name in packages_to_validate:
        if not check_package_visibility(accessing_package, package_name, visibility_config):
            fail("""
Package visibility violation:

  Package: {}
  Requested by: {}

This package is not visible from your location.
Check the package_visibility configuration in your npm_translate_lock rule.

For more information, see: https://docs.aspect.build/rules/aspect_rules_js/docs/npm_translate_lock#package_visibility
""".format(package_name, accessing_package))

def check_package_visibility(accessing_package, package_name, visibility_config):
    """Check if accessing_package can access package_name based on visibility_config.

    Args:
        accessing_package: The bazel package trying to access the npm package
        package_name: The name of the npm package being accessed
        visibility_config: Dictionary mapping package names/patterns to visibility rules

    Returns:
        True if access is allowed, False otherwise
    """
    # Get visibility rules for this package
    visibility_rules = get_package_visibility_rules(package_name, visibility_config)

    # Check each visibility rule
    for rule in visibility_rules:
        if rule == "//visibility:public":
            return True

        # Package-specific access: //packages/foo:__pkg__
        if rule == "//" + accessing_package + ":__pkg__":
            return True

        # Subpackage access: //packages/foo:__subpackages__
        if rule.endswith(":__subpackages__"):
            rule_package = rule[2:-16]  # Remove "//" and ":__subpackages__"
            if accessing_package.startswith(rule_package + "/") or accessing_package == rule_package:
                return True

        # Target-specific access: //packages/foo:target
        if rule.startswith("//" + accessing_package + ":"):
            return True

    return False

def get_package_visibility_rules(package_name, visibility_config):
    """Get visibility rules for package_name from configuration.

    Args:
        package_name: The name of the npm package
        visibility_config: Dictionary mapping package names/patterns to visibility rules

    Returns:
        List of visibility rules for the package
    """
    # Direct package match
    if package_name in visibility_config:
        return visibility_config[package_name]

    # Wildcard match
    if "*" in visibility_config:
        return visibility_config["*"]

    # Default to public if not specified
    return ["//visibility:public"]
