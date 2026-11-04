const assert = require('node:assert')
const path = require('node:path')

require('./opt_out_lib.js')

// bootstrap.cjs patched process.execPath to the node wrapper, so the child re-enters
// bootstrap.cjs.
const { status, error } = require('node:child_process').spawnSync(
    process.execPath,
    [path.join(__dirname, 'opt_out_lib.js')],
    { stdio: 'inherit' }
)

assert.ifError(error)
assert.strictEqual(status, 0, 'the child process failed')
