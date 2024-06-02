### pnpm lockfile testing across versions

See notes in lockfile-test.bzl for test cases of each package.

## pnpm lockfile edge cases (./cases/\*)

Unique test cases hard to cover with normal pnpm workspaces + package.json. Each
test case is a pnpm-lock.yaml with a unique filename, see cases/BUILD for how the test
cases run on each of those lockfiles.

-   `isaacs-cliui-v*`: a transitive `npm:` dependency as an alias to use multiple versions of a single package, this is different then a direct `npm:` dependency
-   `override-with-alias-url-v9` - a package overridden with a different package
-   `tarball-no-url-v54` - a package with a tarball but not a full URL
