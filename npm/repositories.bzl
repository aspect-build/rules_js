"""Repository rules to fetch third-party npm packages

Load these with,

```starlark
load("@aspect_rules_js//npm:repositories.bzl", "npm_translate_lock", "npm_import")
```

These use Bazel's downloader to fetch the packages.
You can use this to redirect all fetches through a store like Artifactory.

See <https://blog.aspect.dev/configuring-bazels-downloader> for more info about how it works
and how to configure it.

[`npm_translate_lock`](#npm_translate_lock) is the primary user-facing API.
It uses the lockfile format from [pnpm](https://pnpm.io/motivation) because it gives us reliable
semantics for how to dynamically lay out `node_modules` trees on disk in bazel-out.

To create `pnpm-lock.yaml`, consider using [`pnpm import`](https://pnpm.io/cli/import)
to preserve the versions pinned by your existing `package-lock.json` or `yarn.lock` file.

If you don't have an existing lock file, you can run `npx pnpm install --lockfile-only`.

Advanced users may want to directly fetch a package from npm rather than start from a lockfile,
[`npm_import`](./npm_import) does this.
"""

load("//npm/private:npm_import.bzl", _npm_import = "npm_import")
load("//npm/private:npm_translate_lock.bzl", _list_patches = "list_patches", _npm_translate_lock = "npm_translate_lock")
load("//npm/private:pnpm_repository.bzl", _LATEST_PNPM_VERSION = "LATEST_PNPM_VERSION", _pnpm_repository = "pnpm_repository")

npm_import = _npm_import
npm_translate_lock = _npm_translate_lock
pnpm_repository = _pnpm_repository
LATEST_PNPM_VERSION = _LATEST_PNPM_VERSION
list_patches = _list_patches
