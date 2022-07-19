"""Simple macro exposing the typescript tsc binary.

Most users should use ts_project from aspect-build/rules_ts instead.
"""

load("@npm//:typescript/package_json.bzl", typescript_bin = "bin")

def tsc(name, args = ["-p", "tsconfig.json"], **kwargs):
    typescript_bin.tsc(
        name = name,
        args = args,
        # Always run tsc with the working directory in the project folder
        chdir = native.package_name(),
        **kwargs
    )
