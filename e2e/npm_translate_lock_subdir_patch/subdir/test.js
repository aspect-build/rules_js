// debug.patched is only available after patching.
const debug = require('debug')
process.exit(debug.patched === true ? 0: 1)
