// A program built with collect_coverage = False: under `bazel coverage` it still gets
// COVERAGE_DIR, but neither it nor a child node process may start a V8 coverage
// session. opt_out_merger asserts that nothing was written to COVERAGE_DIR and that no
// report was generated.
const assert = require('node:assert')
const path = require('node:path')

require('./opt_out_lib.js')

// bootstrap.cjs patched process.execPath to the node wrapper, so the child re-enters
// bootstrap.cjs with this process's environment.
const { status, error } = require('node:child_process').spawnSync(
    process.execPath,
    [path.join(__dirname, 'opt_out_lib.js')],
    { stdio: 'inherit' }
)

assert.ifError(error)
assert.strictEqual(status, 0, 'the child process failed')
