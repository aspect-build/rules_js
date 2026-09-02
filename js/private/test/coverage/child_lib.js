const assert = require('node:assert')

// The root process deletes this from the environment so that a child does not generate
// a second, redundant lcov report.
assert.strictEqual(process.env.JS_BINARY__COVERAGE_REPORT, undefined)

// ...and this proves the deletion happened in bootstrap.cjs rather than the var simply
// never having been set: the depth counter grows once per bootstrap, so a value longer
// than one character means this really is a nested js_binary node process.
assert.ok(
    process.env.JS_BINARY__NODE_PATCHES_DEPTH.length > 1,
    `expected a nested bootstrap, got depth '${process.env.JS_BINARY__NODE_PATCHES_DEPTH}'`
)

// If this is a coverage-enabled run, then the root process should have set NODE_V8_COVERAGE.
if (process.env.COVERAGE_DIR) {
    assert.match(
        process.env.NODE_V8_COVERAGE || '',
        /^\//,
        `expected an absolute NODE_V8_COVERAGE, got '${process.env.NODE_V8_COVERAGE}'`
    )
}

if (true) {
    childCovered()
} else {
    childUncovered()
}

function childCovered() {
    console.log('child covered')
}

function childUncovered() {
    console.log('child uncovered')
}
