// The js_binary entry point for coverage_test. It runs with COVERAGE_DIR set and nothing
// else, which is all a coverage-enabled test action gives the launcher: turning that into
// NODE_V8_COVERAGE before node starts, and finding the report generator without having
// its path baked in, are what launcher.cjs has to do here that the launcher script did.
const assert = require('node:assert')
const path = require('node:path')

assert.ok(
    process.env.NODE_V8_COVERAGE,
    'launcher.cjs did not turn COVERAGE_DIR into NODE_V8_COVERAGE'
)

// One of these has to be reported as executed and the other as not, which only real V8
// coverage data for this process can say.
if (true) {
    probeCovered()
} else {
    probeUncovered()
}

// bootstrap.cjs patched process.execPath to the node wrapper, so the child re-enters
// launcher.cjs the way any program shelling out to `node` does. It must not claim the
// coverage report for itself, and its own profile must still reach the report this
// process generates.
const { status, error } = require('node:child_process').spawnSync(
    process.execPath,
    [path.join(__dirname, 'coverage_child.js')],
    { stdio: 'inherit' }
)
assert.ifError(error)
assert.strictEqual(status, 0, 'the child process failed')

function probeCovered() {
    console.log('probe covered')
}

function probeUncovered() {
    console.log('probe uncovered')
}
