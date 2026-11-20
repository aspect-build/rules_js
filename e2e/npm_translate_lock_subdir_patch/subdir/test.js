// debug.patched is only available after patching.
const debug = require('debug')
const libE = require('@aspect-test/e')
process.exit(debug.patched === true && libE.PATCHED === 123 && libE.PATCH_TOOL === true ? 0 : 1)
