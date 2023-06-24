# npm_translate_lock_partial_clone E2E test

Tests that npm_translate_lock can reference a `package.json` file in the pnpm workspace that does
not exist in the clone. In this case, `project-a` is the workspace package that does not exist on
disk but it is referenced in `pnpm-workspaces.yaml`, the `pnpm-lock.yaml` file and in
`npm_translate_lock`.
