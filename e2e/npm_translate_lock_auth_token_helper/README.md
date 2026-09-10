# tokenHelper auth integration test for npm_translate_lock

Companion to `npm_translate_lock_auth`. That test covers a static `_authToken`; this one
covers a [`tokenHelper`](https://pnpm.io/npmrc#urltokenhelper) declared in the `.npmrc`.

`token-helper.sh` prints the token from `ASPECT_GH_PACKAGES_AUTH_TOKEN`, and
`ASPECT_NPM_AUTH_TOKEN` must have permission to pull the `@aspect-priv-npm` scope, same as
the sibling test.

`update_pnpm_lock` is enabled and `test.sh` changes `package.json` so that `pnpm install`
runs with the private registry, which pnpm can only authenticate with because rules_js
resolves the `tokenHelper` into the `.npmrc` copy it hands to pnpm.
