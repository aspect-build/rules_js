# Use bazel to update your pnpm lockfile

This shows an example of how you can add some bazel targets to test that your pnpm lockfile is
up-to-date, and run another target to update it.

`:assert_lockfile_up_to_date` is a test target that will perform a quick check to ensure that your
lockfile is not out-of-date (what `pnpm install --frozen-lockfile` checks for).

When that test target fails, it will print out information instructing you to run `bazel run
:update_pnpm_lockfile`, which will run a `pnpm install` and copy the resulting updated lockfile to
your workspace.

The dual target approach was taken instead of adding a generated file test on the generated
`pnpm-lock.yaml` file because generating that lockfile requires downloading packages and running a
longer install command. With the test target defined here, the check to assert that the lockfile
isn't out-of-date runs in ~0.5 seconds and does not access any network resources to do so.

## Limitations

Using something this with pnpm workspaces would require that you list out all of the `package.json`
files used in your various workspaces. This is problematic, as it would be duplicating the
information in `pnpm-workspace.yaml`. Future work could potentially migrate this into a repository
rule that parses the `pnpm-workspace.yaml` file and generates targets with the correct runtime
dependencies on all of the needed `package.json` files.
