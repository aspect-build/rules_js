# Dynamic .npmrc authentication integration test

Tests that authentication tokens are read dynamically from `.npmrc` on each download,
not cached statically. Critical for short-lived credentials like AWS CodeArtifact tokens.

Auth token with permission to pull packages from `@aspect-test` scope must be set in
`ASPECT_NPM_AUTH_TOKEN` environment variable for this e2e test to pass.
