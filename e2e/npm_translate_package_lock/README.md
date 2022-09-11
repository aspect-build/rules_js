# Simple integration test for npm_translate_lock

Exercises `package_json`, `npm_package_lock` and `npmrc` attributes of `npm_translate_lock`.

`npmrc` attribute is intentionally load bearing here since the `karma-typescript` package has
intentional unmet missing peer dependencies and `pnpm import` (run by `npm_translate_lock` when
importing from a npm package lock file) will fail inside `npm_translate_lock` unless
`strict-peer-dependencies=false` is set in `.npmrc`.
