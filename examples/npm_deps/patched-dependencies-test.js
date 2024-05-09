const meaningOfLife = require('meaning-of-life')

// Verify meaning-of-life was patched with
//  examples/npm_deps/patches/meaning-of-life@1.0.0-pnpm.patch

if (meaningOfLife === 42) {
    throw new Error('Patches were not applied!')
}

if (meaningOfLife !== 'forty two') {
    throw new Error('`pnpm.patchedDependencies` was not applied!')
}
