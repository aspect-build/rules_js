"""Preset exclusion patterns for npm packages."""

# Minimal basic exclusions. Similar to 'yarn_autoclean' but without test/asset/example/coverage dirs
# and only the most common build/config/misc files.
_DEFAULT = [
    # build scripts (files)
    "Makefile",
    "Gulpfile.js",
    "Gruntfile.js",

    # configs (files)
    "appveyor.yml",
    "circle.yml",
    "codeship-services.yml",
    "codeship-steps.yml",
    "wercker.yml",
    ".tern-project",
    ".gitattributes",
    ".editorconfig",
    ".*ignore",
    ".eslintrc",
    ".jshintrc",
    ".flowconfig",
    ".documentup.json",
    ".yarn-metadata.json",
    ".travis.yml",

    # misc (files)
    "*.md",
]

# Yarn autoclean exclusions
# Copied from https://github.com/yarnpkg/yarn/blob/7cafa512a777048ce0b666080a24e80aae3d66a9/src/cli/commands/autoclean.js#L16
# DO NOT EDIT: keep in sync with Yarn. If other presets want to share patterns copy them
# and do not refactor them into shared lists to ensure this list remains the same as yarn.
_YARN_AUTOCLEAN = [
    # test directories
    "**/__tests__/**",
    "**/test/**",
    "**/tests/**",
    "**/powered-test/**",

    # asset directories
    "**/docs/**",
    "**/doc/**",
    "**/website/**",
    "**/images/**",
    "**/assets/**",

    # examples
    "**/example/**",
    "**/examples/**",

    # code coverage directories
    "**/coverage/**",
    "**/.nyc_output/**",

    # build scripts (files)
    "Makefile",
    "Gulpfile.js",
    "Gruntfile.js",

    # configs (files)
    "appveyor.yml",
    "circle.yml",
    "codeship-services.yml",
    "codeship-steps.yml",
    "wercker.yml",
    ".tern-project",
    ".gitattributes",
    ".editorconfig",
    ".*ignore",
    ".eslintrc",
    ".jshintrc",
    ".flowconfig",
    ".documentup.json",
    ".yarn-metadata.json",
    ".travis.yml",

    # misc (files)
    "*.md",
]

# The presets available by name. These are the PUBLIC preset names.
EXCLUDE_PACKAGE_CONTENTS_PRESETS = {
    "basic": _DEFAULT,
    "yarn_autoclean": _YARN_AUTOCLEAN,
}
