### pnpm lockfile testing across versions

TODO:

-   http references: `"hello": "https://gitpkg.vercel.app/EqualMa/gitpkg-hello/packages/hello"`

    Has inconsistencies across pnpm lockfile versions, issues with pnpm9

-   file references: `"@scoped/c": "file:../projects/c"`

    Has inconsistencies across pnpm lockfile versions, issues with pnpm9

-   npm: references: `@aspect-test/a2": "npm:@aspect-test/a"`

    No :node_modules/\* targets are generated for aliases to npm packages.
