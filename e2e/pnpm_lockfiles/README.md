### pnpm lockfile testing across versions

See notes in lockfile-test.bzl for test cases of each package.

## pnpm lockfile edge cases

Unique test cases hard to cover with normal pnpm workspaces + package.json. Each
test case is a pnpm-lock.yaml with a unique filename, see cases/BUILD for how the test
cases run on each of those lockfiles.
