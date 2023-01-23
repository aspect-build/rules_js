# Npm auth integration test for npm_translate_lock

Auth token(s) are set in `.npmrc` to fetch packages from private registries.

npm auth token with permission to pull packages from `@aspect-priv-npm` scope must be set in
`ASPECT_NPM_AUTH_TOKEN` environment variable for this e2e test to pass.
