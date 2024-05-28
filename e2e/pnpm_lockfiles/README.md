### pnpm lockfile testing across versions

TODO:

-   http references: `"hello": "https://gitpkg.vercel.app/EqualMa/gitpkg-hello/packages/hello"`

    Has inconsistencies across pnpm lockfile versions, issues with pnpm9

-   npm: references: `@aspect-test/a2": "npm:@aspect-test/a"`

    No :node_modules/\* targets are generated for aliases to npm packages.

    Note: _sometimes_ fails to install with pnpm9

## pnpm lockfile edge cases

Unique test cases hard to cover with normal pnpm workspaces + package.json. Each
test case is a pnpm-lock.yaml with a unique filename, see cases/BUILD for how the test
cases run on each of those lockfiles.
