## Bazel isn't seeing my changes to package.json

rules_js relies on what's in the `pnpm-lock.yaml` file.
Make sure your changes are reflected there.

Want a Bazel test to assert the lockfile isn't stale? See our `examples/assert_lockfile_to_to_date`.

## Can I edit files in `node_modules` for debugging?

Try running Bazel with `--experimental_check_output_files=false` so that your edits inside the `bazel-out/node_modules` tree are preserved.

## Why can't Bazel fetch an npm package?

If the error looks like this: `failed to fetch. no such package '@npm__foo__1.2.3//': at offset 773, object has duplicate key`
then you are hitting https://github.com/bazelbuild/bazel/issues/15605

The workaround is to patch the package.json of any offending packages in npm_translate_lock, see https://github.com/aspect-build/rules_js/issues/148#issuecomment-1144378565.
Or, if a newer version of the package has fixed the duplicate keys, you could upgrade.
