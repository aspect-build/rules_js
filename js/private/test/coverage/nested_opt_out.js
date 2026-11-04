// opt_out_bin (collect_coverage = False) inherits this collecting process's
// NODE_V8_COVERAGE.
const assert = require('node:assert')
const path = require('node:path')

const child = path.join(
    process.env.JS_BINARY__RUNFILES,
    process.env.JS_BINARY__WORKSPACE,
    process.env.OPT_OUT_BIN
)
const { status, error } = require('node:child_process').spawnSync(child, [], {
    stdio: 'inherit',
})

assert.ifError(error)
assert.strictEqual(status, 0, 'the collect_coverage = False child failed')
