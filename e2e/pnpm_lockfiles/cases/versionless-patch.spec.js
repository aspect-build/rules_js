const libE = require('@aspect-test/e')

if (libE.PATCHED !== 123) {
    throw new Error('Failed to patch @aspect-test/e')
}
