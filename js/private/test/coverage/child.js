// Spawns a nested node process, which re-enters bootstrap.cjs through the node wrapper.
// Only this root process may generate the lcov report: child_lib.js asserts the guard
// that keeps the child from generating one too, and child_merger asserts that the
// child's V8 profile still made it into the report, i.e. that the root process reports
// late enough to include it.
const assert = require('node:assert')
const path = require('node:path')

// The report below is only evidence of anything if coverage.cjs is what collected the
// coverage that went into it. Nothing sets NODE_V8_COVERAGE before node starts any more, so
// a missing session here means an empty report rather than one collected some other way.
// This target also runs under plain `bazel test`, where there is no coverage to collect.
if (process.env.COVERAGE_DIR) {
    assert.strictEqual(
        typeof globalThis[Symbol.for('aspect_rules_js.v8_coverage')],
        'function',
        'expected coverage.cjs to have started a v8 coverage session'
    )
}

// bootstrap.cjs patched process.execPath to the node wrapper, so this is the same
// `node` a program would pick up off the PATH.
const { status, error } = require('node:child_process').spawnSync(
    process.execPath,
    [path.join(__dirname, 'child_lib.js')],
    { stdio: 'inherit' }
)

assert.ifError(error)
assert.strictEqual(status, 0, 'the child process failed')
