// Runs nested_bin, a separate js_binary target. Only the root process of a test that
// generates the report ships coverage.cjs, so nested_bin is collected only through the
// NODE_V8_COVERAGE this process sets.
const assert = require('node:assert')
const path = require('node:path')

const child = path.join(
    process.env.JS_BINARY__RUNFILES,
    process.env.JS_BINARY__WORKSPACE,
    process.env.NESTED_BIN
)
const { status, error } = require('node:child_process').spawnSync(child, [], {
    stdio: 'inherit',
})

assert.ifError(error)
assert.strictEqual(status, 0, 'nested_bin failed')
