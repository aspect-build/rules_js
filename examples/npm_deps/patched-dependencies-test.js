const meaningOfLife = require('meaning-of-life')

// meaning-of-life should have been patched twice:
//
// First, by the `pnpm.patchedDependencies` patch:
//  examples/npm_deps/patches/meaning-of-life@1.0.0-pnpm.patch
// 42 => "forty two"
//
// Then by the the following patch in the `patches` attr:
//  examples/npm_deps/patches/meaning-of-life@1.0.0-after_pnpm.patch
// "forty two" => 32

if (meaningOfLife === 42) {
    throw new Error('Patches were not applied!')
} else if (meaningOfLife === 'forty two') {
    throw new Error('Only `pnpm.patchedDependencies` patch was applied!')
} else if (meaningOfLife !== 32) {
    throw new Error('Patch in `patches` was not applied!')
}
