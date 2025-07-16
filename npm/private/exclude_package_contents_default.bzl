"""A default files exclude list for common packages.

Based on Yarn autoclean; see
https://github.com/yarnpkg/yarn/blob/7cafa512a777048ce0b666080a24e80aae3d66a9/src/cli/commands/autoclean.js#L16
"""

exclude_package_contents_default = [
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
