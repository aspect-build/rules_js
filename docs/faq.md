## Bazel isn't seeing my changes to package.json

rules_js relies on what's in the `pnpm-lock.yaml` file.
Make sure your changes are reflected there.

Want a Bazel test to assert the lockfile isn't stale? See our `examples/assert_lockfile_to_to_date`.
