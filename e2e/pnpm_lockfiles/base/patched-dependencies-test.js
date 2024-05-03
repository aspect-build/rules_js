const meaningOfLife = require('meaning-of-life')

// meaning-of-life should have been patched
if (meaningOfLife !== 'forty two') {
    throw new Error('`pnpm.patchedDependencies` was NOT applied!')
}
