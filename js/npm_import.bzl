"""Repository rules to fetch third-party npm packages

These use Bazel's downloader to fetch the packages.
You can use this to redirect all fetches through a store like Artifactory.

See <https://blog.aspect.dev/configuring-bazels-downloader> for more info about how it works
and how to configure it.

[`translate_pnpm_lock`](#translate_pnpm_lock) is the primary user-facing API.
It uses the lockfile format from [pnpm](https://pnpm.io/motivation) because it gives us reliable
semantics for how to dynamically lay out `node_modules` trees on disk in bazel-out.

To create `pnpm-lock.yaml`, consider using [`pnpm import`](https://pnpm.io/cli/import)
to preserve the versions pinned by your existing `package-lock.json` or `yarn.lock` file.

If you don't have an existing lock file, you can run `npx pnpm install --lockfile-only`.

Advanced users may want to directly fetch a package from npm rather than start from a lockfile.
[`npm_import`](#npm_import) does this.
"""

load("//js/private:npm_import.bzl", import_lib = "npm_import")
load("//js/private:translate_pnpm_lock.bzl", lib = "translate_pnpm_lock")

translate_pnpm_lock = repository_rule(
    doc = lib.doc,
    implementation = lib.implementation,
    attrs = lib.attrs,
)

npm_import = repository_rule(
    doc = import_lib.doc,
    implementation = import_lib.implementation,
    attrs = import_lib.attrs,
)
