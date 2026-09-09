"""The file extensions rules_js reports as instrumented for code coverage."""

# TODO: check if there is more extensions
# TODO: .ts should not be here since we ought to only instrument transpiled files?
COVERAGE_EXTENSIONS = [
    "mjs",
    "mts",
    "cjs",
    "cts",
    "ts",
    "js",
    "jsx",
    "tsx",
]
