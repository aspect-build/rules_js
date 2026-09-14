# Bazel credential helper integration test for npm_translate_lock

Companion to `npm_translate_lock_auth`. That test authenticates through `.npmrc`; this one has
no `.npmrc` at all. Registries are declared with the `registries` setting of `pnpm-workspace.yaml`
(pnpm 11) and a
[Bazel credential helper](https://bazel.build/reference/command-line-reference#flag--credential_helper)
serves both sides of the private registries:

-   `npm_import` downloads go through Bazel's downloader, which honors `--credential_helper`
    from `.bazelrc`.
-   `update_pnpm_lock` runs `pnpm install`, which knows nothing about Bazel, so the same helper
    is passed to `npm_translate_lock(credential_helpers = ...)` and rules_js hands the credentials
    it returns to pnpm. `test.sh` changes `package.json` to exercise that path.

`credential-helper.sh` answers with `ASPECT_GH_PACKAGES_AUTH_TOKEN` for `npm.pkg.github.com`
and `ASPECT_NPM_AUTH_TOKEN` for `registry.npmjs.org`, same secrets as the sibling tests.
