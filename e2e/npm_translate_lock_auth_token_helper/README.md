# tokenHelper auth integration test for npm_translate_lock

Companion to `npm_translate_lock_auth`. That test covers a static `_authToken`; this one
covers a [`tokenHelper`](https://pnpm.io/npmrc#urltokenhelper) read from the file named by
the `npmrc_auth_file` attribute.

`token-helper.sh` prints the token from `ASPECT_GH_PACKAGES_AUTH_TOKEN`, and
`ASPECT_NPM_AUTH_TOKEN` must have permission to pull the `@aspect-priv-npm` scope, same as
the sibling test.
